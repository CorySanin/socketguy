document.addEventListener('DOMContentLoaded', function () {
    var container = document.getElementById('container');
    var ws = new WebSocket(`ws://${window.location.host}/`);
    ws.onmessage = function (event) {
        var data = JSON.parse(event.data);
        console.log(data);
        var note = document.createElement('div');
        var author = document.createElement('span');
        author.appendChild(document.createTextNode(data.user));
        author.classList.add('author');
        var text = document.createElement('p');
        text.appendChild(document.createTextNode(data.text));
        text.classList.add('text');
        note.appendChild(author);
        note.appendChild(text);
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
});