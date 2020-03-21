<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="yes" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
<xsl:for-each select="//table" >
<xsl:variable name="table_name" select="@table_name"/>
<xsl:result-document method="xml" href="functions_{@table_name}.js">
async function errorHandler(error) {
    var text = '';
    if(Object.prototype.toString.call(error) == '[object Response]') {
        var responseJson = await error.json();
        text = responseJson.originalError ? responseJson.originalError.info.message : error.statusText;
    }
    else
        text = error.toString();
        
    $('#errorDiv').text(text);
    $('#errorDiv').show();
}

function getApiQueryString() {
    var queryString = '?';
    const urlParams = new URLSearchParams(window.location.search);
       
    if(window.location.search.substring(1) != '') {
    <xsl:for-each select="columns/column[@is_primary_key=1]">
        if(!(urlParams.get('<xsl:value-of select="@column_name" />') == null || urlParams.get('<xsl:value-of select="@column_name" />') == ''))
            queryString += 'FilterBy[<xsl:value-of select="position() - 1"/>][col]=<xsl:value-of select="@column_name" /><xsl:text disable-output-escaping="yes">&amp;FilterBy</xsl:text>[<xsl:value-of select="position() - 1"/>][regex]=' + encodeURIComponent(urlParams.get('<xsl:value-of select="@column_name" />')) + '<xsl:if test="position() != last()"><xsl:text disable-output-escaping="yes">&amp;</xsl:text></xsl:if>';
    </xsl:for-each>
    }
    return queryString;
}

<xsl:for-each select="//table//columns/column[@referenced_table_name=$table_name]" >
<xsl:variable name="referencing_table_name" select="../../@table_name" />
<xsl:variable name="referencing_column_name" select="@column_name" />
function getLinks<xsl:value-of select="$referencing_table_name" />ApiUrl(item) {
    var toReturn = '/api/data/master/<xsl:value-of select="$referencing_table_name" />?';
    toReturn += 'FilterBy[<xsl:value-of select="position() - 1"/>][col]=<xsl:value-of select="$referencing_column_name" /><xsl:text disable-output-escaping="yes">&amp;FilterBy</xsl:text>[<xsl:value-of select="position() - 1"/>][regex]=';
    toReturn += encodeURIComponent(item.<xsl:value-of select="@referenced_column_name" />)<xsl:if test="position() != last()"><xsl:text disable-output-escaping="yes"> + '&amp;'</xsl:text></xsl:if>;
return toReturn;
}

function getPrimaryRefLink<xsl:value-of select="$referencing_table_name" />AppUrl(linkedItem) {
    var toReturn='/app/<xsl:value-of select="$referencing_table_name" />.html?';
    <xsl:for-each select="//tables/table[@table_name=$referencing_table_name]/columns/column[@is_primary_key=1]">
        toReturn += '<xsl:value-of select="@column_name" />=';
        toReturn += encodeURIComponent(linkedItem.<xsl:value-of select="@column_name" />)<xsl:if test="position() != last()"><xsl:text disable-output-escaping="yes">+ '&amp;'</xsl:text></xsl:if>;
    </xsl:for-each>
    return toReturn;
}

function getNewRefLink<xsl:value-of select="$referencing_table_name" />AppUrl(linkedItem) {
    var toReturn='/app/<xsl:value-of select="$referencing_table_name" />.html?new=1';
    
    Object.entries(linkedItem).forEach(entry =<xsl:text disable-output-escaping="yes">&gt;</xsl:text> {
        let key = entry[0];
        let value = entry[1];
        toReturn += <xsl:text disable-output-escaping="yes">'&amp;'</xsl:text> + key + '=' + value;
    });

    return toReturn;
}

function getRefLink<xsl:value-of select="$referencing_table_name" />ApiUrl(linkedItem) {
    var toReturn='/api/data/master/<xsl:value-of select="$referencing_table_name" />';
    
    <xsl:for-each select="//tables/table[@table_name=$referencing_table_name]/columns/column[@is_primary_key=1]">
        toReturn += '/' +  encodeURIComponent(linkedItem.<xsl:value-of select="@column_name" />);
    </xsl:for-each>
    
    return toReturn;
}
</xsl:for-each>

