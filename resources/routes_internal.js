exports.initialize = function (app, appConfig, sql, pool) {

/**
 * @swagger
 * definitions:
 *   Branch:
 *     properties:
 *      branch_name:
 *          type:
 *              string
 *          description:
 *              "DB datatype: NVARCHAR(255) | PRIMARY KEY"
 *      start_master_version_name:
 *          type:
 *              string
 *          description:
 *              "Reference to Version | The (closed) Version in the master branch where this Branch branched from | DB datatype: NVARCHAR(255)"
 *      last_closed_version_name:
 *          type:
 *              string
 *          description:
 *              "Reference to Version | The last closed Version in this branch | DB datatype: NVARCHAR(255)"
 *      current_version_name:
 *          type:
 *              string
 *          description:
 *              "Reference to Version | The current Version in this Branch | DB datatype: NVARCHAR(255)"
 *   Version:
 *     properties:
 *      version_name:
 *          type:
 *              string
 *          description:
 *              "DB datatype: NVARCHAR(255) | PRIMARY KEY"
 *      branch_name:
 *          type:
 *              string
 *          description:
 *              "Reference to Branch | The Branch where this Version is worked on | DB datatype: NVARCHAR(255)"
 *      previous_version_name:
 *          type:
 *              string
 *          description:
 *              "Reference to Version | The previous Version in the history of changes (similar to a commit in Git) | PRIMARY KEY"
 *      version_order:
 *          type:
 *              number
 *          description:
 *              "Global order of Versions (across all Branches) | DB datatype: NVARCHAR(255)"
 *      version_status:
 *          type:
 *              string
 *          description:
 *              "Status (OPEN | CLOSED | MERGING) of this Version | DB datatype: NVARCHAR(255)"
 *      
 * /api/branch:
 *   get:
 *     tags:
 *       - Branch
 *     description: Returns all Branches
 *     produces:
 *       - application/json
 *     responses:
 *       200:
 *         description: Array of Branch records
 *         schema:
 *           $ref: '#/definitions/Branch'
 *
 * /api/version:
 *   get:
 *     tags:
 *       - Version
 *     description: Returns all Versions
 *     parameters:
 *       - name: branch
 *         description: name of the branch (e.g. 'master')
 *         in: query
 *         required: false
 *         type: string
 *     produces:
 *       - application/json
 *     responses:
 *       200:
 *         description: Array of Version records
 *         schema:
 *           $ref: '#/definitions/Version'
 *
 * /api/branch/{branch_name}:
 *   post:
 *     tags:
 *       - Branch
 *     description: Creates a new Branch
 *     parameters:
 *       - name: branch_name
 *         description: name of the branch (e.g. 'DEV-123')
 *         in: path
 *         required: true
 *         type: string
  *     produces:
 *       - application/json
 *     responses:
 *       200:
 *         description: The created Branch record
 *         schema:
 *           $ref: '#/definitions/Branch'
 *
 * /api/{branch}/version/{version_name}:
 *   post:
 *     tags:
 *       - Version
 *     description: Creates a new version
 *     parameters:
 *       - name: version_name
 *         description: "name of the created version (e.g. 'DEV-123: add first batch')"
 *         in: path
 *         required: true
 *         type: string
 *         example: "DEV-123: add first batch"
 *       - name: branch
 *         description: name of the branch (e.g. 'DEV-123')
 *         in: path
 *         required: true
 *         type: string
 *         example: "DEV-123"
 *     produces:
 *       - application/json
 *     responses:
 *       200:
 *         description: The created Version record
 *         schema:
 *           $ref: '#/definitions/Version'
 *
 * /api/truncate_repository:
 *   get:
 *     description: Wipes out entire repository, leaving only master Branch and no Version / data
 *     produces:
 *       - application/json
 *     responses:
 *       200:
 *         description: successful truncation
 */
app.post("/api/:branch/version/:version_name", function(req , res) {          
    const request = new sql.Request(pool);
    if(req.body['branch'])
        request.input('branch_name', sql.NVarChar, req.params['branch']);
    request.input('version_name', sql.NVarChar, req.params['version_name']);
    request.execute('dbo.create_version', (err, result) => {
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

app.get("/api/truncate_repository", function(req , res) {          
    const request = new sql.Request(pool);
    request.execute('dbo.truncate_repository', (err, result) => {
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
};
