<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY s "&#160;">]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
const correlator = require('express-correlation-id');
var express = require("express");
var bodyParser = require("body-parser");
var sql = require("mssql");
var swaggerJSDoc = require('swagger-jsdoc');
var Busboy = require('busboy');
var fs = require('fs');
var path = require('path');
var os = require('os');

const appConfig = {
    version: '1.0.0',
    port: 80
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
const pool = new sql.ConnectionPool({
        user:'<xsl:value-of select="//configuration[@key='DbUser']/@value" />',
        password:'<xsl:value-of select="//configuration[@key='DbPassword']/@value" />',
        server:'<xsl:value-of select="//configuration[@key='DbHostName']/@value" />',
        database:'<xsl:value-of select="//configuration[@key='DbName']/@value" />',
        pool: {
            max: 10,
            <xsl:if test="count(//configuration[@key='DbInstanceName']) &gt; 0">
            instanceName: '<xsl:value-of select="//configuration[@key='DbInstanceName']/@value" />',
            </xsl:if>
            min: 0,
            idleTimeoutMillis: 30000
        }
    });
pool.connect(err => {if(err) console.log(err); else console.log('DB connection successful.');});

var swaggerSpec = swaggerJSDoc({
    swaggerDefinition: {
        info: {
            title: 'Node Swagger API',
            version: appConfig.version,
            description: 'META-generated API documentation',
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
  apis: ['./routes*.js'],
});
app.get('/swagger.json', function(req, res) {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

function getTimestamp (date) {
    return date.getFullYear()
    + '-' + (date.getMonth() &lt; 10 ? '0' : '') + date.getMonth()
    + '-' + (date.getDate() &lt; 10 ? '0' : '') + date.getDate()
    + ' ' + (date.getHours() &lt; 10 ? '0' : '') + date.getHours()
    + ':' + (date.getMinutes() &lt; 10 ? '0' : '') + date.getMinutes()
    + ':' + (date.getSeconds() &lt; 10 ? '0' : '') + date.getSeconds()
    + '.' + (date.getMilliseconds() &lt; 100 ? (date.getMilliseconds() &lt; 10 ? '00' : '0') : '') + date.getMilliseconds();
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

app.use(express.static('public'))
var routes = require('./routes.js');
routes.initialize(app, appConfig, sql, pool, Busboy, path, fs);
var routes_internal = require('./routes_internal.js');
routes_internal.initialize(app, appConfig, sql, pool, Busboy, path, fs);

</xsl:template>
</xsl:stylesheet>