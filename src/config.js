var config = {}

config.host = process.env.HOST;
config.authKey = process.env.AUTH_KEY;
config.databaseId = "Http";
config.collectionId = "Requests";

module.exports = config;