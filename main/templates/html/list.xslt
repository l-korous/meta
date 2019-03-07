<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="yes" encoding="UTF-8" omit-xml-declaration="yes" />
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
        <script src="https://code.jquery.com/jquery-3.3.1.slim.min.js">;</script>
		<script src="functions.js">;</script>
        <script>
            function loadCall() {
				var i = 1;
				loadListData('http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/api/master/<xsl:value-of select="@table_name" />', function(item) {
					var newElement = $(document.getElementById("body").appendChild(document.getElementById("entry-dummy").cloneNode(true)));
					newElement.attr("id", "entry" + i);
					<xsl:for-each select="columns/column[@is_primary_key=1]">
						$(newElement).find('.entryIdentifierField<xsl:value-of select="@column_name" />')[0].innerHTML = '<xsl:value-of select="@column_name" />: ' + item.<xsl:value-of select="@column_name" />;
					</xsl:for-each>
					<xsl:for-each select="columns/column[@is_primary_key=0]" >
						$(newElement).find('.entryField<xsl:value-of select="@column_name" />')[0].innerHTML = '<xsl:value-of select="@column_name" />: ' + item.<xsl:value-of select="@column_name" />;
					</xsl:for-each>
					
					// For each reference, where this table is src or dest
					<xsl:for-each select="//references/reference[@dest_table_name=$table_name or @src_table_name=$table_name]" >
						// 	take the other table
						<xsl:choose>
							<xsl:when test="@dest_table_name = $table_name"><xsl:variable name="ref_table_name" select="@src_table_name" /></xsl:when>
							<xsl:otherwise><xsl:variable name="ref_table_name" select="@dest_table_name" /></xsl:otherwise>
						</xsl:choose>
						
						// 	fire a get for it
						loadListData('http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/api/master/<xsl:value-of select="$ref_table_name" />?FilterBy=', function(childItem) {
							var newChildElement = $($(newElement).find('.entryLinks<xsl:value-of select="@reference_name" />')[0].appendChild(document.getElementById("entryLink-dummy").cloneNode(true)));
								
							newChildElement.attr("id", "entryLink<xsl:value-of select="@reference_name" />" + i);
							<xsl:for-each select="reference_details/reference_detail">
								<xsl:choose>
									<xsl:when test="@dest_table_name = $table_name"><xsl:variable name="ref_column_name" select="@src_column_name" /></xsl:when>
									<xsl:otherwise><xsl:variable name="ref_column_name" select="@dest_column_name" /></xsl:otherwise>
								</xsl:choose>
							
								$(newChildElement).find('.entryLinkIdentifierField<xsl:value-of select="$ref_column_name" />')[0].innerHTML = '<xsl:value-of select="$ref_column_name" />: ' + childItem.<xsl:value-of select="$ref_column_name" />;
							
								$(newChildElement).find('.entryLinkIdentifierField<xsl:value-of select="$ref_column_name" />')[0].href = '<xsl:value-of select="$ref_column_name" />: ' + childItem.<xsl:value-of select="$ref_column_name" />;
							</xsl:for-each>
							
							<!--
							<xsl:attribute name="href">'http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/app/<xsl:value-of select="@dest_table_name" />.html?<xsl:for-each select="reference_details/reference_detail" ><xsl:value-of select="@dest_column_name" /><xsl:if test="position() != last()">&amp;</xsl:if></xsl:for-each></xsl:attribute>
							-->
						});
					</xsl:for-each>
					i++;
				}, function() {
					$('#entry-dummy').remove();
				});
            }
        </script>
    </head>
<body onload="loadCall()" id="body">
    <nav>
		<xsl:for-each select="//table" >
        <div onmouseover="$('#new_{@table_name}').toggle()" onmouseout="$('#new_{@table_name}').toggle();" >
			<xsl:element name="a">
			  <xsl:if test="@table_name = $table_name">
				 <xsl:attribute name="class">currentPage</xsl:attribute>
			  </xsl:if>
			  <xsl:attribute name="href"><xsl:value-of select="@table_name" />.html</xsl:attribute>
			  <xsl:value-of select="@table_name" />
			</xsl:element>
            <xsl:element name="a">
			  <xsl:attribute name="class">hiddenNavLink</xsl:attribute>
			  <xsl:attribute name="id">new_<xsl:value-of select="@table_name" /></xsl:attribute>
			  <xsl:attribute name="href">new-<xsl:value-of select="@table_name" />.html</xsl:attribute>
			  New <xsl:value-of select="@table_name" /> 
			</xsl:element>
        </div>
		</xsl:for-each>
    </nav>
    <div>
        <div class="entry bubblar" id="entry-dummy">
            <xsl:for-each select="columns/column[@is_primary_key=1]" >
				<xsl:element name="h2">
					<xsl:attribute name="class">entryIdentifierField<xsl:value-of select="@column_name" /></xsl:attribute>
					<xsl:value-of select="@column_name" />:</xsl:element>
			</xsl:for-each>
			<xsl:for-each select="columns/column[@is_primary_key=0]" >
				<xsl:element name="div">
					<xsl:attribute name="class">entryField<xsl:value-of select="@column_name" /></xsl:attribute>
					<xsl:value-of select="@column_name" />:</xsl:element>
			</xsl:for-each>
            <xsl:for-each select="//references/reference[@dest_table_name=$table_name or @src_table_name=$table_name]" >
				<xsl:choose>
					<xsl:when test="@dest_table_name = $table_name"><xsl:variable name="ref_table_name" select="@src_table_name" /></xsl:when>
					<xsl:otherwise><xsl:variable name="ref_table_name" select="@dest_table_name" /></xsl:otherwise>
				</xsl:choose>
					
				<xsl:element name="div">
					<xsl:attribute name="class">entryLinks<xsl:value-of select="@reference_name" /></xsl:attribute>
					
					<xsl:element name="h3">
						<xsl:attribute name="class">entryLinksType</xsl:attribute>
						<xsl:value-of select="$ref_table_name" /> (<xsl:value-of select="@reference_name" />)</xsl:element>
					
					<a href="">
						<xsl:element name="div">
							<xsl:attribute name="class">addEntryLink</xsl:attribute>
							<xsl:attribute name="id">addEntryLink<xsl:value-of select="@reference_name" /></xsl:attribute>
							Add <xsl:value-of select="$ref_table_name" />(<xsl:value-of select="@reference_name" />)
						</xsl:element>
					</a>
					
					<xsl:element name="a">
						<xsl:attribute name="class">entryLink<xsl:value-of select="@reference_name" /></xsl:attribute>
						<xsl:attribute name="id">entryLink<xsl:value-of select="@reference_name" />-dummy</xsl:attribute>
						
						<xsl:for-each select="reference_details/reference_detail" >
							<xsl:choose>
								<xsl:when test="@dest_table_name = $table_name"><xsl:variable name="ref_column_name" select="@src_column_name" /></xsl:when>
								<xsl:otherwise><xsl:variable name="ref_column_name" select="@dest_column_name" /></xsl:otherwise>
							</xsl:choose>
							
							<xsl:element name="div">
								<xsl:attribute name="class">entryLinkIdentifierField<xsl:value-of select="$ref_column_name" /></xsl:attribute>
								<xsl:value-of select="$ref_column_name" />
							</xsl:element>
						</xsl:for-each>
					</xsl:element>
				</xsl:element>
			</xsl:for-each>
        </div>
    </div>
</body>
</html>
</xsl:result-document>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>