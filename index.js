const fs = require('fs');
const ws = require('ws');
const path = require('path');
const open = require('open');
const UdpBroadcast = require('udp-broadcast').server;
const interactive = require('@mixer/interactive-node');
const { ShortCodeExpireError, OAuthClient } = require('@mixer/shortcode-oauth');
const AlertOverlay = require('./alert-overlay');

const configfile = path.join(__dirname, 'config/config.json');
const USELESSCODE = 420030;
const client = new interactive.GameClient();

interactive.setWebSocket(ws);

let layoutfile = path.join(__dirname, 'layout/default.json');
let currentScene = 'default';
let server, config, defaultGroup, alertoverlay;

function handleControls(controls) {
    controls.forEach((control) => {
        if (control.kind === 'button') {
            control.on('mousedown', (inputEvent, participant) => {
                server.send({
                    participant: participant.username,
                    control: control.controlID,
                    type: control.kind,
                    meta: control.meta,
                    transactionID: (inputEvent.transactionID ? inputEvent.transactionID : null)
                });
            });
        }
        else if (control.kind === 'textbox') {
            control.on('submit', (inputEvent, participant) => {
                server.send({
                    participant: participant.username,
                    control: control.controlID,
                    type: control.kind,
                    message: inputEvent.input.value,
                    meta: control.meta
                });
            });
        }
    });
}

client.on('open', () => {
    console.log('Connected to Mixer.');

    fs.readFile(layoutfile, 'utf8', function (err, data) {
        if (!err) {
            try {
                layout = JSON.parse(data);
                client.synchronizeScenes().then((remoteScenes) => {
                    layout.scenes.forEach((scene) => {
                        let gscene = client.state.getScene(scene.sceneID);

                        let createControls = () => {
                            client.createControls(scene).then(handleControls).catch((err) => { console.log(err) });
                        }

                        if (!gscene) {
                            client.createScene({ sceneID: scene.sceneID }).then(() => { createControls(); }).catch((err) => { console.log(err) });
                        }
                        else {
                            createControls();
                        }
                    });
                    return client.ready(true);
                }).catch((err) => { console.log(err) });

                client.synchronizeGroups().then((remoteGroups) => {
                    defaultGroup = client.state.getGroup('default');
                    defaultGroup.sceneID = currentScene;

                    return client.updateGroups({
                        groups: [defaultGroup]
                    })
                })
            }
            catch (e) {
                console.log('Could not read config file.', e);
            }
        }
        else {
            console.log('Could not read config file.');
        }
    })
});

client.state.on('participantJoin', (participant) => {
    participant.groupID = currentScene;
});

const oaclient = new OAuthClient({
    clientId: '49410fcfcbbc1ddcdefb22a3b77231fbc157b8e18e1deadf',
    scopes: ['interactive:robot:self']
});

fs.readFile(configfile, 'utf8', function (err, data) {
    if (!err) {
        try {
            config = JSON.parse(data);
            alertoverlay = new AlertOverlay(config);
            server = new UdpBroadcast(config);
            server.on('message', (m) => {
                try {
                    if (typeof m === 'object') {
                        if ('scene' in m) {
                            currentScene = m.scene;
                            if (defaultGroup) {
                                defaultGroup.sceneID = currentScene;
                                client.updateGroups({
                                    groups: [defaultGroup]
                                })
                            }
                        }
                        if ('text' in m) {
                            alertoverlay.notify(m);
                            if ('transactionID' in m) {
                                client.captureTransaction(m.transactionID);
                            }
                        }
                    }
                }
                catch{
                    if (m) {
                        console.log(m);
                    }
                }
            });
            server.open();
            if (process.argv.length > 2) {
                layoutfile = process.argv[2];
            }
            attempt().then(tokens => {
                client.open({
                    authToken: tokens.data.accessToken,
                    versionId: USELESSCODE,
                });
            });
        }
        catch (e) {
            console.log('Could not read config file.', e);
        }
    }
    else {
        console.log('Could not read config file.');
    }
})


const attempt = () =>
    oaclient
        .getCode()
        .then(code => {
            if ('auto-open-browser' in config && !config['auto-open-browser']) {
                console.log(`Go to https://mixer.com/go?code=${code.code} to allow SocketGuy to access your account.`)
            }
            else {
                open(`https://mixer.com/go?code=${code.code}`);
            }
            return code.waitForAccept();
        })
        .catch(err => {
            if (err instanceof ShortCodeExpireError) {
                return attempt(); // loop!
            }

            throw err;
        });