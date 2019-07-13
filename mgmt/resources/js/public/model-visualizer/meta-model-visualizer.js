nodeWidth = 100;
nodeHeight = 400;
minZoom = .2;
maxZoom = 5.;
lines = [];
container = null;
nodeSizes = [];

async function errorHandler(error) {
    var text = '';
    if(Object.prototype.toString.call(error) == '[object Response]') {
        var responseJson = await error.json();
        text = responseJson.originalError ? responseJson.originalError.info.message : error.statusText;
    }
    else
        text = await error.toString();
        
    console.log("ERROR");
    console.dir(text);
}

function parseXml(xml) {
   var dom = null;
   if (window.DOMParser) {
      try { 
         dom = (new DOMParser()).parseFromString(xml, "text/xml"); 
      } 
      catch (e) { dom = null; }
   }
   else if (window.ActiveXObject) {
      try {
         dom = new ActiveXObject('Microsoft.XMLDOM');
         dom.async = false;
         if (!dom.loadXML(xml)) // parse error ..

            window.alert(dom.parseError.reason + dom.parseError.srcText);
      } 
      catch (e) { dom = null; }
   }
   else
      alert("cannot parse xml string!");
   return dom;
}

function xmlToJson(xml) {
	// Create the return object
	var obj = {};

	if (xml.nodeType == 1) { // element
		// do attributes
        for (var j = 0; j < xml.attributes.length; j++) {
            var attribute = xml.attributes.item(j);
            obj[attribute.nodeName] = attribute.nodeValue;
        }
	} else if (xml.nodeType == 3) { // text
		obj = xml.nodeValue;
	}

	// do children
	if (xml.hasChildNodes()) {
		for(var i = 0; i < xml.childNodes.length; i++) {
			var item = xml.childNodes.item(i);
			var nodeName = item.nodeName;
			if (typeof(obj[nodeName]) == "undefined") {
				obj[nodeName] = xmlToJson(item);
			} else {
				if (typeof(obj[nodeName].push) == "undefined") {
					var old = obj[nodeName];
					obj[nodeName] = [];
					obj[nodeName].push(old);
				}
				obj[nodeName].push(xmlToJson(item));
			}
		}
	}
	return obj;
};

function getNodes(xml_data) {
    var nodes = [];
    var id_ = 0;
    xml_data.root.tables.table.forEach(function(table) {
        var node = {
            id: id_,
            class: "baseTable",
            shape: "table",
            name: table.table_name,
            node: table,
            rows1: [],
            rows2: [],
            rows3: []
        };
        table.columns.column.forEach(function(column) {
            if(column.is_primary_key == "1")
                node.rows1.push({col1: column.column_name, col2: column.datatype, col3: ""});
            else if(column.referenced_table_name != "")
                node.rows2.push({col1: column.column_name, col2: column.datatype, col3: "'" + column.referenced_table_name + "'.'" + column.referenced_column_name + "'" });
            else
                node.rows3.push({col1: column.column_name, col2: column.datatype, col3: (column.required == "1" ? (column.unique == "1" ? "required+unique" : "required") : (column.unique == "1" ? "unique" : "")) });
        });
        
        id_ = id_ + 1;
        nodes.push(node);
    });
    return nodes;
}

function getLinks(xml_data, nodes) {
    var links = [];
    nodes.forEach(function(node) {
        xml_data.root.tables.table.find(function(table) { return table.table_name == node.name; }).columns.column.forEach(function(column) {
            if (column.referenced_table_name != "") {
                var link = {
                    source: node.id,
                    sourceNode: node,
                    target: nodes.find(function(node) { return node.name == column.referenced_table_name; }).id,
                    targetNode: nodes.find(function(node) { return node.name == column.referenced_table_name; })
                };
                
                links.push(link);
            }
        });
    });
    return links;
}

async function initialize() {
    try {
        const urlParams = new URLSearchParams(window.location.search);
        const response = await fetch(window.location.origin + '/api/model-xml/' + urlParams.get('model_id'));
        if(response.ok) {
            var response_ = await response.text();
            var dom_ = parseXml(response_);
            xml_data = xmlToJson(dom_);
            var nodes_ = getNodes(xml_data);
            var links_ = getLinks(xml_data, nodes_);
            
            // Main data container
            data = { nodes: nodes_, links: links_ };

            // Canvas for all nodes.
            canvas = d3.select("#canvas");
            container = canvas.append("g");
            
            zoom = d3.zoom().scaleExtent([minZoom, maxZoom]).on("zoom", function () {
              container.attr("transform", d3.event.transform);
            });
            canvas.call(zoom);
            
            // Move to [0, 0]
            box = canvas.node().getBoundingClientRect();
            zoom.translateBy(canvas, box.width/ 2, box.height / 2);
        }
        else
            throw response;
    }
    catch(e) {
        errorHandler(e);
    }
}
    

