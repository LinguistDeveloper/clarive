Cla.SwarmZoom = Ext.extend( Ext.Panel, {
    
    initComponent : function(){
        var self = this;

        Cla.SwarmZoom.superclass.initComponent.call(this);
        
        self.on('afterrender', function(){
            self.init();
        });
    },

    init : function(){

        var self = this;

        $.injectCSS({
           
            ".node" : {"fill": "#000", "cursor": "crosshair"},
            ".node_selected" : {  "fill": "#ff7f0e",  "stroke": "#ff7f0e"},
            ".drag_line" : {  "stroke": "#999",  "stroke-width": '5'},
            ".drag_line_hidden" : {  "stroke": "#999",  "stroke-width": '0'},
            ".link" : {  "stroke": "#999",  "stroke-width": '5',  "cursor": "crosshair"},
            ".link_selected" : { "stroke": "#ff7f0e"}            
        });

        var id = self.body.id; 
        var selector = '#' + id; 

        var width = 960,
            height = 500,
            fill = d3.scale.category20();

        // mouse event vars
        self.selected_node = null,
            selected_link = null,
            mousedown_link = null,
            mousedown_node = null,
            mouseup_node = null;

        // init svg
        self.outer = d3.select("#"+ id)
          .append("svg:svg")
            .attr("width", width)
            .attr("height", height)
            .attr("pointer-events", "all");

        self.vis = self.outer
          .append('svg:g')
            .call(d3.behavior.zoom().on("zoom", function(){self.rescale()}))
            .on("dblclick.zoom", null)
            .append('svg:g')
            .on("mousemove", function(){self.mousemove()})
            .on("mousedown", function(){self.mousedown()})
            .on("mouseup", function(){self.mouseup()});

        self.vis.append('svg:rect')
            .attr('width', width)
            .attr('height', height)
            .attr('fill', 'yellow')

        // init force layout
        self.force = d3.layout.force()
            .size([width,height])
            .nodes([{}]) // initialize with a single node
            .linkDistance(50)
            .charge(-200)
            .on("tick", function(){self.tick()});


        // line displayed when dragging new nodes
        self.drag_line = self.vis.append("line")
            .attr("class", "drag_line")
            .attr("x1", 0)
            .attr("y1", 0)
            .attr("x2", 0)
            .attr("y2", 0);

        // get layout properties
        self.nodes = self.force.nodes();
           self.links = self.force.links();
            self.node = self.vis.selectAll(".node");
            self.link = self.vis.selectAll(".link");

        // add keyboard callback
        d3.select(window)
            .on("keydown", function() {self.keydown()});

        self.redraw();

    },

 mousedown : function(){    

      var self = this;

      if (!self.mousedown_node && !self.mousedown_link) {
          // allow panning if nothing is selected
          self.vis.call(d3.behavior.zoom().on("zoom"), function() {self.rescale()});

          //return;
      }
    },




mousemove : function() {

  var self = this;
  //alert(self.mousedown_node);
  if (!self.mousedown_node) return;

  // update drag line
  self.drag_line
      .attr("x1", self.mousedown_node.x)
      .attr("y1", self.mousedown_node.y)
      .attr("x2", d3.svg.mouse(this)[0])
      .attr("y2", d3.svg.mouse(this)[1]);

},

mouseup : function() {

    var self = this;
      
  if (self.mousedown_node) {
    // hide drag line
    self.drag_line
      .attr("class", "drag_line_hidden")
    if (!self.mouseup_node) {
      // add node
      var point = d3.mouse(this),
        node = {x: point[0], y: point[1]},
        n = self.nodes.push(node);
      // select new node
      self.selected_node = node;
      self.selected_link = null;
      
      // add link to mousedown node
      self.links.push({source: self.mousedown_node, target: node});
    }

    self.redraw();
  }
  // clear mouse event vars
  self.resetMouseVars();
},

resetMouseVars : function() {
    
  var self= this;

  self.mousedown_node = null;
  self.mouseup_node = null;
  self.mousedown_link = null;
},

tick : function() {

var self = this;

  self.link.attr("x1", function(d) { return d.source.x; })
      .attr("y1", function(d) { return d.source.y; })
      .attr("x2", function(d) { return d.target.x; })
      .attr("y2", function(d) { return d.target.y; });

  self.node.attr("cx", function(d) { return d.x; })
      .attr("cy", function(d) { return d.y; });
},

// rescale g
rescale : function() {

alert("entra en rescale");
  var self = this;
  
  self.vis.attr("transform","translate(" + d3.event.translate + ")" + " scale(" + d3.event.scale + ")");

},

// redraw force layout
redraw : function() {

  var self = this;

  self.link = self.link.data(self.links);

  self.link.enter().insert("line", ".node")
      .attr("class", "link")
      .on("mousedown", 
        function(d) { 
          self.mousedown_link = d; 
          if (self.mousedown_link == self.selected_link) self.selected_link = null;
          else self.selected_link = self.mousedown_link; 
          self.selected_node = null; 
          self.redraw(); 
        })

  self.link.exit().remove();

  self.link
    .classed("link_selected", function(d) { return d === self.selected_link; });

  self.node = self.node.data(self.nodes);

  self.node.enter().insert("circle")
      .attr("class", "node")
      .attr("r", 5)
      .on("mousedown", 
        function(d) { 
          // disable zoom
          

          self.vis.call(d3.behavior.zoom().on("zoom"), null);

          self.mousedown_node = d;
          alert("esto es d" +d);

          if (self.mousedown_node == self.selected_node) self.selected_node = null;
          else self.selected_node = self.mousedown_node; 
          self.selected_link = null; 

          // reposition drag line
          self.drag_line
              .attr("class", "link")
              .attr("x1", self.mousedown_node.x)
              .attr("y1", self.mousedown_node.y)
              .attr("x2", self.mousedown_node.x)
              .attr("y2", self.mousedownself._node.y);

          self.redraw(); 
        })
      .on("mousedrag",
        function(d) {
          self.redraw();
        })
      .on("mouseup", 
        function(d) { 
          if (self.mousedown_node) {
            self.mouseup_node = d; 
            if (self.mouseup_node == self.mousedown_node) { self.resetMouseVars(); return; }

            // add link
            var link = {source: self.mousedown_node, target: self.mouseup_node};
            self.links.push(link);

            // select new link
            self.selected_link = link;
           self.selected_node = null;

            // enable zoom
            self.vis.call(d3.behavior.zoom().on("zoom"), function(){self.rescale()});
            self.redraw();
          } 
        })
    .transition()
      .duration(750)
      .ease("elastic")
      .attr("r", 6.5);

  self.node.exit().transition()
      .attr("r", 0)
    .remove();

  self.node
    .classed("node_selected", function(d) { return d === self.selected_node; });

  

  if (d3.event) {
    // prevent browser's default behavior
    d3.event.preventDefault();
  }

  self.force.start();

},

spliceLinksForNode : function(node) {
  var self = this;

  self.toSplice = self.links.filter(
    function(l) { 
      return (l.source === self.node) || (l.target === self.node); });
  self.toSplice.map(
    function(l) {
      self.links.splice(self.links.indexOf(l), 1); });
},

keydown : function() {
  var self = this;
  if (!self.selected_node && !self.selected_link) return;
  switch (d3.event.keyCode) {
    case 8: // backspace
    case 46: { // delete
      if (self.selected_node) {
        self.nodes.splice(self.nodes.indexOf(self.selected_node), 1);
        self.spliceLinksForNode(self.selected_node);
      }
      else if (self.selected_link) {
        self.links.splice(self.links.indexOf(self.selected_link), 1);
      }
      self.selected_link = null;
      self.selected_node = null;
      self.redraw();
      break;
    }
  }
}
});