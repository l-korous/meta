<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY s "&#160;">]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
var express = require("express");
var bodyParser = require("body-parser");
var sql = require("mssql");
var swaggerJSDoc = require('swagger-jsdoc');

const appConfig = {
    hostName: '<xsl:value-of select="//configuration[@key='hostname']/@value" />',
    version: '1.0.0',
    port: <xsl:value-of select="//configuration[@key='port']/@value" />
};

var app = express();
app.use(bodyParser.json()); 
app.use(function (req, res, next) {
    //Enabling CORS 
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Methods", "GET,HEAD,OPTIONS,POST,PUT");
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
            description: 'Demonstrating how to describe a RESTful API with Swagger',
        },
        host: appConfig.hostName + ':' + appConfig.port,
        basePath: '/',
    },
  apis: ['./routes.js'],
});
app.get('/swagger.json', function(req, res) {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

app.use(express.static('public'))
var routes = require('./routes.js');
routes.initialize(app, appConfig, sql, pool);

</xsl:template>
</xsl:stylesheet>
