<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="yes" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
<xsl:for-each select="//table" >
<xsl:variable name="table_name" select="@table_name"/>
<xsl:result-document method="xml" href="functions_{@table_name}.js">
function getApiQueryString() {
    const defaultQueryString = '?';
    var queryString = '?';
    const urlParams = new URLSearchParams(window.location.search);
       
    if(window.location.search.substring(1) == '') 
        return defaultQueryString;
    else {
    <xsl:for-each select="columns/column[@is_primary_key=1]">
        if(urlParams.get('<xsl:value-of select="column_name" />') == null || urlParams.get('<xsl:value-of select="column_name" />') == '')
            return defaultQueryString;
        queryString += 'FilterBy[<xsl:value-of select="position() - 1"/>][col]=<xsl:value-of select="@column_name" /><xsl:text disable-output-escaping="yes">&amp;FilterBy</xsl:text>[<xsl:value-of select="position() - 1"/>][regex]=' + urlParams.get('<xsl:value-of select="@column_name" />') + '<xsl:if test="position() != last()"><xsl:text disable-output-escaping="yes">&amp;</xsl:text></xsl:if>';
    </xsl:for-each>
    }
    return queryString;
}

<xsl:for-each select="//references/reference[@dest_table_name=$table_name or @src_table_name=$table_name]" >
<xsl:variable name="ref_table_name" select="if(@dest_table_name = $table_name) then @src_table_name else @dest_table_name" />
function getLinks<xsl:value-of select="@reference_name" />ApiUrl(item) {
    var toReturn = 'http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/api/master/<xsl:value-of select="$ref_table_name" />?';
    <xsl:for-each select="reference_details/reference_detail">
        <xsl:variable name="ref_column_name" select="if(@dest_table_name = $table_name) then @src_column_name else @dest_column_name" />
        <xsl:variable name="this_column_name" select="if(@dest_table_name = $table_name) then @dest_column_name else @src_column_name" />
        toReturn += 'FilterBy[<xsl:value-of select="position() - 1"/>][col]=<xsl:value-of select="$ref_column_name" /><xsl:text disable-output-escaping="yes">&amp;FilterBy</xsl:text>[<xsl:value-of select="position() - 1"/>][regex]=';
        toReturn += item.<xsl:value-of select="$this_column_name" /><xsl:if test="position() != last()"><xsl:text disable-output-escaping="yes"> + '&amp;'</xsl:text></xsl:if>;
    </xsl:for-each>
    return toReturn;
}

function getRefLink<xsl:value-of select="@reference_name" />AppUrl(childItem) {
    var toReturn='http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/app/<xsl:value-of select="$ref_table_name" />.html?';
    <xsl:for-each select="//tables/table[@table_name=$ref_table_name]/columns/column[@is_primary_key=1]">
        toReturn += '<xsl:value-of select="@column_name" />=';
        toReturn += childItem.<xsl:value-of select="@column_name" /><xsl:if test="position() != last()"><xsl:text disable-output-escaping="yes">+ '&amp;'</xsl:text></xsl:if>;
    </xsl:for-each>
    return toReturn;
}

function getRefLink<xsl:value-of select="@reference_name" />ApiUrl(childItem) {
    var toReturn='http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/api/master/<xsl:value-of select="$ref_table_name" />';
    <xsl:for-each select="reference_details/reference_detail">
        <xsl:variable name="ref_column_name" select="if(@dest_table_name = $table_name) then @src_column_name else @dest_column_name" />
        toReturn += '/' +  item.<xsl:value-of select="$ref_column_name" />;
    </xsl:for-each>
    return toReturn;
}
</xsl:for-each>

function getLink<xsl:value-of select="$table_name" />(item) {
    var toReturn='http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/api/master/<xsl:value-of select="$table_name" />';
    <xsl:for-each select="columns/column[@is_primary_key=1]">
        toReturn += '/' +  item.<xsl:value-of select="@column_name" />;
    </xsl:for-each>
    return toReturn;
}
    
function saveNew() {
    var body = {
        <xsl:for-each select="columns/column" >
        <xsl:value-of select="@column_name" />: $('<xsl:value-of select="meta:datatype_to_html_element(@datatype)" />[name=new_<xsl:value-of select="@column_name" />]').val()<xsl:if test="position() != last()">,
        </xsl:if></xsl:for-each>
    };
    post_item(getLink<xsl:value-of select="$table_name" />(body), body, function() {
       location = 'http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/app/<xsl:value-of select="$table_name" />.html';
    });
}
    
