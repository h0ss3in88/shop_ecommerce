
const products = require('./lib/products'),
    ping = require('./lib/ping');

module.exports = (app,options) => {
    const { repo } = options;
    app.use('/api',ping());
    app.use('/api',products(repo));
}
