<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY s "&#160;">]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
const qs = require('qs');
exports.initialize = function (app, appConfig, sql, pool) {

<xsl:for-each select="//table" >
var <xsl:value-of select="@table_name" />_field_to_node_mssql_datatype = function (column_name){
switch(column_name) {
<xsl:for-each select="columns/column" >case "<xsl:value-of select="@column_name" />": return <xsl:value-of select="meta:datatype_to_node_mssql(@datatype)" />;break;
</xsl:for-each>}
}

/**
 * @swagger
 * definitions:
 *   <xsl:value-of select="@table_name" />:
 *     required: [<xsl:for-each select="columns/column[@is_nullable=0 or @is_primary_key=1]" ><xsl:value-of select="@column_name" /><xsl:if test="position() != last()">, </xsl:if></xsl:for-each>]
 *     properties:
 *      <xsl:for-each select="columns/column" ><xsl:value-of select="@column_name" />:
 *          type:
 *              <xsl:value-of select="meta:datatype_to_js(@datatype)" />
 *          description:
 *              "DB datatype: <xsl:value-of select="meta:datatype_to_sql(@datatype)" /><xsl:if test="@is_primary_key = 1"> | PRIMARY KEY</xsl:if><xsl:if test="@is_unique = 1"> | UNIQUE</xsl:if><xsl:if test="@is_nullable = 0"> | REQUIRED</xsl:if>"
 *      </xsl:for-each>
 *
 * /api/{branch}/<xsl:value-of select="@table_name" />:
 *   get:
 *     tags:
 *       - <xsl:value-of select="@table_name" />
 *     description: Returns all <xsl:value-of select="@table_name" /> records
 *     parameters:
 *       - name: branch
 *         description: name of the branch (e.g. 'master')
 *         in: path
 *         required: true
 *         type: string
 *       - name: SortBy 
 *         description: "serialized object (e.g. [{'col': 'myColumn1', 'dir': 'ASC'}, {'col': 'myColumn2', 'dir': 'DESC'}, ...] ) for sorting, serialized using https://github.com/ljharb/qs (into form 'SortBy[0][col]=myColumn1&amp;SortBy[0][dir]=ASC&amp;SortBy[1][col]=myColumn2&amp;SortBy[1][dir]=DESC')"
 *         in: query
 *         required: false
 *         type: array
 *       - name: FilterBy
 *         description: "serialized object (e.g. [{'col': 'myColumn1', 'regex': '%Smith'}, {'col': 'myColumn2', 'regex': 'abc[def]'}, ...] ) for filtering, serialized using https://github.com/ljharb/qs (into form 'FilterBy[0][col]=myColumn1&amp;FilterBy[0][regex]=%Smith&amp;FilterBy[1][col]=myColumn2&amp;FilterBy[1][regex]=\"abc\\[def\\]\"')"
 *         in: query
 *         required: false
 *         type: array
 *     produces:
 *       - application/json
 *     responses:
 *       200:
 *         description: An array of <xsl:value-of select="@table_name" /> records
 *         schema:
 *           $ref: '#/definitions/<xsl:value-of select="@table_name" />'
 */
app.get("/api/:branch/<xsl:value-of select="@table_name" />", function(req , res) {          
    const request = new sql.Request(pool);
    request.input('branch_name', sql.NVarChar, req.params['branch']);
    request.input('jsonParams', sql.NVarChar, qs.parse() || '{}');
    request.execute('dbo.get_<xsl:value-of select="@table_name" />', (err, result) =&gt; {
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

/**
 * @swagger
 * /api/{branch}/<xsl:value-of select="@table_name" /><xsl:for-each select="columns/column[@is_primary_key=1]">/{<xsl:value-of select="@column_name" />}</xsl:for-each>:
 *   get:
 *     tags:
 *       - <xsl:value-of select="@table_name" />
 *     description: Returns a single <xsl:value-of select="@table_name" /> record
 *     parameters:
 *       - name: branch
 *         description: name of the branch (e.g. 'master')
 *         in: path
 *         required: true
 *         type: string
 *       <xsl:for-each select="columns/column[@is_primary_key=1]" >- name: <xsl:value-of select="@column_name" />
 *         type: <xsl:value-of select="meta:datatype_to_swagger(@datatype)" />
 *         in: path
 *         description: "<xsl:value-of select="@column_name" /> | DB datatype: <xsl:value-of select="meta:datatype_to_sql(@datatype)" />"
 *         required: true
 *       </xsl:for-each>
 *     produces:
 *       - application/json
 *     responses:
 *       200:
 *         description: A <xsl:value-of select="@table_name" /> record
 *         schema:
 *           $ref: '#/definitions/<xsl:value-of select="@table_name" />'
 *   post:
 *     tags:
 *       - <xsl:value-of select="@table_name" />
 *     description: Creates a single <xsl:value-of select="@table_name" /> record
 *     parameters:
 *       - name: branch
 *         description: name of the branch (e.g. 'master')
 *         in: path
 *         required: true
 *         type: string
 *       <xsl:for-each select="columns/column[@is_primary_key=1]" >- name: <xsl:value-of select="@column_name" />
 *         type: <xsl:value-of select="meta:datatype_to_swagger(@datatype)" />
 *         in: path
 *         description: "<xsl:value-of select="@column_name" /> | DB datatype: <xsl:value-of select="meta:datatype_to_sql(@datatype)" />"
 *         required: true
 *       </xsl:for-each>
 *       <xsl:for-each select="columns/column[@is_primary_key=0]" ><xsl:sort select="@is_nullable" order="descending" />- name: <xsl:value-of select="@column_name" />
 *         type: <xsl:value-of select="meta:datatype_to_swagger(@datatype)" />
 *         in: body
 *         description: "<xsl:value-of select="@column_name" /> | DB datatype: <xsl:value-of select="meta:datatype_to_sql(@datatype)" /><xsl:if test="@is_unique = 1"> | UNIQUE</xsl:if>"
 *         required: <xsl:choose><xsl:when test="@is_nullable = 0">true</xsl:when><xsl:otherwise>false</xsl:otherwise></xsl:choose>
 *         example: "<xsl:value-of select="meta:datatype_to_swagger_example(@datatype)" />"
 *       </xsl:for-each>
 *     produces:
 *       - application/json
 *     responses:
 *       200:
 *         description: The created <xsl:value-of select="@table_name" /> record
 *         schema:
 *           $ref: '#/definitions/<xsl:value-of select="@table_name" />'
 <xsl:if test="count(columns/column[@is_primary_key=0]) &gt; 0">*   put:
 *     tags:
 *       - <xsl:value-of select="@table_name" />
 *     description: Updates a single <xsl:value-of select="@table_name" /> record
 *     parameters:
 *       - name: branch
 *         description: name of the branch (e.g. 'master')
 *         in: path
 *         required: true
 *         type: string
 *       <xsl:for-each select="columns/column[@is_primary_key=1]" >- name: <xsl:value-of select="@column_name" />
 *         type: <xsl:value-of select="meta:datatype_to_swagger(@datatype)" />
 *         in: path
 *         description: "<xsl:value-of select="@column_name" /> | DB datatype: <xsl:value-of select="meta:datatype_to_sql(@datatype)" />"
 *         required: true
 *       </xsl:for-each>
 *       <xsl:for-each select="columns/column[@is_primary_key=0]" ><xsl:sort select="@is_nullable" order="descending" />- name: <xsl:value-of select="@column_name" />
 *         type: <xsl:value-of select="meta:datatype_to_swagger(@datatype)" />
 *         in: body
 *         description: "<xsl:value-of select="@column_name" /> | DB datatype: <xsl:value-of select="meta:datatype_to_sql(@datatype)" /><xsl:if test="@is_unique = 1"> | UNIQUE</xsl:if>"
 *         required: <xsl:choose><xsl:when test="@is_nullable = 0">true</xsl:when><xsl:otherwise>false</xsl:otherwise></xsl:choose>
 *         example: "<xsl:value-of select="meta:datatype_to_swagger_example(@datatype)" />"
 *       </xsl:for-each>
 *     produces:
 *       - application/json
 *     responses:
 *       200:
 *         description: The updated <xsl:value-of select="@table_name" /> record
 *         schema:
 *           $ref: '#/definitions/<xsl:value-of select="@table_name" />'</xsl:if>
 *   delete:
 *     tags:
 *       - <xsl:value-of select="@table_name" />
 *     description: Deletes a single <xsl:value-of select="@table_name" /> record
 *     parameters:
 *       - name: branch
 *         description: name of the branch (e.g. 'master')
 *         in: path
 *         required: true
 *         type: string
 *       <xsl:for-each select="columns/column[@is_primary_key=1]" >- name: <xsl:value-of select="@column_name" />
 *         type: <xsl:value-of select="meta:datatype_to_swagger(@datatype)" />
 *         in: path
 *         description: "<xsl:value-of select="@column_name" /> | DB datatype: <xsl:value-of select="meta:datatype_to_sql(@datatype)" />"
 *         required: true
 *       </xsl:for-each>
 *     produces:
 *       - application/json
 *     responses:
 *       200:
 *         description: Successfully deleted
 */
app.get("/api/:branch/<xsl:value-of select="@table_name" />/<xsl:for-each select="columns/column[@is_primary_key=1]">:<xsl:value-of select="@column_name" /><xsl:if test="position() != last()">/</xsl:if></xsl:for-each>", function(req , res) {          
    const request = new sql.Request(pool);
    request.input('branch_name', sql.NVarChar, req.params['branch']);
    <xsl:for-each select="columns/column[@is_primary_key=1]">
    request.input('<xsl:value-of select="@column_name" />', <xsl:value-of select="meta:datatype_to_node_mssql(@datatype)" />, req.params['<xsl:value-of select="@column_name" />']);</xsl:for-each>
    request.execute('dbo.get_single_<xsl:value-of select="@table_name" />', (err, result) =&gt; {
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
app.delete("/api/:branch/<xsl:value-of select="@table_name" />/<xsl:for-each select="columns/column[@is_primary_key=1]">:<xsl:value-of select="@column_name" /><xsl:if test="position() != last()">/</xsl:if></xsl:for-each>", function(req , res) {          
    const request = new sql.Request(pool);
    request.input('branch_name', sql.NVarChar, req.params['branch']);
    <xsl:for-each select="columns/column[@is_primary_key=1]">
    request.input('<xsl:value-of select="@column_name" />', <xsl:value-of select="meta:datatype_to_node_mssql(@datatype)" />, req.params['<xsl:value-of select="@column_name" />']);</xsl:for-each>
    request.execute('dbo.delete_<xsl:value-of select="@table_name" />', (err, result) =&gt; {
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
app.post("/api/:branch/<xsl:value-of select="@table_name" />/<xsl:for-each select="columns/column[@is_primary_key=1]">:<xsl:value-of select="@column_name" /><xsl:if test="position() != last()">/</xsl:if></xsl:for-each>", function(req , res) {          
    const request = new sql.Request(pool);
    request.input('branch_name', sql.NVarChar, req.params['branch']);
    <xsl:for-each select="columns/column[@is_primary_key=1]">
    request.input('<xsl:value-of select="@column_name" />', <xsl:value-of select="meta:datatype_to_node_mssql(@datatype)" />, req.params['<xsl:value-of select="@column_name" />']);</xsl:for-each>
    
    for (var key in req.body) {
        if (req.body.hasOwnProperty(key)) {
            request.input(key, <xsl:value-of select="@table_name" />_field_to_node_mssql_datatype(key), req.body[key]);
        }
    }
    console.dir(req.body);
    request.execute('dbo.insert_<xsl:value-of select="@table_name" />', (err, result) =&gt; {
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
app.put("/api/:branch/<xsl:value-of select="@table_name" />/<xsl:for-each select="columns/column[@is_primary_key=1]">:<xsl:value-of select="@column_name" /><xsl:if test="position() != last()">/</xsl:if></xsl:for-each>", function(req , res) {          
    const request = new sql.Request(pool);
    request.input('branch_name', sql.NVarChar, req.params['branch']);
    <xsl:for-each select="columns/column[@is_primary_key=1]">
    request.input('<xsl:value-of select="@column_name" />', <xsl:value-of select="meta:datatype_to_node_mssql(@datatype)" />, req.params['<xsl:value-of select="@column_name" />']);</xsl:for-each>
    
    for (var key in req.body) {
        if (req.body.hasOwnProperty(key)) {
            request.input(key, <xsl:value-of select="@table_name" />_field_to_node_mssql_datatype(key), req.body[key]);
        }
    }
    request.execute('dbo.update_<xsl:value-of select="@table_name" />', (err, result) =&gt; {
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
