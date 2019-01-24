
const repository = (db) => {
    const products = db.products;

    const getAllProducts = () => {
        return new Promise((resolve,reject) => {
            products.find({}).then((result) => {
                return resolve(result);
            }).catch(err => {
                return reject(err);
            });
        });
    }
    const getProductById = (id) => {
        return new Promise((resolve,reject) => {
            products.findOne({ id : id }).then((result) => {
                return resolve(result);
            }).catch(err => {
                return reject(err);
            });
        });
    }
    return Object.create({
        getAllProducts,
        getProductById
    });
}
const connect = (connection) => {
    if(!connection){
        return Promise.reject(new Error('connection db not supplied!'));
    }else{
        return Promise.resolve(repository(connection));
    }
}

module.exports = Object.assign({},{connect});