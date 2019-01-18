<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">

    <xsl:function name="meta:datatype_to_sql">
        <xsl:param name="dt"/>
        <xsl:choose>
            <xsl:when test="$dt = 'string'">NVARCHAR(255)</xsl:when>
            <xsl:when test="$dt = 'long_string'">NVARCHAR(MAX)</xsl:when>
            <xsl:when test="$dt = 'int'">INT</xsl:when>
            <xsl:when test="$dt = 'float'">FLOAT</xsl:when>
            <xsl:when test="$dt = 'datetime'">DATETIME</xsl:when>
            <xsl:when test="$dt = 'date'">DATE</xsl:when>
            <xsl:when test="$dt = 'boolean'">BIT</xsl:when>
            <xsl:when test="$dt = 'time'">TIME</xsl:when>
            <xsl:otherwise><xsl:value-of select="$dt" /></xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="meta:datatype_to_js">
        <xsl:param name="dt"/>
        <xsl:choose>
            <xsl:when test="$dt = 'string'">string</xsl:when>
            <xsl:when test="$dt = 'long_string'">string</xsl:when>
            <xsl:when test="$dt = 'int'">number</xsl:when>
            <xsl:when test="$dt = 'float'">number</xsl:when>
            <xsl:when test="$dt = 'datetime'">string</xsl:when>
            <xsl:when test="$dt = 'date'">string</xsl:when>
            <xsl:when test="$dt = 'boolean'">boolean</xsl:when>
            <xsl:when test="$dt = 'time'">string</xsl:when>
            <xsl:otherwise><xsl:value-of select="$dt" /></xsl:otherwise>
        </xsl:choose>
    </xsl:function>
        
    <xsl:function name="meta:datatype_to_swagger">
        <xsl:param name="dt"/>
        <xsl:choose>
            <xsl:when test="$dt = 'string'">string (max. 255 characters)</xsl:when>
            <xsl:when test="$dt = 'long_string'">string</xsl:when>
            <xsl:when test="$dt = 'int'">integer number</xsl:when>
            <xsl:when test="$dt = 'float'">floating-point number</xsl:when>
            <xsl:when test="$dt = 'datetime'">datetime ('YYYY-MM-DD HH:mm:ss.###')</xsl:when>
            <xsl:when test="$dt = 'date'">date ('YYYY-MM-DD')</xsl:when>
            <xsl:when test="$dt = 'boolean'">boolean</xsl:when>
            <xsl:when test="$dt = 'time'">time ('HH:mm:ss.###')</xsl:when>
            <xsl:otherwise><xsl:value-of select="$dt" /></xsl:otherwise>
        </xsl:choose>
    </xsl:function>
        
    <xsl:function name="meta:datatype_to_node_mssql">
        <xsl:param name="dt"/>
        <xsl:choose>
            <xsl:when test="$dt = 'string'">sql.NVarChar</xsl:when>
            <xsl:when test="$dt = 'long_string'">sql.NVarChar</xsl:when>
            <xsl:when test="$dt = 'int'">sql.Int</xsl:when>
            <xsl:when test="$dt = 'float'">sql.Int</xsl:when>
            <xsl:when test="$dt = 'datetime'">sql.DateTime</xsl:when>
            <xsl:when test="$dt = 'date'">sql.DateTime</xsl:when>
            <xsl:when test="$dt = 'boolean'">sql.Bit</xsl:when>
            <xsl:when test="$dt = 'time'">sql.DateTime</xsl:when>
            <xsl:otherwise>#$!ERROR#$!</xsl:otherwise>
        </xsl:choose>
    </xsl:function>
        
    <xsl:function name="meta:datatype_to_swagger_example">
        <xsl:param name="dt"/>
        <xsl:choose>
            <xsl:when test="$dt = 'string'">13-efg-41-ahs</xsl:when>
            <xsl:when test="$dt = 'long_string'">This is a looong text</xsl:when>
            <xsl:when test="$dt = 'int'">13</xsl:when>
            <xsl:when test="$dt = 'float'">258.89</xsl:when>
            <xsl:when test="$dt = 'datetime'">'2020-10-20 10:20:10.123'</xsl:when>
            <xsl:when test="$dt = 'date'">'2020-10-20'</xsl:when>
            <xsl:when test="$dt = 'boolean'">true</xsl:when>
            <xsl:when test="$dt = 'time'">'10:20:10.123'</xsl:when>
            <xsl:otherwise>#$!ERROR#$!</xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>