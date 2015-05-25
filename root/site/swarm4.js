Cla.Swarm4 = Ext.extend( Ext.Panel, {
    initComponent : function(){
        var self = this;

        self.tbar = [
            { text:_('Start Anim'), handler:function(){ self.start_anim() } },
            { text:_('Stop Anim'), handler:function(){ self.stop_anim() } },
            '-',
            { text:_('First'), handler:function(){ self.first() } },
            '-',
            { text:_('Add'), handler:function(){ self.init() } },
            '-',
            { text:_('Del'), handler:function(){ self.del() } }
        ];

        Cla.Swarm4.superclass.initComponent.call(this);
         
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

        $.injectCSS({
            "link": {"stroke": "#666",  'stroke-width':'1.5px'},
            "#licensing": {  "fill":"green"},
            ".link.licensing": {   "stroke": "green"},
            "circle": {  "fill": "#ccc",  "stroke": "#333",  "stroke-width": '1.5px'},
            "text": {  "font": "10px sans-serif"}
        });

        self.links = [
          {source: "Microsoft", target: "Amazon", type: "licensing"},
          {source: "Microsoft", target: "HTC", type: "licensing"},
          {source: "Samsung", target: "Apple", type: "suit"},
          {source: "Motorola", target: "Apple", type: "suit"},
          {source: "Nokia", target: "Apple", type: "resolved"},
          {source: "HTC", target: "Apple", type: "suit"},
          {source: "Kodak", target: "Apple", type: "suit"},
          {source: "Microsoft", target: "Barnes & Noble", type: "suit"},
          {source: "Microsoft", target: "Foxconn", type: "suit"},
          {source: "Oracle", target: "Google", type: "suit"},
          {source: "Apple", target: "HTC", type: "suit"},
          {source: "Microsoft", target: "Inventec", type: "suit"},
          {source: "Samsung", target: "Kodak", type: "resolved"},
          {source: "LG", target: "Kodak", type: "resolved"},
          {source: "RIM", target: "Kodak", type: "suit"},
          {source: "Sony", target: "LG", type: "suit"},
          {source: "Kodak", target: "LG", type: "resolved"},
          {source: "Apple", target: "Nokia", type: "resolved"},
          {source: "Qualcomm", target: "Nokia", type: "resolved"},
          {source: "Apple", target: "Motorola", type: "suit"},
          {source: "Microsoft", target: "Motorola", type: "suit"},
          {source: "Motorola", target: "Microsoft", type: "suit"},
          {source: "Huawei", target: "ZTE", type: "suit"},
          {source: "Ericsson", target: "ZTE", type: "suit"},
          {source: "Kodak", target: "Samsung", type: "resolved"},
          {source: "Apple", target: "Samsung", type: "suit"},
          {source: "Kodak", target: "RIM", type: "suit"},
          {source: "Nokia", target: "Qualcomm", type: "suit"}
        ];

        self.nodes = {};

        // Compute the distinct nodes from the links.
        self.links.forEach(function(link) {
          link.source = self.nodes[link.source] || (self.nodes[link.source] = {name: link.source});
          link.target = self.nodes[link.target] || (self.nodes[link.target] = {name: link.target});
        });

        self.width = 960,self.height = 500;

        self.force = d3.layout.force()
            .nodes(d3.values(self.nodes))
            .links(self.links)
            .size([self.width, self.height])
            .linkDistance(60)
            .charge(-300)
            .on("tick", self.tick)
            .start();

        self.svg = d3.select("body").append("svg")
            .attr("width", self.width)
            .attr("height", self.height);

        // Per-type markers, as they don't inherit styles.
        self.svg.append("defs").selectAll("marker")
            .data(["suit", "licensing", "resolved"])
          .enter().append("marker")
            .attr("id", function(d) { return d; })
            .attr("viewBox", "0 -5 10 10")
            .attr("refX", 15)
            .attr("refY", -1.5)
            .attr("markerWidth", 6)
            .attr("markerHeight", 6)
            .attr("orient", "auto")
          .append("path")
            .attr("d", "M0,-5L10,0L0,5");

        self.path = self.svg.append("g").selectAll("path")
            .data(self.force.links())
          .enter().append("path")
            .attr("class", function(d) { return "link " + d.type; })
            .attr("marker-end", function(d) { return "url(#" + d.type + ")"; });

        self.circle = self.svg.append("g").selectAll("circle")
            .data(self.force.nodes())
          .enter().append("circle")
            .attr("r", 6)
            .call(self.force.drag);

        self.text = self.svg.append("g").selectAll("text")
            .data(self.force.nodes())
          .enter().append("text")
            .attr("x", 8)
            .attr("y", ".31em")
            .text(function(d) { return d.name; });

        // Use elliptical arc path segments to doubly-encode directionality.
        function tick() {
            var self = this;
          self.path.attr("d", linkArc);
          self.circle.attr("transform", transform);
          self.text.attr("transform", transform);
        }

        function linkArc(d) {
          var dx = d.target.x - d.source.x,
              dy = d.target.y - d.source.y,
              dr = Math.sqrt(dx * dx + dy * dy);
          return "M" + d.source.x + "," + d.source.y + "A" + dr + "," + dr + " 0 0,1 " + d.target.x + "," + d.target.y;
        }

        function transform(d) {
          return "translate(" + d.x + "," + d.y + ")";
        }


    }  
});