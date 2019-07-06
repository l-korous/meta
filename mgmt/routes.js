exports.initialize = function (app, appConfig, Busboy, path, fs) {
    function makeid(length) {
       var result           = '';
       var characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
       var charactersLength = characters.length;
       for ( var i = 0; i < length; i++ ) {
          result += characters.charAt(Math.floor(Math.random() * charactersLength));
       }
       return result;
    }

    /**
     * @swagger
     * /api/model-xml/{model_id}:
     *   get:
     *     description: Get stored model by id
     *     produces:
     *       - application/json
     *     parameters:
     *       - name: model_id
     *         description: the internal model ID from the POST response (upload of the model).
     *         in: path
     *         required: true
     *         type: string  
     *     responses:
     *       200:
     *         description: 'OK'
     *         schema:
     *          type: object
     *          properties:
     *              model:
     *                  type: string
     *                  description: the entire model is returned (as JSON)
     */
    app.get("/api/model-xml/:model_id", function(req , res) {
        var model_id = req.params['model_id'];
        full_path = path.join(__dirname, 'tmp', model_id);
        var contents = fs.readFileSync(full_path, 'utf8');
        res.send(contents);
    });

    /**
     * @swagger
     * /api/model-xml:
     *   post:
     *     description: Store model internally
     *     parameters:
     *       - name: model
     *         description: the model xml file
     *         in: body
     *         required: true
     *         type: string  
     *     produces:
     *       - application/xml
     *     responses:
     *       200:
     *         description: 'OK'
     *         schema:
     *          type: object
     *          properties:
     *              model_id:
     *                  type: string
     *                  description: the internal model ID with which a GET call needs to be made
     */
    app.post("/api/model-xml", function(req , res) {
        var model_id = makeid(32);
        var full_path = path.join(__dirname, 'tmp', model_id);
        fs.writeFile(full_path, req.body, (err) => {
          if (err)
              console.log(err);
        });
    
        res.send(model_id);
    });
};
