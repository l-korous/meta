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

</xsl:stylesheet>