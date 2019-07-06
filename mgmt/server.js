var express = require("express");
var bodyParser = require("body-parser");
var swaggerJSDoc = require('swagger-jsdoc');
var Busboy = require('busboy');
var fs = require('fs');
var path = require('path');
var os = require('os');

const appConfig = {
    hostName: 'localhost',
    version: '1.0.0',
    port: 3000
};

var app = express();
app.use(bodyParser.json()); 
app.use(function (req, res, next) {
    //Enabling CORS 
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Methods", "GET,HEAD,OPTIONS,POST,PUT,DELETE");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, contentType,Content-Type, Accept, Authorization");
    next();
});

 var server = app.listen(appConfig.port, function () {
    var port = server.address().port;
    console.log("App now running on port", port);
 });
 
// DB config
var swaggerSpec = swaggerJSDoc({
    swaggerDefinition: {
        info: {
            title: 'META Management API',
            version: appConfig.version,
            description: 'META Management API documentation',
        },
        host: appConfig.hostName + ':' + appConfig.port,
        basePath: '/',
        securityDefinitions: {
            BasicAuth: {
                type: "basic"
            }
        },
        security: [
            {
                BasicAuth: []
            }
        ]
    },
  apis: ['./routes.js'],
});
app.get('/swagger.json', function(req, res) {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

app.use(express.static('public'))
var routes = require('./routes.js');
routes.initialize(app, appConfig, Busboy, path, fs);