var DocumentDBClient = require('documentdb').DocumentClient;

var config = require('./config');
var docDbUtils = require('./docDbUtils');
var http = require('http');

// Init database
var docDbClient = new DocumentDBClient(config.host, {
    masterKey: config.authKey
});
var docCollection;
var docDbError;
docDbUtils.getOrCreateDatabase(docDbClient, config.databaseId, function(err, db){
    if (err == null) {
        docDbUtils.getOrCreateCollection(docDbClient, db._self, config.collectionId, function(error, collection){
            if (err == null) {         
                docCollection = collection;
            }
            else {
                docDbError = err;
            }
        })
    }
    else {
        docDbError = err;
    }
});

// create server
var port = process.env.PORT || 1338;
http.createServer(function (req, res) {
    if(docDbError){
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end(`DocumentDb Error:\n${JSON.stringify(docDbError)}.`)
        return;
    }
    // Add reqeust record
    var record = {
        ip: req.headers['x-forwarded-for'] || req.connection.remoteAddress,
        time: Date.now()
    }
    docDbClient.createDocument(docCollection._self, record, function (error, c) {});
    // Get request count
    docDbClient.queryDocuments(docCollection._self, 'SELECT VALUE Count(1) FROM root').current(function(err, count){
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end(`Hello World!\nThere are ${count} request records.`);
    });
}).listen(port);
