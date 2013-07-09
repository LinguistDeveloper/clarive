Baseliner.D3Graph = Ext.extend( Ext.Panel, {
    mid: 6516,
    mode: 'tree', 
    depth: 3, 
    unique: true,
    linkDistance: 60,
    charge: -300,
    initComponent : function(){
        var self = this;
        require(['d3'], function(){
            Baseliner.D3Graph.superclass.initComponent.call(self);
        });
        
        self.on('resize', function(p,w,h){
            if( this.svg ) {
                //this.svg.trigger('resizeEnd');
                //this.svg.attr('width', w).attr('height', h);
                //self.draw();
            }
        });
        self.on('afterrender', function(){
            Baseliner.ajaxEval('/ci/json_tree', { mid:self.mid, depth:self.depth, mode:self.mode, unique:self.unique }, function(res){
                self.links = [];
                
                var link = function(source){
                    Ext.each( source.children, function(chi){
                        self.links.push({ source: source.name, target: chi.name, type:"child" });
                        link( chi );
                    });
                }
                link( res.data );

                self.nodes = {};

                // Compute the distinct nodes from the links.
                self.links.forEach(function(link) {
                  link.source = self.nodes[link.source] || (self.nodes[link.source] = {name: link.source});
                  link.target = self.nodes[link.target] || (self.nodes[link.target] = {name: link.target});
                });
                
                self.draw();

            });
        });
    },
    draw: function(){
        var self = this;

        var id = self.body.id; 
        var height = self.body.getHeight();
        var width = self.body.getWidth();
        
        self.force = d3.layout.force()
            .nodes(d3.values(self.nodes))
            .links(self.links)
            .size([width, height])
            .linkDistance( self.linkDistance )
            .charge( self.charge )
            .on("tick", function() { self.tick() })
            .start();

        self.svg = d3.select("#"+ id ).append("svg:svg").attr("width", '100%').attr("height", '100%')
            //.attr("viewBox", "0 0 "+height+" "+width )
            .attr("preserveAspectRatio", "xMinYMin meet");

        // Per-type markers, as they don't inherit styles.
        self.svg.append("svg:defs").selectAll("marker")
            .data(["suit", "child", "parent"])
            .enter().append("svg:marker")
            .attr("id", String)
            .attr("viewBox", "0 -5 10 10")
            .attr("refX", 15)
            .attr("refY", -1.5)
            .attr("markerWidth", 6)
            .attr("markerHeight", 6)
            .attr("orient", "auto")
            .append("svg:path")
            .attr("d", "M0,-5L10,0L0,5");

        self.path = self.svg.append("svg:g").selectAll("path")
            .data(self.force.links())
          .enter().append("svg:path")
            .attr("class", function(d) { return "link " + d.type; })
            .attr("marker-end", function(d) { return "url(#" + d.type + ")"; });

        self.circle = self.svg.append("svg:g").selectAll("circle")
            .data(self.force.nodes())
          .enter().append("svg:circle")
            .attr("r", 6)
            .call(self.force.drag);

        self.text = self.svg.append("svg:g").selectAll("g")
            .data(self.force.nodes())
          .enter().append("svg:g");

        // A copy of the text with a thick white stroke for legibility.
        self.text.append("svg:text")
            .attr("x", 8)
            .attr("y", ".31em")
            .attr("class", "shadow")
            .text(function(d) { return d.name; });

        self.text.append("svg:text")
            .attr("x", 8)
            .attr("y", ".31em")
            .text(function(d) { return d.name; });

    },
    tick : function(){
        var self = this;
        // Use elliptical arc path segments to doubly-encode directionality.
        self.path.attr("d", function(d) {
            var dx = d.target.x - d.source.x,
                dy = d.target.y - d.source.y,
                dr = Math.sqrt(dx * dx + dy * dy);
            return "M" + d.source.x + "," + d.source.y + "A" + dr + "," + dr + " 0 0,1 " + d.target.x + "," + d.target.y;
        });

        self.circle.attr("transform", function(d) {
            return "translate(" + d.x + "," + d.y + ")";
        });

        self.text.attr("transform", function(d) {
            return "translate(" + d.x + "," + d.y + ")";
        });
    }
});

var w = 960,
    h = 500;
var gg = new Baseliner.D3Graph();
var win = new Baseliner.Window({ bodyStyle: { 'background-color':'#fff' }, width: w, height: h, items: gg, layout:'fit' });
win.show();
                    