function getLink<xsl:value-of select="$table_name" />(item) {
    var toReturn='/api/data/master/<xsl:value-of select="$table_name" />';
    <xsl:for-each select="columns/column[@is_primary_key=1]">
        toReturn += '/' +  encodeURIComponent(item.<xsl:value-of select="@column_name" />);
    </xsl:for-each>
    return toReturn;
}
    
function saveNew() {
    var body = {
        <xsl:for-each select="columns/column" >
        <xsl:value-of select="@column_name" />: $('<xsl:value-of select="meta:datatype_to_html_element(@datatype)" />[name=new_<xsl:value-of select="@column_name" />]').val() == '' ? null : $('<xsl:value-of select="meta:datatype_to_html_element(@datatype)" />[name=new_<xsl:value-of select="@column_name" />]').val()<xsl:if test="position() != last()">,
        </xsl:if></xsl:for-each>
    };
    meta_api_post(getLink<xsl:value-of select="$table_name" />(body), body, function() {
       location = '/app/<xsl:value-of select="$table_name" />.html';
    }, errorHandler);
}
    
function save(i) {
    var body = {
        <xsl:for-each select="columns/column" >
        <xsl:value-of select="@column_name" />: $('<xsl:value-of select="meta:datatype_to_html_element(@datatype)" />[name=' + i + '<xsl:value-of select="@column_name" />]').val() == '' ? null : $('<xsl:value-of select="meta:datatype_to_html_element(@datatype)" />[name=' + i + '<xsl:value-of select="@column_name" />]').val()<xsl:if test="position() != last()">,
        </xsl:if></xsl:for-each>
    };
    meta_api_put(getLink<xsl:value-of select="$table_name" />(body), body, function() {
       location = window.location;
    }, errorHandler);
}

