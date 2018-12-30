/////////////// Config, general >>>
var express = require("express");
var bodyParser = require("body-parser");
var sql = require("mssql");
var swaggerJSDoc = require('swagger-jsdoc');

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
        user:'sa',
        password:'asdf',
        server:'localhost',
        database:'meta3',
        pool: {
            max: 10,
            instanceName: 'SQLEXPRESS',
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
  apis: ['./routes/*.js'],
});
app.get('/swagger.json', function(req, res) {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

app.use(express.static('public'))
/////////////// <<<

/// Generate >>>
var routesTable = require('./routes/table.js');
routesTable.initialize(app, appConfig, sql, pool);