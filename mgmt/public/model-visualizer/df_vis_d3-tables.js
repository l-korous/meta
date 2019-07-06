nodeWidth = 600;
nodeHeight = 400;
minZoom = .2;
maxZoom = 5.;
lines = [];
container = null;

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

async function initialize() {
    try {
        const urlParams = new URLSearchParams(window.location.search);
        const response = await fetch(window.location.origin + '/api/model-json/' + urlParams.get('model_id'));
        if(response.ok) {
            dataNodes = await response.json();

            // linky mezi tabulkami
            dataLinksString = '[{"source": "asdf", "target": "2"}, {"source": "1", "target": "asdf"}]';

            // inicializace, vytvoreni canvasu, vytvoreni zoomovaci funkce, a inicialni posun na stred
            
            // Nacteni dat - nody & linky
            data = { nodes: dataNodes, links: JSON.parse(dataLinksString) };

            // Vytvoreni canvasu a containeru pro vsechny nody
            canvas = d3.select("#canvas");
            container = canvas.append("g");
            
            // Zoom - vytvoreni zoom objektu, a prirazeni canvasu
            zoom = d3.zoom().scaleExtent([minZoom, maxZoom]).on("zoom", function () {
              container.attr("transform", d3.event.transform);
            });
            canvas.call(zoom);
            
            // posunuti na souradnice [0, 0]
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
    // Inicializace vseho
    var promise_ = initialize();
    promise_.then(function() {
        // Ted teprve vykreslim a forcelayout uz bude respektovat zadane souradnice (tam kde jsou zadane)
        redraw();
    });
});

// vertikalni velikost zjistena pomoci jQuery po pred-vykresleni
function getVerticalSize(node) {
    return $("." + "divInfo-" + node.id).outerHeight();
}

// horizontalni velikost zjistena pomoci jQuery po pred-vykresleni
function getHorizontalSize(node) {
    return $("." + "divInfo-" + node.id).outerWidth();
}
  
// Z dat v node vratim cele html ktere nacpu do svg elementu
function createTableHtml(node) {
    var tableName = '<div class="dfTableName">' + node.name + '</div>';
    var rows1 = '<div class="dfRows1">';
    node.rows1.forEach(function(rowI) {
        rows1 += '<div class="dfRow1">' + 
         (rowI.col1 ? ('<div class="dfCol1">' + rowI.col1 + '</div>'): '') +
         (rowI.col1 ? ('<div class="dfCol2">' + rowI.col2 + '</div>'): '') +
         (rowI.col1 ? ('<div class="dfCol3">' + rowI.col3 + '</div>'): '') +
         '</div>';
    });
    rows1 += '</div>';
    var rows2 = '<div class="dfRows2">';
    node.rows2.forEach(function(rowI) {
        rows2 += '<div class="dfRow2">' + 
         (rowI.col1 ? ('<div class="dfCol1">' + rowI.col1 + '</div>'): '') +
         (rowI.col1 ? ('<div class="dfCol2">' + rowI.col2 + '</div>'): '') +
         (rowI.col1 ? ('<div class="dfCol3">' + rowI.col3 + '</div>'): '') +
         '</div>';
    });
    rows2 += '</div>';
    return tableName + rows1 + rows2;
}

function redraw() {
    // Force-directed simulace v D3
    var simulation = d3.forceSimulation()
            .force("link", d3.forceLink().id(function(d) { return d.id; }))
            .force("collide",d3.forceCollide( function(d){return .75 * Math.max(getHorizontalSize(d), getVerticalSize(d)); }).iterations(3) )
            .force("charge", d3.forceManyBody())
            .force("center", d3.forceCenter(0, 0))
            .force("y", d3.forceY(0))
            .force("x", d3.forceX(0))
            .alphaDecay(.1);
            
    // Dam pryc existujici nody a linky
    container.selectAll("g.node").remove();
    container.selectAll("g.links").selectAll("line").remove();
    
    // Pridani linku do containeru v SVG
    var link = container.append("g")
        .attr("class", "links")
        .selectAll("line")
        .data(data.links)
        .enter()
        .append("line")
        .attr("stroke", "black")
    
    // A pridam vsechny znovu
    var node = container.selectAll("g.node").data(data.nodes);

    // Definice dragging objektu
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
        getPosition(d.id, d3.select(this).attr("x"), d3.select(this).attr("y"));
    });
    
    // Pro nove nody nastavim atributy - CSS tridu, [x, y], a nastavim dragging.
    var nodeEnter = node.enter().append("g")
        .attr("class", function(d) {
            return "node " + d.shape + " nodeInfo-" + d.id;
        })
        .attr("x", "0").attr("y", "0")
        .call(drag);
    
    // Pro nove nody ted div pro vnitrni html
    var divEnter = nodeEnter.append("foreignObject").attr("width", nodeWidth).attr("height", nodeHeight).append("xhtml:div");
    
    // Vnitrni html oclassuju a vyplnim
    node.merge(nodeEnter)
        .select("div")
        .attr("class", function(d) { return "info divInfo-" + d.id + " " + d.class; })
        .html(function(d) { return createTableHtml(d); });
    
    // Vysku a sirku SVG krabicky nastavim podle rozmeru vnitrniho html
    node.merge(nodeEnter).select("foreignObject").attr("width", function(d) { return getHorizontalSize(d); })
        .attr("height", function(d) { return getVerticalSize(d); });
    
    // Technikalie v force-directed layoutu, tohle je pro jednu iteraci nelinearniho resice ulohy rozmisteni
    var ticked = function() {
        link
            .attr("x1", function(d) { return (d.source.xSet ? d.source.xSet : d.source.x) + (getHorizontalSize(d.source) / 2.); })
            .attr("y1", function(d) { return (d.source.ySet ? d.source.ySet : d.source.y) + (getVerticalSize(d.source) / 2.); })
            .attr("x2", function(d) { return (d.target.xSet ? d.target.xSet : d.target.x) + (getHorizontalSize(d.target) / 2.); })
            .attr("y2", function(d) { return (d.target.ySet ? d.target.ySet : d.target.y) + (getVerticalSize(d.target) / 2.); })
            .attr("class", function(d) { return "edge start-" + d.source.id + " end-" + d.target.id; });

        nodeEnter
            .attr("x", function(d) { return d.xSet ? d.xSet : d.x; })
            .attr("y", function(d) { return d.ySet ? d.ySet : d.y; })
            .attr("transform", function(d) { return "translate(" + (d.xSet ? d.xSet : d.x) + ", " + (d.ySet ? d.ySet : d.y) + ")"; });
    }  
    
    // Predani parametru simulace
    simulation.nodes(data.nodes).on("tick", ticked);
    simulation.force("link").links(data.links);    
    
    // Tohle je tu jen proto aby na zacatku se nic nehybalo, ale rovnou se to vykreslilo optimalne rozlozeny (iterace resice nedelam s casovym odstupem, ale najednou.
    for (var i = 0, n = Math.ceil(Math.log(simulation.alphaMin()) / Math.log(1 - simulation.alphaDecay())); i < n; ++i) {
        simulation.tick();
    }
    
    var node = container.selectAll("g.node").data(data.nodes)
        .attr("dsfa", function(d) { return d.xSet; });
}

function getPosition(id,x,y) {
    console.log('getPosition: (id: ' + id + ', x: ' + x + ', y: ' + y + ')');
    
    apex.server.process(
        "GET_POSITION",
        {
            x01: 'aaa',
            x02: id,
            x03: x,
            x04: y
        },
        {
          dataType: 'text',
          success: function(pData){console.log(pData)}
        }
    );
}

function setPosition(id,x,y) {
    data.nodes.find(function(n) { return n.id == id;} ).xSet = x;
    data.nodes.find(function(n) { return n.id == id;} ).ySet = y;
    // Abych mohl tuto funkci volat i po inicialnim vykresleníi, tak se vola redraw(), aby ihned bylo jeji zavolani videt.
    redraw();
}
