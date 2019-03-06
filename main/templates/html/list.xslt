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
            <div class="entryLinks">
				<xsl:for-each select="references/reference" >
					<xsl:variable name="dest_table_name" select="@dest_table_name"/>
					<xsl:element name="h3">
						<xsl:attribute name="class">entryLinksType</xsl:attribute>
						<xsl:value-of select="@dest_table_name" /> (<xsl:value-of select="@reference_name" />)</xsl:element>
					
					<xsl:element name="a">
						<xsl:attribute name="class">entryLink</xsl:attribute>
						<xsl:attribute name="id">entryLink<xsl:value-of select="@reference_name" /></xsl:attribute>
						<xsl:attribute name="href">'http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/app/<xsl:value-of select="@dest_table_name" />.html?<xsl:for-each select="reference_details/reference_detail" ><xsl:value-of select="@dest_column_name" /><xsl:if test="position() != last()">&amp;</xsl:if>
							</xsl:for-each>
						</xsl:attribute>
						<xsl:for-each select="reference_details/reference_detail" >
							<xsl:element name="div">
								<xsl:attribute name="class">entryLinkIdentifierField</xsl:attribute>
								<xsl:attribute name="id">entryLinkIdentifierField<xsl:value-of select="@dest_column_name" /></xsl:attribute>
								<xsl:value-of select="@dest_column_name" />
							</xsl:element>
						</xsl:for-each>
					</xsl:element>
					
					<a href="">
						<xsl:element name="div">
							<xsl:attribute name="class">addEntryLink</xsl:attribute>
							<xsl:attribute name="id">addEntryLink<xsl:value-of select="@reference_name" /></xsl:attribute>
							Add <xsl:value-of select="@dest_table_name" />(<xsl:value-of select="@reference_name" />)
						</xsl:element>
					</a>
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