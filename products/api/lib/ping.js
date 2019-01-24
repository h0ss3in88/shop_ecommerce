const express = require('express'),
    status = require('http-status'),
    router = express.Router();

module.exports = () => {
    router
        .route('/ping')
        .get((req,res,next) => {
            return res.status(status.OK).json({ "ping" : "pong" });
        });
    return router;
}