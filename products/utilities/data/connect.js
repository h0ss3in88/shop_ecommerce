const massive = require('massive');
const connect = (mediator) => {
    mediator.once('server.boot', () => {
        console.log(process.env.POSTGRES_HOST);
        massive({
            host: process.env.POSTGRES_HOST || 'localhost',
            port: process.env.POSTGRES_PORT || 5432,
            database: process.env.POSTGRES_DATABASE || 'balloonshop',
            user: process.env.POSTGRES_USER || 'hussein',
            password: process.env.POSTGRES_PASS || '123456'
        }).then((db) => {
            mediator.emit('db.ready', db);
        }).catch(err => {
            mediator.emit('db.error', err);
        });
    });
}
module.exports = Object.assign({},{connect});