function save(i) {
    var body = {
        <xsl:for-each select="columns/column" >
        <xsl:value-of select="@column_name" />: $('<xsl:value-of select="meta:datatype_to_html_element(@datatype)" />[name=' + i + '<xsl:value-of select="@column_name" />]').val()<xsl:if test="position() != last()">,
        </xsl:if></xsl:for-each>
    };
    put_item(getLink<xsl:value-of select="$table_name" />(body), body, function() {
       location = 'http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/app/<xsl:value-of select="$table_name" />.html';
    });
}

function handleNew() {
    const urlParams = new URLSearchParams(window.location.search);
    if(urlParams.get('new') != null) {
        $('.entryNew').show();
    }
}

function loadCall() {
    handleNew();
    
    var i = 1;
    var query = getApiQueryString();
    get('http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/api/master/<xsl:value-of select="@table_name" />' + query, function(item) {
        var newElement = $(document.getElementById("body").appendChild(document.getElementById("entry-dummy").cloneNode(true)));
        newElement.attr("id", "entry" + i);
        
        $(newElement).find('.entryDeleter')[0].onclick = function() {
            delete_item(getLink<xsl:value-of select="$table_name" />(item), function() { location.reload(); });
        }
        
        $(newElement).find('.editButton').attr('i', i);
        <xsl:for-each select="columns/column[@is_primary_key=1]">
        $(newElement).find('.entryIdentifierField<xsl:value-of select="@column_name" />')[0].innerHTML = '<xsl:value-of select="@column_name" />: ' + item.<xsl:value-of select="@column_name" />;
        $(newElement).find('[name=dummy_<xsl:value-of select="@column_name" />]').val(item.<xsl:value-of select="@column_name" />);
        $(newElement).find('[name=dummy_<xsl:value-of select="@column_name" />]').attr('name', i + '<xsl:value-of select="@column_name" />');
        $(newElement).find('[for=dummy_<xsl:value-of select="@column_name" />]').attr('for', i + '<xsl:value-of select="@column_name" />');
        </xsl:for-each>
        <xsl:for-each select="columns/column[@is_primary_key=0]" >
        $(newElement).find('.entryField<xsl:value-of select="@column_name" />')[0].innerHTML = '<xsl:value-of select="@column_name" />: ' + item.<xsl:value-of select="@column_name" />;
        $(newElement).find('[name=dummy_<xsl:value-of select="@column_name" />]').val(item.<xsl:value-of select="@column_name" />);
        $(newElement).find('[name=dummy_<xsl:value-of select="@column_name" />]').attr('name', i + '<xsl:value-of select="@column_name" />');
        $(newElement).find('[for=dummy_<xsl:value-of select="@column_name" />]').attr('for', i + '<xsl:value-of select="@column_name" />');
        </xsl:for-each>
        <xsl:for-each select="//references/reference[@dest_table_name=$table_name or @src_table_name=$table_name]" >
        <!-- For each reference, where this table is src or dest take the other table and fire a GET for it -->
        var i_<xsl:value-of select="@reference_name" /> = 1;
        <xsl:variable name="ref_table_name" select="if(@dest_table_name = $table_name) then @src_table_name else @dest_table_name" />
        get(getLinks<xsl:value-of select="@reference_name" />ApiUrl(item), function(childItem) {
            var newChildElement = $($(newElement).find('.entryLinks<xsl:value-of select="@reference_name" />')[0].appendChild(document.getElementById("entryLinkDiv<xsl:value-of select="@reference_name" />-dummy").cloneNode(true)));
            newChildElement.attr("id", newElement.attr("id") + "Link<xsl:value-of select="@reference_name" />" + i_<xsl:value-of select="@reference_name" />++);
            <xsl:for-each select="//tables/table[@table_name=$ref_table_name]/columns/column[@is_primary_key=1]">
            $(newChildElement).find('.entryLinkIdentifierField<xsl:value-of select="@column_name" />')[0].innerHTML = '<xsl:value-of select="@column_name" />: ' + childItem.<xsl:value-of select="@column_name" />;
            </xsl:for-each>
            $(newChildElement).find('.entryLinkA')[0].href = getRefLink<xsl:value-of select="@reference_name" />AppUrl(childItem);
            $(newChildElement).find('.entryLinkDeleter')[0].onclick = function() {
                delete_item(getRefLink<xsl:value-of select="@reference_name" />ApiUrl(childItem), function() {
                    window.reload();
                });
            }
        }, function() {
            $('#entryLinkDiv<xsl:value-of select="@reference_name" />-dummy').remove();
        });
        </xsl:for-each>
        i++;
    }, function() {
        $('#entry-dummy').remove();
    });
}
</xsl:result-document>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>