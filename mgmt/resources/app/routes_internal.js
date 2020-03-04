exports.initialize = function (app, appConfig, sql, pool, Busboy, path, fs) {
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
        *   delete:
        *     tags:
        *       - Branch
        *     description: Deletes an existing branch
        *     parameters:
        *       - name: branch_name
        *         description: name of the branch (e.g. 'DEV-123')
        *         in: path
        *         required: true
        *         type: string
        *         example: "DEV-123"
        *     produces:
        *       - application/json
        *     responses:
        *       200:
        *         description: (empty)
    */
     app.delete("/api/branch/:branch_name", function(req , res) {          
        const request = new sql.Request(pool);    
        request.input('branch_name', sql.NVarChar, req.params['branch_name']);
        request.execute('meta.delete_branch', (err, result) => {
            if(err) {
                console.log(err);
                res.status(400).send(err);
            }
            else {
                if(result.recordset) {
                    res.send(result.recordset);
                }
                else
                    res.send(result.output == {} ? result.output : "success");
            }
        });
    });
    
    /**
    * @swagger
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
    */
     app.post("/api/branch/:branch_name", function(req , res) {          
        const request = new sql.Request(pool);
        request.input('branch_name', sql.NVarChar, req.params['branch_name']);
        request.execute('meta.create_branch', (err, result) => {
            if(err) {
                console.log(err);
                res.status(400).send(err);
            }
            else {
                if(result.recordset) {
                    res.send(result.recordset);
                }
                else
                    res.send(result.output == {} ? result.output : "success");
            }
        });
    });
     
     /**
     * @swagger
     * definitions:
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
     * /api/branch/{branch}/version:
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
     * /api/branch/{branch}/version/{version_name}:
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
     */
    app.post("/api/branch/:branch/version/:version_name", function(req , res) {          
        const request = new sql.Request(pool);
        request.input('branch_name', sql.NVarChar, req.params['branch']);
        request.input('version_name', sql.NVarChar, req.params['version_name']);
        request.execute('meta.create_version', (err, result) => {
            if(err) {
                console.log(err);
                res.status(400).send(err);
            }
            else {
                if(result.recordset) {
                    res.send(result.recordset);
                }
                else
                    res.send(result.output == {} ? result.output : "success");
            }
        });
    });
    
    /**
    * @swagger
    * /api/branch/{branch}/close_version/{version}:
    *   post:
    *     tags:
    *       - Version
    *     description: Closes an existing version
    *     parameters:
    *       - name: version
    *         description: "name of the version (e.g. 'DEV-123: add first batch')"
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
    *         description: The closed Version record
    *         schema:
    *           $ref: '#/definitions/Version'
    */
     app.post("/api/branch/:branch/close_version/:version", function(req , res) {          
        const request = new sql.Request(pool);
        request.input('branch_name', sql.NVarChar, req.params['branch']);
        request.input('version_name', sql.NVarChar, req.params['version']);
        request.execute('meta.close_version', (err, result) => {
            if(err) {
                console.log(err);
                res.status(400).send(err);
            }
            else {
                if(result.recordset) {
                    res.send(result.recordset);
                }
                else
                    res.send(result.output == {} ? result.output : "success");
            }
        });
    });
     
    /**
    * @swagger
    * /api/truncate-repository:
    *   post:
    *     tags:
    *       - Repository
    *     description: Wipes out entire repository, leaving only master Branch and no Version / data
    *     produces:
    *       - application/json
    *     responses:
    *       200:
    *         description: successful truncation
    */
    app.post("/api/truncate_repository", function(req , res) {          
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
                else {
                    res.send(result.output == {} ? result.output : "success");
                }
            }
        });
    });
     
    /**
    * @swagger
    * definitions:
    *   Table:
    *     properties:
    *      table_name:
    *          type:
    *              string
    *          description:
    *              "Name of the table"
    * /api/table:
    *   get:
    *     tags:
    *       - Repository
    *     description: Lists all tables
    *     produces:
    *       - application/json
    *     responses:
     *       200:
     *         description: Array of Table records
     *         schema:
     *           $ref: '#/definitions/Table'
    */
    app.get("/api/table", function(req , res) {          
        const request = new sql.Request(pool);
        request.execute('meta.get_tables', (err, result) => {
            if(err) {
                console.log(err);
                res.status(400).send(err);
            }
            else {
                if(result.recordset) {
                    res.send(result.recordset);
                }
                else
                    res.send(result.output == {} ? result.output : "success");
            }
        });
    });
     
    /**
    * @swagger
    * definitions:
    *   Column:
    *     properties:
    *      column_name:
    *          type:
    *              string
    *          description:
    *              Name of the column
    *      column_order:
    *          type:
    *              integer
    *          description:
    *              Order of the column within its table
    *      table_name:
    *          type:
    *              string
    *          description:
    *              Name of the table
    *      datatype_name:
    *          type:
    *              string
    *          description:
    *              Name of the datatype of the column
    *      is_primary_key:
    *          type:
    *              boolean
    *          description:
    *              If the column is the primary key in the table
    *      is_unique:
    *          type:
    *              boolean
    *          description:
    *              If the column must have unique values within the table
    *      is_required:
    *          type:
    *              boolean
    *          description:
    *              If the column is required to have value
    *      referenced_table_name:
    *          type:
    *              string
    *          description:
    *              If the column is a foreign key, then name of the table it references
    *      referenced_column_name:
    *          type:
    *              string
    *          description:
    *              If the column is a foreign key, then name of the column it references
    *      on_delete:
    *          type:
    *              string
    *          description:
    *              If the column is a foreign key, then behavior if the referenced record is deleted
    * /api/column:
    *   get:
    *     tags:
    *       - Repository
    *     description: Lists all columns for a particular table
    *     parameters:
    *       - name: table
    *         description: "name of the table"
    *         in: path
    *         required: true
    *         type: string
    *         example: "myTable"
    *     produces:
    *       - application/json
    *     responses:
     *       200:
     *         description: Array of Column records
     *         schema:
     *           $ref: '#/definitions/Column'
    */
    app.get("/api/table/:table/column", function(req , res) {          
        const request = new sql.Request(pool);
        request.input('table_name', sql.NVarChar, req.params['table']);
        request.execute('meta.get_columns', (err, result) => {
            if(err) {
                console.log(err);
                res.status(400).send(err);
            }
            else {
                if(result.recordset) {
                    res.send(result.recordset);
                }
                else
                    res.send(result.output == {} ? result.output : "success");
            }
        });
    });
    
    /**
        * @swagger
        * /api/upload_file:
        *   post:
        *     tags:
        *       - Utility
        *     description: Uploads a file to tmp directory
        *     responses:
        *       200:
        *         description: (empty)
    */
    app.post("/api/upload_file", function(req , res) {  
        var busboy = new Busboy({ headers: req.headers });
        var full_path = '';
        
        busboy.on('file', function(fieldname, file, filename, encoding, mimetype) {
          full_path = path.join(__dirname, 'tmp', filename);
          file.pipe(fs.createWriteStream(full_path));
        });
        
        busboy.on('finish', function() {
          res.send();
        });
        return req.pipe(busboy);
    });
    
    /**
        * @swagger
        * /api/bulk_insert_excel_internal:
        *   post:
        *     tags:
        *       - Repository
        *     description: Internal function to insert data from Excel
        *     responses:
        *       200:
        *         description: (empty)
    */
    app.post("/api/bulk_insert_excel_internal", function(req , res) {          
        const request = new sql.Request(pool);
        request.input('file_root', sql.NVarChar, path.join(__dirname, 'tmp', req.query['random_string']));
        request.execute('meta.bulk_insert_excel_internal', (err, result) => {
            if(err) {
                console.log(err);
                res.status(400).send(err);
            }
            else {
                if(result.recordset) {
                    res.send(result.recordset);
                }
                else
                    res.send(result.output == {} ? result.output : "success");
                
                fs.readdir(path.join(__dirname, 'tmp'), function (err, files) {
                    if (err) {
                        return console.log('Unable to scan directory: ' + err);
                    }
                    
                    files.forEach(function (file) {
                        if(file.startsWith(req.query['random_string'])) {
                            fs.unlink(path.join(__dirname, 'tmp', file), (err) => {
                              if (err) {
                                console.error(err)
                                return
                              }
                            });
                        }
                    });
                });
            }
        });
    });
};
