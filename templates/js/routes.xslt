<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY s "&#160;">]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
exports.initialize = function (app, appConfig, sql, pool) {

<xsl:for-each select="//table" >
/**
 * @swagger
 * /api/<xsl:value-of select="@table_name" />:
 *   get:
 *     tags:
 *       - <xsl:value-of select="@table_name" />
 *     description: Returns all <xsl:value-of select="@table_name" /> records
 *     produces:
 *       - application/json
 *     responses:
 *       200:
 *         description: An array of <xsl:value-of select="@table_name" /> records
 *         schema:
 *           $ref: '#/definitions/<xsl:value-of select="@table_name" />'
 */
app.get("api/:branch/:<xsl:value-of select="@table_name" />", function(req , res) {          
    const request = new sql.Request(pool);
    request.input('<xsl:value-of select="@table_name" />', sql.NVarChar, req.param('<xsl:value-of select="@table_name" />'));
    request.input('branch_id', sql.NVarChar, req.param('branch'));
    request.input('jsonParams', sql.NVarChar, '{}');
    request.execute('dbo.get', (err, result) =&gt; {
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
//request.bulk(table, (err, result) =&gt; {
    // ... error checks
//})
</xsl:for-each>
};
</xsl:template>
</xsl:stylesheet>
