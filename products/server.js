const express = require('express'),
      logger = require('morgan'),
      bodyParser = require('body-parser'),
      helmet = require('helmet'),
      compression = require('compression'),
      api = require('./api');
const getApp = (options) => {
    return new Promise((resolve, reject) => {
        if (!options.repo) {
            return reject(new Error('The server must be started with a connected repository'));
        } else {
            const app = express();
            app.use(logger('dev'));
            app.use(bodyParser.json());
            app.use(bodyParser.urlencoded({ extended: true }));
            app.use(compression());
            app.set('port', process.env.PORT || 3600);
            api(app, options);
            app.use((err, req, res, next) => {
                return res.status(500).send(err.message);
            });
            return resolve(app);
        }
    });
}

module.exports = Object.assign({},{getApp});