$(document).ready( function () {
    var promise_ = initialize();
    promise_.then(function() {
        redraw();
    });
});

// Vertical size after before-draw
function getVerticalSize(node) {
    return $("." + "divInfo-" + node.id).outerHeight();
}

// Horizontal size after before-draw
function getHorizontalSize(node) {
    var n = nodeSizes.find(function(n) { return n.id == node.id; });
    if(n)
        return n.size;
    var width = $("." + "divInfo-" + node.id).outerWidth();
    width = getHorizontalSizeRecursive($("." + "divInfo-" + node.id), width);
    nodeSizes.push({id: node.id, size: width + 1});
    return width;
}

function getHorizontalSizeRecursive($element, width){
    if($element[0].clientWidth > width)
        width = $element[0].clientWidth;
    if($element[0].nodeName != 'TABLE') {
        $element.children().each(function () {
            var $currentElement = $(this);
            width = getHorizontalSizeRecursive($(this), width);
        });
    }
    return width;
}
  
function createTableHtml(node) {
    var table = '<div class="dfTableName">' + node.name + '</div> <div class="dfRows"><table>';
    if(node.rows1.length > 0) {
        table += '<tr class="dfRowHead dfRowHead1"><td>PK name</td><td colspan="2">PK datatype</td></tr>';
        node.rows1.forEach(function(rowI) {
            table += '<tr class="dfRow dfRow1">' + 
             (rowI.col1 ? ('<td class="dfCol1">' + rowI.col1 + '</td>'): '') +
             (rowI.col1 ? ('<td class="dfCol2" colspan="2">' + rowI.col2 + '</td>'): '') +
             '</tr>';
        });
    }
    
    if(node.rows2.length > 0) {
        table += '<tr class="dfRowHead dfRowHead2"><td>FK name</td><td>FK datatype</td><td>References</td></tr>';
        node.rows2.forEach(function(rowI) {
            table += '<tr class="dfRow dfRow2">' + 
             (rowI.col1 ? ('<td class="dfCol1">' + rowI.col1 + '</td>'): '') +
             (rowI.col1 ? ('<td class="dfCol2">' + rowI.col2 + '</td>'): '') +
             (rowI.col1 ? ('<td class="dfCol3">' + rowI.col3 + '</td>'): '') +
             '</tr>';
        });
    }
    
    if(node.rows3.length > 0) {
        table += '<tr class="dfRowHead dfRowHead3"><td>Attribute</td><td>Datatype</td><td>Properties</td></tr>';
        node.rows3.forEach(function(rowI) {
            table += '<tr class="dfRow dfRow3">' + 
             (rowI.col1 ? ('<td class="dfCol1">' + rowI.col1 + '</td>'): '') +
             (rowI.col1 ? ('<td class="dfCol2">' + rowI.col2 + '</td>'): '') +
             (rowI.col1 ? ('<td class="dfCol3">' + rowI.col3 + '</td>'): '') +
             '</tr>';
        });
    }
    table += '</table>';
    return table;
}

// Create Event Handlers for mouse
function handleMouseOver(d, i) {  // Add interactivity
    // Highlight node
    var node = d3.select(this);
    node.attr("class", function(d) { return "highLightedNode " + node.attr("class"); });
    
    // Referenced nodes
    if(node.data()[0].node.columns.column) {
        node.data()[0].node.columns.column.forEach(function(column) {
            if(column.referenced_table_name != "") {
                var other_node = d3.select( 'g.node[node_name=' + column.referenced_table_name + ']');
                other_node.attr("class", function(d) { return "referencedNode " + other_node.attr("class"); });
            }
        });
    }
    
    // Referencing nodes
    data.nodes.forEach(function(node_) {
        node_.node.columns.column.forEach(function(column) {
            if(column.referenced_table_name == node.attr("node_name")) {
                var other_node = d3.select( 'g.node[node_name=' + node_.name + ']');
                other_node.attr("class", function(d) { return "referencingNode " + other_node.attr("class"); });
            }
        });
    });
}

