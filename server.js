
var http = require('http');
var mongoClient = require('mongodb').MongoClient;

var mongoUri = process.env.MONGO_URI || '';
var port = process.env.PORT || 80;

mongoClient.connect(mongoUri, function (err, client) {

    http.createServer(function (req, res) {

        if(err){
            res.writeHead(500, { 'Content-Type': 'text/plain' });
            res.end(`Failed to connect to the database.\n${err}\n12:45`)
            return;
        }
        
        const db = client.db('logs');
        const requests = db.collection('requests');
 
        requests.count(function(error, count){
            res.writeHead(200, { 'Content-Type': 'text/plain' });
            res.end(`Hello World!\nThere are ${count} request records.`);
        })

        requests.insertOne({
            ip: req.headers['x-forwarded-for'] || req.connection.remoteAddress,
            time: Date.now()
        });
    }).listen(port);

});