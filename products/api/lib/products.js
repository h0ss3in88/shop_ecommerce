const express = require('express'),
      status = require('http-status'),
      validator = require('validator'),
      router = express.Router();

module.exports = (repo) => {
    router.get('/products',(req,res,next) => {
        repo.getAllProducts().then(result => {
            return res.status(status.OK).json(result);
        }).catch(next);
    });
    router.param('id',(req,res,next,id) => {
        if(validator.isNumeric(id) && !validator.isEmpty(id)){
            req.id = id;
            return next();
        }else{
            return next('id should be in correct format');
        }
    });
    router
        .route('/products/:id')
        .get((req,res,next) => {
            repo.getProductById(req.id).then(result => {
                return res.status(status.OK).json(result);
            }).catch(next);
        });
    return router;
}