function handleNew() {
    const urlParams = new URLSearchParams(window.location.search);
    if(urlParams.get('new') != null) {
        $('.entryNew').show();
        <!-- This fills the inputs with information already specified in the (app) URL -->
        var item = {};
        <xsl:for-each select="columns/column[@is_primary_key = 1]">
            $("[name=new_<xsl:value-of select="@column_name" />]").focus();
        </xsl:for-each>
        <xsl:for-each select="columns/column">
        if(urlParams.get('<xsl:value-of select="@column_name" />') <xsl:text disable-output-escaping="yes">&amp;&amp;</xsl:text> urlParams.get('<xsl:value-of select="@column_name" />') != '')
            item['<xsl:value-of select="@column_name" />'] = urlParams.get('<xsl:value-of select="@column_name" />');
        </xsl:for-each>
        <xsl:for-each select="columns/column">
            <xsl:variable name="column_name" select="@column_name"/>
            <xsl:value-of select="@column_name" />_field_to_input_value(item, $('.entryNew').find('[name=new_<xsl:value-of select="@column_name" />]'));
            
            <!-- This adds whispering for the relevant inputs -->
            <xsl:if test="@referenced_table_name != ''" >
            $("[name=new_<xsl:value-of select="@column_name" />]").keyup(function(e) {
                $("[name=new_<xsl:value-of select="@column_name" />]").next('ul').empty();
                if(e.keyCode == 40 || $("[name=new_<xsl:value-of select="@column_name" />]").val().length <xsl:text disable-output-escaping="yes">&gt;</xsl:text> 0) {
                    var searchstring = (e.keyCode == 40 ? '' : $("[name=new_<xsl:value-of select="@column_name" />]").val());
                
                    meta_api_get('/api/data/master/<xsl:value-of select="@referenced_table_name" />?FilterBy[0][col]=name<xsl:text disable-output-escaping="yes">&amp;</xsl:text>FilterBy[0][regex]=%' + searchstring + '%', function(item) {
                            $("[name=new_<xsl:value-of select="@column_name" />]").next('ul').show();
                            $("[name=new_<xsl:value-of select="@column_name" />]").next('ul').append('<xsl:text disable-output-escaping="yes">&lt;</xsl:text>li \
                            onclick="$(\'[name=new_<xsl:value-of select="@column_name" />]\').val(\'' + item.<xsl:value-of select="@referenced_column_name" /> + '\'); $(\'[name=new_<xsl:value-of select="@column_name" />]\').next(\'ul\').hide();" \
                            <xsl:text disable-output-escaping="yes">&gt;</xsl:text>' + item.<xsl:value-of select="@referenced_column_name" /> + '<xsl:text disable-output-escaping="yes">&lt;/li&gt;</xsl:text>');
                        },
                        function() {},
                        errorHandler
                    );
                }
            });
            
            $("[name=new_<xsl:value-of select="@column_name" />]").next('ul').blur(function() {
                $("[name=new_<xsl:value-of select="@column_name" />]").next('ul').hide();
            });
            
            $("[name=new_<xsl:value-of select="@column_name" />]").focus(function() {
                $("[name=new_<xsl:value-of select="@column_name" />]").keyup();
            });
            </xsl:if>
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

function handleKeyPress(e) {
    // plus
    if(e.keyCode == 43) {
        $(document.getElementById("new_<xsl:value-of select="@table_name" />")).click();
    }
    // enter
    else if(e.keyCode == 13) {
        const urlParams = new URLSearchParams(window.location.search);
        if(urlParams.get('new') != null) {
            saveNew();
        }
    }
}

function loadCall() {
    handleNew();
    
    var i = 1;
    var query = getApiQueryString();
    meta_api_get('/api/data/master/<xsl:value-of select="@table_name" />' + query, function(item) {
        var newElement = $(document.getElementById("flex").appendChild(document.getElementById("entry-dummy").cloneNode(true)));
        newElement.attr("id", "entry" + i);
        
        $(newElement).find('.entryDeleter')[0].onclick = function() {
            meta_api_delete(getLink<xsl:value-of select="$table_name" />(item), function() { location.reload(); });
        }
        
        $(newElement).find('.saveButton').attr('i', i);
        
        <!-- Read & Write -->
        <xsl:for-each select="columns/column" >
        $(newElement).find('.entry<xsl:if test="@is_primary_key=1">Identifier</xsl:if>Field<xsl:value-of select="@column_name" />')[0].innerHTML = '<xsl:value-of select="@column_name" />: ' + <xsl:value-of select="@column_name" />_field_to_html_conversion(item);
        <xsl:value-of select="@column_name" />_field_to_input_value(item, $(newElement).find('[name=dummy_<xsl:value-of select="@column_name" />]'));
        $(newElement).find('[name=dummy_<xsl:value-of select="@column_name" />]').attr('name', i + '<xsl:value-of select="@column_name" />');
        $(newElement).find('[for=dummy_<xsl:value-of select="@column_name" />]').attr('for', i + '<xsl:value-of select="@column_name" />');
        <!-- Whispering -->
        <xsl:variable name="column_name" select="@column_name"/>
        <xsl:if test="@referenced_table_name != ''" >
        $("[name=" + i + "<xsl:value-of select="@column_name" />]").attr('i', i);
        $("[name=" + i + "<xsl:value-of select="@column_name" />]").keyup(function() {
            var i = $(this).attr('i');
            $(this).next('ul').empty();
            if($(this).val().length <xsl:text disable-output-escaping="yes">&gt;</xsl:text> 0) {
                meta_api_get('/api/data/master/<xsl:value-of select="@referenced_table_name" />?FilterBy[0][col]=name<xsl:text disable-output-escaping="yes">&amp;</xsl:text>FilterBy[0][regex]=%' + $("[name=" + i + "<xsl:value-of select="@column_name" />]").val() + '%', function(item) {
                        $("[name=" + i + "<xsl:value-of select="@column_name" />]").next('ul').show();
                        $("[name=" + i + "<xsl:value-of select="@column_name" />]").next('ul').append('<xsl:text disable-output-escaping="yes">&lt;</xsl:text>li i = ' + i + '\
                        onclick="$(\'[name=\' + $(this).attr(\'i\') + \'<xsl:value-of select="@column_name" />]\').val(\'' + item.<xsl:value-of select="@referenced_column_name" /> + '\'); $(\'[name=\' + $(this).attr(\'i\') + \'<xsl:value-of select="@column_name" />]\').next(\'ul\').hide();" \
                        <xsl:text disable-output-escaping="yes">&gt;</xsl:text>' + item.<xsl:value-of select="@referenced_column_name" /> + '<xsl:text disable-output-escaping="yes">&lt;/li&gt;</xsl:text>');
                    },
                    function() {},
                    errorHandler
                );
            }
        });
        
        $("[name=" + i + "<xsl:value-of select="@column_name" />]").next('ul').blur(function() {
            $(this).next('ul').hide();
        });
        
        $("[name=" + i + "<xsl:value-of select="@column_name" />]").focus(function() {
            $(this).keyup();
        });
        </xsl:if>
        </xsl:for-each>
        
        <!-- For each reference, where this table is src or dest take the other table and: -->
        <xsl:for-each select="//table//columns/column[@referenced_table_name=$table_name]" >
            <xsl:variable name="referencing_table_name" select="../../@table_name" />
            <xsl:variable name="referencing_column_name" select="@column_name" />
        <!-- 1) create '+' handler -->
        $(newElement).find('#addEntryLink<xsl:value-of select="$referencing_column_name" />').click(function() {
            var linkedItem = {};
            linkedItem.<xsl:value-of select="$referencing_column_name" /> = item.<xsl:value-of select="@referenced_column_name" />;
            window.location = getNewRefLink<xsl:value-of select="$referencing_table_name" />AppUrl(linkedItem);
        });
        <!-- 2) fire a GET for populating the list -->
        var i_<xsl:value-of select="$referencing_column_name" /> = 1;
        meta_api_get(getLinks<xsl:value-of select="$referencing_table_name" />ApiUrl(item), function(linkedItem) {
            var newChildElement = $($(newElement).find('.entryLinks<xsl:value-of select="$referencing_column_name" />')[0].appendChild(document.getElementById("entryLinkDiv<xsl:value-of select="$referencing_column_name" />-dummy").cloneNode(true)));
            newChildElement.attr("id", newElement.attr("id") + "Link<xsl:value-of select="$referencing_column_name" />" + i_<xsl:value-of select="$referencing_column_name" />++);
            <xsl:for-each select="//tables/table[@table_name=$referencing_table_name]/columns/column[@is_primary_key=1 and @column_name != $referencing_column_name]">
                $(newChildElement).find('.entryLinkIdentifierField<xsl:value-of select="$referencing_table_name" /><xsl:value-of select="@column_name" />')[0].innerHTML = '<xsl:value-of select="@column_name" />: ' + linkedItem.<xsl:value-of select="@column_name" />;
            </xsl:for-each>
            $(newChildElement).find('.entryLinkA')[0].href = getPrimaryRefLink<xsl:value-of select="$referencing_table_name" />AppUrl(linkedItem);
            $(newChildElement).find('.entryLinkDeleter')[0].onclick = function() {
                meta_api_delete(getRefLink<xsl:value-of select="$referencing_table_name" />ApiUrl(linkedItem), function() {
                    location.reload();
                }, errorHandler);
            }
        }, function() {
            $('#entryLinkDiv<xsl:value-of select="$referencing_column_name" />-dummy').remove();
        }, function(err) {
            $('#errorDiv').innerHTML = err;
            $('#errorDiv').show();
        });
        </xsl:for-each>
        i++;
    }, function() {
        $('#entry-dummy').remove();
    }, errorHandler);
}
</xsl:result-document>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>