function handleMouseOut(d, i) {
    // Highlight node
    var node = d3.select(this);
    node.attr("class", function(d) { return node.attr("class").replace("highLightedNode ", ''); });
    
    // Referenced nodes
    if(node.data()[0].node.columns.column) {
        node.data()[0].node.columns.column.forEach(function(column) {
            if(column.referenced_table_name != "") {
                var other_node = d3.select( 'g.node[node_name=' + column.referenced_table_name + ']');
                other_node.attr("class", function(d) { return other_node.attr("class").replace("referencedNode ", ''); });
            }
        });
    }
    
    // Referencing nodes
    data.nodes.forEach(function(node_) {
        node_.node.columns.column.forEach(function(column) {
            if(column.referenced_table_name == node.attr("node_name")) {
                var other_node = d3.select( 'g.node[node_name=' + node_.name + ']');
                other_node.attr("class", function(d) { return other_node.attr("class").replace("referencingNode ", ''); });
            }
        });
    });
}


function redraw() {
    container.selectAll("g.node").remove();
    container.selectAll("g.links").selectAll("line").remove();
    
    var link = container.append("g")
        .attr("class", "links")
        .selectAll("line")
        .data(data.links)
        .enter()
        .append("line")
        .attr("stroke", "black")
    
    var node = container.selectAll("g.node").data(data.nodes);

    var drag = d3.drag()
    .on("drag", function(d,i) {
        d3.select(this).attr("x", Number(d3.select(this).attr("x")) + d3.event.dx);
        d3.select(this).attr("y", Number(d3.select(this).attr("y")) + d3.event.dy);
        d3.select(this).attr("transform", function(d,i){ return "translate(" + [ d3.select(this).attr("x"), d3.select(this).attr("y") ] + ")"; });
        if(container.selectAll("line.end-" + d.id)._groups[0].length > 0)
            container.selectAll("line.end-" + d.id).attr("x2", Number(container.selectAll("line.end-" + d.id).attr("x2")) + d3.event.dx).attr("y2", Number(container.selectAll("line.end-" + d.id).attr("y2")) + d3.event.dy);
        if(container.selectAll("line.start-" + d.id)._groups[0].length > 0)
            container.selectAll("line.start-" + d.id).attr("x1", Number(container.selectAll("line.start-" + d.id).attr("x1")) + d3.event.dx).attr("y1", Number(container.selectAll("line.start-" + d.id).attr("y1")) + d3.event.dy);
    })
    .on("end", function(d,i) {
        // nothing here
    });
    
    var nodeEnter = node.enter().append("g")
        .attr("class", function(d) {
            return "node " + d.shape + " nodeInfo-" + d.id;
        })
        .attr("node_name", function(d) {
            return d.name;
        })
        .attr("x", "0").attr("y", "0")
        .call(drag)
        .on("mouseover", handleMouseOver)
        .on("mouseout", handleMouseOut);
    
    var divEnter = nodeEnter.append("foreignObject").attr("width", nodeWidth).attr("height", nodeHeight).append("xhtml:div");
    
    node.merge(nodeEnter)
        .select("div")
        .attr("class", function(d) { return "info divInfo-" + d.id + " " + d.class; })
        .html(function(d) { return createTableHtml(d); });
    
    node.merge(nodeEnter).select("foreignObject")
        .attr("width", function(d) { return getHorizontalSize(d); })
        .attr("height", function(d) { return getVerticalSize(d); });
    
    var ticked = function() {
        link
            .attr("x1", function(d) { return d.sourceNode.x + (getHorizontalSize(d.sourceNode) / 2.); })
            .attr("y1", function(d) { return d.sourceNode.y + (getVerticalSize(d.sourceNode) / 2.); })
            .attr("x2", function(d) { return d.targetNode.x + (getHorizontalSize(d.targetNode) / 2.); })
            .attr("y2", function(d) { return d.targetNode.y + (getVerticalSize(d.targetNode) / 2.); })
            .attr("class", function(d) { return "edge start-" + d.sourceNode.id + " end-" + d.targetNode.id; });

        nodeEnter
            .attr("x", function(d) { return d.x; })
            .attr("y", function(d) { return d.y; })
            .attr("transform", function(d) { return "translate(" + d.x + ", " + d.y + ")"; });
    }  
    
    // Force-directed simulation in D3
    var simulation = d3.forceSimulation()
            .nodes(data.nodes).on("tick", ticked)
            .force("charge", d3.forceManyBody().strength(-1000))
            .force('link', d3.forceLink().links(data.links).distance(0).strength(1))
            .force("center", d3.forceCenter(0, 0))
            .force("collide",d3.forceCollide().radius( function(d){return Math.max(getHorizontalSize(d), getVerticalSize(d)); }).strength(0.5) )
            .alphaDecay(0.05);
    
    // Pre-drawing simulation run
    for (var i = 0, n = Math.ceil(Math.log(simulation.alphaMin()) / Math.log(1 - simulation.alphaDecay())); i < n; ++i) {
        simulation.tick();
    }
}
