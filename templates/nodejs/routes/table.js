exports.initialize = function (app, appConfig, sql, pool) {

/// Generate >>>
/**
 * @swagger
 * /api/puppies:
 *   get:
 *     tags:
 *       - Puppies
 *     description: Returns all puppies
 *     produces:
 *       - application/json
 *     responses:
 *       200:
 *         description: An array of puppies
 *         schema:
 *           $ref: '#/definitions/Puppy'
 */
app.get("api/:branch/:table", function(req , res) {          
/// <<<
    const request = new sql.Request(pool);
/// Generate >>>
    request.input('table', sql.NVarChar, req.param('table'));
/// <<<
    request.input('branch_id', sql.NVarChar, req.param('branch'));
    request.input('jsonParams', sql.NVarChar, '{}');
    request.execute('dbo.get', (err, result) => {
        if(err) {
            console.log(err);
            res.status(400).send(err);
        }
        else {
            if(result.recordset) {
                res.send(result.recordset);
            }
            else
                res.send(result.output);
        }
    });
});

//
//request.bulk(table, (err, result) => {
    // ... error checks
//})
};