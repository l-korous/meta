<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
<xsl:for-each select="//table" >
<xsl:result-document method="xml" href="{@table_name}.html">
<html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0, user-scalable=0, width=device-width">
        <title id="title">Loading...</title>
        <link rel="stylesheet" type="text/css" href="style.css" />
        
        <script>
            function getParameterByName(name, url) {
                if (!url) url = window.location.href;
                name = name.replace(/[\[\]]/g, '\\$&amp;');
                var regex = new RegExp('[?&amp;]' + name + '(=([^&amp;#]*)|&amp;|#|$)'),
                    results = regex.exec(url);
                if (!results) return null;
                if (!results[2]) return '';
                return decodeURIComponent(results[2].replace(/\+/g, ' '));
            }

            async function loadData() {
                var id = getParameterByName("<xsl:value-of select="@table_name" />");
                const response = await fetch('XYZ/XYZ_id');
                const myJson = await response.json();
                document.getElementById("title").innerHTML = myJson.origin;
            }
        </script>
    </head>
<body onload="loadData()">
    <nav>
        <div onmouseover="$('#new_XYZ').toggle();" onmouseout="$('#new_XYZ').toggle();">
            <a href="XYZ.html">XYZ</a>
            <a class="hiddenNavLink" id="new_XYZ" href="new-XYZ.html">New XYZ</a>
        </div>
    </nav>
    <div>
        <div class="entry bubblar">
            <h2 class="entryIdentifierField" id="entryIdentifierField">Loading...</h2>
            <div class="entryField" id="entryFieldXYZ">Loading...</div>
            <div class="entryLinks">
                <h3 class="entryLinksType" id="entryLinksTypeXYZ">XYZ</h3>
                <div class="entryLink" id="entryLinkXYZID">
                    <a href="XYZ.html?XYZ_id=ID">
                        <div class="entryLinkIdentifierField" id="entryLinkXYZIDIdentifierField">Loading...</div>
                    </a>
                    <div class="entryLinkField" id="entryLinkXYZIDFieldXYZ">Loading...</div>
                </div>
                <a href=""><div class="addEntryLinkXYZ">Add XYZ</div></a>
            </div>
        </div>
    </div>
</body>
</html>
</xsl:result-document>