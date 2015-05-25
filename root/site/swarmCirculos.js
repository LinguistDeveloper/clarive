Cla.SwarmCirculos = Ext.extend( Ext.Panel, {
    initComponent : function(){
        var self = this;
        self.i = 0;

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

        Cla.SwarmCirculos.superclass.initComponent.call(this);
         
        self.on('resize', function(p,w,h){
            if( self.svg ) {
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

        self.array =  [
        { t:'1000', ev:'add', who:'pedro', node: '#43', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#43', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#45', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#45', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#46', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#47', parent:'Changeset' },
        { t:'7000', ev:'add', who:'marco', node: '#48', parent:'Changeset' },
        { t:'8000', ev:'del', who:'marco', node: '#48', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#49', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#49', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#50', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#51', parent:'Changeset' },
        { t:'13000', ev:'add', who:'ana', node: '#52', parent:'Changeset' }
        ];

        $.injectCSS({
            ".link": { "stroke": "#000", 'stroke-width': '2.5px' },
            ".node": { "stroke": "#fff", fill:"#000", 'stroke-width': '1.5px' },
            ".node.a": { "fill": "red" },
            ".node.b": { "fill": "green" },
            ".node.c": { "fill": "#1f77b4" }
        });

        var id = self.body.id; 
        var selector = '#' + id; 
        //d3.select(selector).selectAll("svg").remove();

        self.force = d3.layout.force()
            //.nodes(self.nodes2)
            .nodes(self.nodes)
            .links(self.links)
            .charge(-10)
            .linkDistance(20)
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
        if(self.array[self.i].ev == 'add') {
            self.add();
            self.i++;
        }else {
            self.del();
            self.i++;
        }
        setTimeout(function(){ self.anim() },1000);
    },
    first : function(){
        var self = this;
        var i 
        var a = { id: "d87654" , who: "diego"}
        self.nodes.push(a);
        self.start();
    },
    add : function(){
        var self = this;
        var a = self.nodes[0];
        var d = {id: "d"+Math.random()};
        self.nodes.push(d);
        self.links.push({source: d, target: a});
        self.start();

    },
    del : function(){
        var self = this;
        self.nodes.splice(self.nodes.length-1); // borra el ultimo nodo creado
        self.links.pop();
        self.start();
    },
    start : function(){
        var self = this;

        self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link.enter().insert("line", ".node").attr("class", "link");
        self.link.exit().remove();

        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 6);
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
