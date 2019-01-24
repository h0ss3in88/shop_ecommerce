const http = require('http'),
      cluster = require('cluster'),
      { EventEmitter } = require('events'),
      os = require('os'),
      app = require('./server'),
      repository = require('./utilities/data/repository'),
      connection = require('./utilities/data/connect'),
      mediator = new EventEmitter();
// verbose logging when we are starting the server
console.log('--- Product Service ---')
console.log('Connecting to Product Service DataBase...')

// log unhandled execpetions
process.on('uncaughtException', (err) => {
  console.error('Unhandled Exception', err);
});
process.on('uncaughtRejection', (err, promise) => {
  console.error('Unhandled Rejection', err);
});
mediator.on('db.error',(err) => {
    console.error(`unable to connect to database ${err}`);
});

mediator.on('db.ready',(db) => {
    let serverApp
    repository.connect(db).then(repo => {
        console.log('repository connected successfully');
        return app.getApp({ repo : repo })
    }).then(app => {
        serverApp = app;
        console.log(app.get('port'));
        if(cluster.isMaster){
            for (let i = 0; i < os.cpus().length; i++) {
                cluster.fork();
            }
            cluster.on('online',(worker) => {
                console.log(`worker online and running with ${worker.process.pid} process id`);
            });
            cluster.on('exit',(worker) => {
                console.log(`worker with ${worker.process.pid} process id dead`);
            });
        }else if(cluster.isWorker){
            let server = http.createServer(serverApp);
            server.listen(serverApp.get('port'),() => {
                console.log(`server running at :${server.address().address}:${server.address().port} on ${cluster.worker.process.pid} process id`);
            });
        }
    });
});
connection.connect(mediator);
mediator.emit('server.boot');