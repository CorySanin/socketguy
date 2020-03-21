document.addEventListener('DOMContentLoaded', function () {
    var container = document.getElementById('container');
    var ws;
    var connected = false;

    function notify(data) {
        var note = document.createElement('div');
        if ('user' in data) {
            var author = document.createElement('span');
            author.appendChild(document.createTextNode(data.user));
            author.classList.add('author');
            note.appendChild(author);
        }
        if ('text' in data) {
            var text = document.createElement('p');
            text.appendChild(document.createTextNode(data.text));
            text.classList.add('text');
            note.appendChild(text);
        }
        note.classList.add('notification', 'zeroheight');
        container.insertBefore(note, container.firstChild);
        setTimeout(() => {
            note.classList.remove('zeroheight');
        }, 50);

        setTimeout(() => {
            note.classList.add('fade');
            setTimeout(() => {
                container.removeChild(note);
            }, 1000);
        }, 6000);
    }

    function onmessage(e) {
        notify(JSON.parse(event.data));
    }

    function connect() {
        ws = new WebSocket(`ws://${window.location.host}/`);
        ws.onopen = function () {
            if (!connected) {
                notify({
                    text: 'Connection established.'
                });
            }
            connected = true;
        }
        ws.onmessage = onmessage;
        ws.onclose = function () {
            if (connected) {
                notify({
                    text: 'Lost connection.'
                });
            }
            connected = false;
            setTimeout(connect, 3000);
        };
    }

    connect();
});