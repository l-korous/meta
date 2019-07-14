const correlator = require('express-correlation-id');
var express = require("express");
var bodyParser = require("body-parser");
var swaggerJSDoc = require('swagger-jsdoc');
var Busboy = require('busboy');
var fs = require('fs');
var path = require('path');
var os = require('os');
const shell = require('shelljs');
var serveIndex = require('serve-index')

const appConfig = {
    port: 4499
};

var app = express();
app.use(bodyParser.text({type: '*/*'}));
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
            description: 'META Management API documentation',
        },
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

function getTimestamp (date) {
    return date.getFullYear()
    + '-' + (date.getMonth() < 10 ? '0' : '') + date.getMonth()
    + '-' + (date.getDate() < 10 ? '0' : '') + date.getDate()
    + ' ' + (date.getHours() < 10 ? '0' : '') + date.getHours()
    + ':' + (date.getMinutes() < 10 ? '0' : '') + date.getMinutes()
    + ':' + (date.getSeconds() < 10 ? '0' : '') + date.getSeconds()
    + '.' + (date.getMilliseconds() < 100 ? (date.getMilliseconds() < 10 ? '00' : '0') : '') + date.getMilliseconds();
}

app.use(correlator({header: "x-my-correlation-header-name"}));

const logRequestStartFinish = (req, res, next) => {
    console.info(getTimestamp(new Date()) + ' |' + req.correlationId() + '| ' + req.method + ' ' + req.originalUrl);

    res.on('finish', () => {
        console.info(getTimestamp(new Date()) + ' |' + req.correlationId() + '| ' + res.statusCode + ' ' + res.statusMessage);
    })

    next();
}

app.use(logRequestStartFinish);
app.use('/public', express.static('public'), serveIndex('public', {'icons': true, view: 'details'}))
var routes = require('./routes.js');
routes.initialize(app, appConfig, Busboy, path, fs, shell);