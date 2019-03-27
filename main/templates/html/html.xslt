<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY s "&#160;">]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
<xsl:for-each select="//table" >
<xsl:variable name="table_name" select="@table_name"/>
<xsl:result-document method="xml" href="{@table_name}.html">
<html>
    <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0, user-scalable=0, width=device-width" />
        <title id="title">Loading...</title>
        <link rel="stylesheet" type="text/css" href="style.css" />
        <script src="jquery-3.3.1.slim.min.js">;</script>
        <script src="functions.js">;</script>
        <xsl:element name="script"><xsl:attribute name="src">functions_<xsl:value-of select="@table_name" />.js</xsl:attribute>;</xsl:element>
    </head>
<body onload="loadCall()" id="body">
    <nav>
		<xsl:for-each select="//table" >
            <div class="navLinkBundle">
                <xsl:element name="a">
                    <xsl:attribute name="class">listNavButton<xsl:if test="@table_name = $table_name"> currentPage</xsl:if></xsl:attribute>
                    <xsl:attribute name="href"><xsl:value-of select="@table_name" />.html</xsl:attribute>
                    <xsl:value-of select="@table_name" />
                </xsl:element><xsl:element name="a">
                    <xsl:attribute name="class">newNavButton</xsl:attribute>
                    <xsl:attribute name="id">new_<xsl:value-of select="@table_name" /></xsl:attribute>
                    <xsl:attribute name="href"><xsl:value-of select="@table_name" />.html?new=1</xsl:attribute>
                    <span></span>
                </xsl:element>
            </div>
		</xsl:for-each>
    </nav>
    <div id="errorDiv" style="display:none;"><xsl:text disable-output-escaping="yes">&#160;</xsl:text></div>
    <div>
        <div class="entry bubblar entryNew" style="display:none">
            <xsl:for-each select="columns/column" >
                <div>
                    <xsl:element name="label">
                        <xsl:attribute name="for">new_<xsl:value-of select="@column_name" /></xsl:attribute>
                        <xsl:value-of select="@column_name" />
                    </xsl:element>
                    <xsl:choose>
                        <xsl:when test="meta:datatype_to_html_element(@datatype) = 'input'" >
                            <xsl:element name="input">
                                <xsl:attribute name="type"><xsl:value-of select="meta:datatype_to_html_input_type(@datatype)" /></xsl:attribute>
                                <xsl:if test="meta:datatype_to_html_input_attribute_name(@datatype) != ''">
                                    <xsl:attribute name="{meta:datatype_to_html_input_attribute_name(@datatype)}">
                                        <xsl:value-of select="meta:datatype_to_html_input_attribute_value(@datatype)" />
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:attribute name="name">new_<xsl:value-of select="@column_name" /></xsl:attribute>
                            </xsl:element>
                        </xsl:when>
                        <xsl:when test="meta:datatype_to_html_element(@datatype) = 'textarea'" >
                            <xsl:element name="textarea"><xsl:attribute name="name">new_<xsl:value-of select="@column_name" /></xsl:attribute>&s;</xsl:element>
                        </xsl:when>
                    </xsl:choose>
                    <ul class="whisperer" style="display:none"> </ul>
                </div>
			</xsl:for-each>
            <button class="saveButton" type="button" onclick="saveNew()">Save</button>
            <button class="cancelNewButton" type="button" onclick="$('.entryNew').hide()">Cancel</button>
        </div>
        <div class="entry bubblar" id="entry-dummy">
            <xsl:if test="count(columns/column[@is_primary_key=0]) &gt; 0">
            <div class="write" style="display:none">
                <button class="editButton" onclick="$(this).parent().toggle();$(this).parent().next().toggle();save($(this).attr('i'));">Save</button>
                <button class="cancelEditButton" type="button" onclick="$(this).parent().toggle();$(this).parent().next().toggle();">Cancel</button>
                <xsl:for-each select="columns/column" >
                    <div>
                        <xsl:element name="label">
                            <xsl:attribute name="for">dummy_<xsl:value-of select="@column_name" /></xsl:attribute>
                            <xsl:value-of select="@column_name" />
                        </xsl:element>
                        <xsl:choose>
                            <xsl:when test="meta:datatype_to_html_element(@datatype) = 'input'" >
                                <xsl:element name="input">
                                    <xsl:attribute name="type"><xsl:value-of select="meta:datatype_to_html_input_type(@datatype)" /></xsl:attribute>
                                    <xsl:attribute name="name">dummy_<xsl:value-of select="@column_name" /></xsl:attribute>
                                    <xsl:if test="@is_primary_key=1">
                                        <xsl:attribute name="readonly" />
                                    </xsl:if>
                                </xsl:element>
                            </xsl:when>
                            <xsl:when test="meta:datatype_to_html_element(@datatype) = 'textarea'" >
                                <xsl:element name="textarea"><xsl:attribute name="name">dummy_<xsl:value-of select="@column_name" /></xsl:attribute>&s;</xsl:element>
                            </xsl:when>
                        </xsl:choose>
                        <ul class="whisperer" style="display:none"> </ul>
                    </div>
                </xsl:for-each>
            </div>
            </xsl:if>
            <div class="read">
                <xsl:if test="count(columns/column[@is_primary_key=0]) &gt; 0"><button class="editButton" onclick="$(this).parent().toggle();$(this).parent().prev().toggle();">Edit</button></xsl:if>
                <button class="entryDeleter">Delete</button>
                <xsl:for-each select="columns/column[@is_primary_key=1]" >
                    <xsl:element name="h2">
                        <xsl:attribute name="class">entryIdentifierField entryIdentifierField<xsl:value-of select="@column_name" /></xsl:attribute>
                        &s;
                    </xsl:element>
                </xsl:for-each>
                <xsl:for-each select="columns/column[@is_primary_key=0]" >
                    <xsl:element name="div">
                        <xsl:attribute name="class">entryField entryField<xsl:value-of select="@column_name" /></xsl:attribute>
                        &s;
                    </xsl:element>
                </xsl:for-each>
                <xsl:for-each select="//references/reference[@referenced_table_name=$table_name]" >
                    <xsl:variable name="referencing_table_name" select="@referencing_table_name" />
                        
                    <xsl:element name="div">
                        <xsl:attribute name="class">entryLinks entryLinks<xsl:value-of select="@reference_name" /></xsl:attribute>
                        
                        <xsl:element name="h3">
                            <xsl:attribute name="class">entryLinksType</xsl:attribute>
                            <xsl:value-of select="$referencing_table_name" /> (<xsl:value-of select="@reference_name" />)</xsl:element>
                        
                        <xsl:element name="button">
                                <xsl:attribute name="class">addEntryLink</xsl:attribute>
                                <xsl:attribute name="id">addEntryLink<xsl:value-of select="@reference_name" /></xsl:attribute>
                                Add <xsl:value-of select="$referencing_table_name" /> (<xsl:value-of select="@reference_name" />)
                        </xsl:element>
                        
                        <xsl:element name="div">
                            <xsl:attribute name="class">entryLinkDiv entryLinkDiv<xsl:value-of select="@reference_name" /></xsl:attribute>
                            <xsl:attribute name="id">entryLinkDiv<xsl:value-of select="@reference_name" />-dummy</xsl:attribute>
                            <button class="entryLinkDeleter">Delete</button>
                            <xsl:element name="a">
                                <xsl:attribute name="class">entryLinkA entryLinkA<xsl:value-of select="@reference_name" /></xsl:attribute>
                                <xsl:for-each select="//tables/table[@table_name=$referencing_table_name]/columns/column[@is_primary_key=1]">
                                    <xsl:element name="div">
                                        <xsl:attribute name="class">entryLinkIdentifierField<xsl:value-of select="@column_name" /></xsl:attribute>
                                        <xsl:text disable-output-escaping="yes">&#160;</xsl:text>
                                    </xsl:element>
                                </xsl:for-each>
                            </xsl:element>
                        </xsl:element>
                    </xsl:element>
                </xsl:for-each>
            </div>
        </div>
    </div>
</body>
</html>
</xsl:result-document>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>