Cla.Swarm3 = Ext.extend( Ext.Panel, {
    initComponent : function(){
        var self = this;

        self.tbar = [
            { text:_('Start Anim'), handler:function(){ self.start_anim() } },
            { text:_('Stop Anim'), handler:function(){ self.stop_anim() } },
            '-',
            { text:_('First'), handler:function(){ self.first() } },
            '-',
            { text:_('Add'), handler:function(){ self.add() } },
            '-',
            { text:_('Del'), handler:function(){ self.del() } }
        ];

        Cla.Swarm3.superclass.initComponent.call(this);
         
        self.on('resize', function(p,w,h){
            if( self.svg ) {
                //self.svg.trigger('resizeEnd');
                //self.svg.attr('width', w).attr('height', h);
                //self.redraw();
            }
        });
        self.on('afterrender', function(){
            self.init();
        });
    },
    init : function(){
        var self = this;

        var color = d3.scale.category10();

        self.nodes = [];
        self.links = [];

        $.injectCSS({
            ".link": { "stroke": "#000", 'stroke-width': '2.5px' },
            ".node": { "stroke": "#fff", fill:"#000", 'stroke-width': '1.5px' },
            ".node.a": { "fill": "#1f77b4" },
            ".node.b": { "fill": "#1f77b4" },
            ".node.c": { "fill": "#1f77b4" }
        });

        var id = self.body.id; 
        var selector = '#' + id; 
        //d3.select(selector).selectAll("svg").remove();

        self.force = d3.layout.force()
            .nodes(self.nodes)
            .links(self.links)
            .charge(-400)
            .linkDistance(120)
            .size([self.width, self.height])
            .on("tick", function(){ self.tick() });

        self.svg = d3.select("#"+ id ).append("svg:svg").attr("width", '100%').attr("height", '100%').attr("preserveAspectRatio", "xMinYMin meet");
        self.node = self.svg.selectAll(".node");
        self.link = self.svg.selectAll(".link");

    },
    start_anim : function(){
        var self = this;
        self.anim_running = true;
        setTimeout(function(){ self.anim() },1000);
    },
    stop_anim : function(){
        var self = this;
        self.anim_running = false;
    },
    anim : function(){
        var self = this;
        if( !self.anim_running ) return;
        // if( tengo eventos para este segundo? ) {
        //     self.add( ...... );
        // }
        self.add();
        setTimeout(function(){ self.anim() },1000);
    },
    first : function(){
        var self = this;
        var a = {id: "a"}, b = {id: "b"}, c = {id: "c"};
        self.nodes.push(a, b, c);
        self.links.push({source: a, target: b}, {source: a, target: c}, {source: b, target: c});
        self.start();
    },
    add : function(){
        var self = this;
        var a = self.nodes[0];
        var d = {id: "d"+Math.random() };
        var c = self.nodes[1];
        self.nodes.push(d);
        self.links.push({source: a, target: d}, {source: d, target: c});
        self.start();
    },
    del : function(){
        var self = this;
        self.nodes.splice(1, 1); // remove b
        self.links.shift(); // remove a-b
        self.links.pop(); // remove b-c
        self.start();
    },
    start : function(){
        var self = this;

        self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link.enter().insert("line", ".node").attr("class", "link");
        self.link.exit().remove();

        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 8);
        self.node.exit().remove();

        self.force.start();
    },
    tick : function(){
        var self = this;
        self.node.attr("cx", function(d) { return d.x; })
            .attr("cy", function(d) { return d.y; })

        self.link.attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; })
          .attr("x2", function(d) { return d.target.x; })
          .attr("y2", function(d) { return d.target.y; });
    }
});


// 1. Add three nodes and three links.
/*
setTimeout(function() {
  var a = {id: "a"}, b = {id: "b"}, c = {id: "c"};
  nodes.push(a, b, c);
  links.push({source: a, target: b}, {source: a, target: c}, {source: b, target: c});
  start();
}, 0);

// 2. Remove node B and associated links.
setTimeout(function() {
  nodes.splice(1, 1); // remove b
  links.shift(); // remove a-b
  links.pop(); // remove b-c
  start();
}, 3000);

// Add node B back.
setTimeout(function() {
  var a = nodes[0], b = {id: "b"}, c = nodes[1];
  nodes.push(b);
  links.push({source: a, target: b}, {source: b, target: c});
  start();
}, 6000);


*/
