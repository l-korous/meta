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
        if(urlParams.get('<xsl:value-of select="@column_name" />') == null || urlParams.get('<xsl:value-of select="@column_name" />') == '')
            return defaultQueryString;
        queryString += 'FilterBy[<xsl:value-of select="position() - 1"/>][col]=<xsl:value-of select="@column_name" /><xsl:text disable-output-escaping="yes">&amp;FilterBy</xsl:text>[<xsl:value-of select="position() - 1"/>][regex]=' + urlParams.get('<xsl:value-of select="@column_name" />') + '<xsl:if test="position() != last()"><xsl:text disable-output-escaping="yes">&amp;</xsl:text></xsl:if>';
    </xsl:for-each>
    }
    return queryString;
}

<xsl:for-each select="//references/reference[@referenced_table_name=$table_name]" >
<xsl:variable name="referencing_table_name" select="@referencing_table_name" />
function getLinks<xsl:value-of select="@reference_name" />ApiUrl(item) {
    var toReturn = 'http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/api/master/<xsl:value-of select="$referencing_table_name" />?';
    <xsl:for-each select="reference_details/reference_detail">
        toReturn += 'FilterBy[<xsl:value-of select="position() - 1"/>][col]=<xsl:value-of select="@referencing_column_name" /><xsl:text disable-output-escaping="yes">&amp;FilterBy</xsl:text>[<xsl:value-of select="position() - 1"/>][regex]=';
        toReturn += item.<xsl:value-of select="@referencing_column_name" /><xsl:if test="position() != last()"><xsl:text disable-output-escaping="yes"> + '&amp;'</xsl:text></xsl:if>;
    </xsl:for-each>
    return toReturn;
}

function getPrimaryRefLink<xsl:value-of select="@reference_name" />AppUrl(linkedItem) {
    var toReturn='http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/app/<xsl:value-of select="$referencing_table_name" />.html?';
    <xsl:for-each select="//tables/table[@table_name=$referencing_table_name]/columns/column[@is_primary_key=1]">
        toReturn += '<xsl:value-of select="@column_name" />=';
        toReturn += linkedItem.<xsl:value-of select="@column_name" /><xsl:if test="position() != last()"><xsl:text disable-output-escaping="yes">+ '&amp;'</xsl:text></xsl:if>;
    </xsl:for-each>
    return toReturn;
}

function getNewRefLink<xsl:value-of select="@reference_name" />AppUrl(linkedItem) {
    var toReturn='http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/app/<xsl:value-of select="$referencing_table_name" />.html?new=1';
    
    Object.entries(linkedItem).forEach(entry =<xsl:text disable-output-escaping="yes">&gt;</xsl:text> {
        let key = entry[0];
        let value = entry[1];
        toReturn += <xsl:text disable-output-escaping="yes">'&amp;'</xsl:text> + key + '=' + value;
    });

    return toReturn;
}

function getRefLink<xsl:value-of select="@reference_name" />ApiUrl(linkedItem) {
    var toReturn='http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/api/master/<xsl:value-of select="$referencing_table_name" />';
    <xsl:for-each select="reference_details/reference_detail">
        toReturn += '/' +  item.<xsl:value-of select="@referenced_column_name" />;
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
        <xsl:value-of select="@column_name" />: $('<xsl:value-of select="meta:datatype_to_html_element(@datatype)" />[name=new_<xsl:value-of select="@column_name" />]').val() == '' ? null : $('<xsl:value-of select="meta:datatype_to_html_element(@datatype)" />[name=new_<xsl:value-of select="@column_name" />]').val()<xsl:if test="position() != last()">,
        </xsl:if></xsl:for-each>
    };
    post_item(getLink<xsl:value-of select="$table_name" />(body), body, function() {
       location = 'http://<xsl:value-of select="//configuration[@key='NodeJsHostname']/@value" />:<xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />/app/<xsl:value-of select="$table_name" />.html';
    });
}
    
function save(i) {
    var body = {
        <xsl:for-each select="columns/column" >
        <xsl:value-of select="@column_name" />: $('<xsl:value-of select="meta:datatype_to_html_element(@datatype)" />[name=' + i + '<xsl:value-of select="@column_name" />]').val() == '' ? null : $('<xsl:value-of select="meta:datatype_to_html_element(@datatype)" />[name=' + i + '<xsl:value-of select="@column_name" />]').val()<xsl:if test="position() != last()">,
        </xsl:if></xsl:for-each>
    };
    put_item(getLink<xsl:value-of select="$table_name" />(body), body, function() {
       location = window.location;
    });
}

