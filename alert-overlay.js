const express = require('express');
const expressws = require('express-ws');

class AlertOverlay {
    constructor(cfg) {
        this._app = express();
        this._ws = expressws(this._app);
        this._clients = [];

        this._app.use(express.static('www'));

        this._app.ws('/', (ws, req) => {
            let index = this._clients.push(ws) - 1;
            ws.on('close', (ws) => {
                this._clients.splice(index, 1);
            });
        });

        this._app.listen(cfg['overlay-port']);
    }

    notify(params) {
        const message = {
            user: params.user,
            text: params.text
        }
        const promises = this._clients.map(async (ws) => {
            ws.send(JSON.stringify(message));
        });
        return new Promise(async resolve => {
            await Promise.all(promises);
            resolve();
        });
    }
}

module.exports = exports = AlertOverlay;