function handleNew() {
    const urlParams = new URLSearchParams(window.location.search);
    if(urlParams.get('new') != null) {
        $('.entryNew').show();
        var item = {};
        <xsl:for-each select="columns/column">
        if(urlParams.get('<xsl:value-of select="@column_name" />') <xsl:text disable-output-escaping="yes">&amp;&amp;</xsl:text> urlParams.get('<xsl:value-of select="@column_name" />') != '')
            item['<xsl:value-of select="@column_name" />'] = urlParams.get('<xsl:value-of select="@column_name" />');
        </xsl:for-each>
        <xsl:for-each select="columns/column">
        <xsl:value-of select="@column_name" />_field_to_input_value(item, $('.entryNew').find('[name=new_<xsl:value-of select="@column_name" />]'));
        </xsl:for-each>
    }
}

<xsl:for-each select="columns/column" >
function <xsl:value-of select="@column_name" />_field_to_input_value(item, elem) {
    var fieldValue = item.<xsl:value-of select="@column_name" />;
    if(fieldValue)
        <xsl:value-of select="meta:datatype_to_input_value_conversion(@datatype)" />;
}</xsl:for-each>

<xsl:for-each select="columns/column" >
function <xsl:value-of select="@column_name" />_field_to_js_datatype_conversion(item) {
    var fieldValue = item.<xsl:value-of select="@column_name" />;
    return fieldValue ? <xsl:value-of select="meta:datatype_to_js_conversion(@datatype)" /> : null;
}</xsl:for-each>

<xsl:for-each select="columns/column" >
function <xsl:value-of select="@column_name" />_field_to_html_conversion(item) {
    var fieldValue = <xsl:value-of select="@column_name" />_field_to_js_datatype_conversion(item);
    return fieldValue ? fieldValue<xsl:value-of select="meta:js_to_html_conversion(@datatype)" /> : null;
}</xsl:for-each>

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
        <!-- Read & Write -->
        <xsl:for-each select="columns/column" >
        $(newElement).find('.entry<xsl:if test="@is_primary_key=1">Identifier</xsl:if>Field<xsl:value-of select="@column_name" />')[0].innerHTML = '<xsl:value-of select="@column_name" />: ' + <xsl:value-of select="@column_name" />_field_to_html_conversion(item);
        <xsl:value-of select="@column_name" />_field_to_input_value(item, $(newElement).find('[name=dummy_<xsl:value-of select="@column_name" />]'));
        $(newElement).find('[name=dummy_<xsl:value-of select="@column_name" />]').attr('name', i + '<xsl:value-of select="@column_name" />');
        $(newElement).find('[for=dummy_<xsl:value-of select="@column_name" />]').attr('for', i + '<xsl:value-of select="@column_name" />');
        </xsl:for-each>
        
        <!-- For each reference, where this table is src or dest take the other table and: -->
        <xsl:for-each select="//references/reference[@referenced_table_name=$table_name]" >
        <xsl:variable name="referencing_table_name" select="@referencing_table_name" />
        <!-- 1) create '+' handler -->
        $(newElement).find('#addEntryLink<xsl:value-of select="@reference_name" />').click(function() {
            var linkedItem = {};
            <xsl:for-each select="reference_details/reference_detail">
                linkedItem.<xsl:value-of select="@referencing_column_name" /> = item.<xsl:value-of select="@referenced_column_name" />;
            </xsl:for-each>
            window.location = getNewRefLink<xsl:value-of select="@reference_name" />AppUrl(linkedItem);
        });
        <!-- 2) fire a GET for populating the list -->
        var i_<xsl:value-of select="@reference_name" /> = 1;
        get(getLinks<xsl:value-of select="@reference_name" />ApiUrl(item), function(linkedItem) {
            var newChildElement = $($(newElement).find('.entryLinks<xsl:value-of select="@reference_name" />')[0].appendChild(document.getElementById("entryLinkDiv<xsl:value-of select="@reference_name" />-dummy").cloneNode(true)));
            newChildElement.attr("id", newElement.attr("id") + "Link<xsl:value-of select="@reference_name" />" + i_<xsl:value-of select="@reference_name" />++);
            <xsl:for-each select="//tables/table[@table_name=$referencing_table_name]/columns/column[@is_primary_key=1]">
            $(newChildElement).find('.entryLinkIdentifierField<xsl:value-of select="@column_name" />')[0].innerHTML = '<xsl:value-of select="@column_name" />: ' + linkedItem.<xsl:value-of select="@column_name" />;
            </xsl:for-each>
            $(newChildElement).find('.entryLinkA')[0].href = getPrimaryRefLink<xsl:value-of select="@reference_name" />AppUrl(linkedItem);
            $(newChildElement).find('.entryLinkDeleter')[0].onclick = function() {
                delete_item(getRefLink<xsl:value-of select="@reference_name" />ApiUrl(linkedItem), function() {
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