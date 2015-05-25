Cla.SwarmRayos = Ext.extend( Ext.Panel, {
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

        Cla.SwarmRayos.superclass.initComponent.call(this);
         
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
        self.links2 = [];
        self.nodes2 = [];
        self.nodes3 = [];

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
            ".link": { "stroke": "green", 'stroke-width': '2.5px'},
            //".node": { "stroke": "#fff", fill:"#000", 'stroke-width': '1.5px' },
            ".node.a": { "fill": "red" },
            ".node.b": { "fill": "green" },
            ".node3": { "fill": "#1f77b4" }
        });

        var id = self.body.id; 
        var selector = '#' + id; 
        //d3.select(selector).selectAll("svg").remove();



              

        self.vis = d3.select("#"+ id ).append("svg:svg").attr("width", '100%').attr("height", '100%').attr("preserveAspectRatio", "xMinYMin meet");
        self.svg = self.vis.append("svg:g").call(d3.behavior.zoom().on("zoom", function(){self.rescale()})).on("dblclick.zoom", null).append('svg:g');
        
self.svg.append('svg:rect')
            .attr('width', self.width)
            .attr('height', self.height)
            .attr('fill', 'white')
        self.force = d3.layout.force()
            //.nodes(self.nodes2)
            .nodes(self.nodes)
            .links(self.links)
            //.links(self.links2)
            .charge(-50)
            .linkDistance(20)
            .size([self.width, self.height])
            .on("tick", function(){ self.tick() });


        self.node = self.svg.selectAll(".node");
        self.link = self.svg.selectAll(".link");
        self.link2 = self.svg.selectAll(".link2");
        self.node2 = self.svg.selectAll(".path");
        self.node3 = self.svg.selectAll(".path");

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
            self.useradd();
            self.add();
            self.i++;
        }else {
            self.userdel();
            self.del();
            self.i++;
        }
        setTimeout(function(){ self.anim() },1000);
    },
    first : function(){
        var self = this;
        var i;

        var a = {id: "a"}, b = {id: "b"}, c = {id: "c"};
        self.nodes.push(a,b,c);
        self.links.push({source: a, target: b}, {source: a, target: c}, {source: b, target: c}); 
        //for (i=0; i<array.length; i++){
        //var a = { id: "d87654" , who: "diego"}
        //self.nodes.push(a);
        //self.nodes2.push(a);
        //self.userstart();
        self.start();
        
        //var a ={id: "a"};
        //self.nodes.push(a);
        //var a = {id: "a"}, b = {id: "b"}, c = {id: "c"};
        //self.nodes.push(a,b,c);
        //self.links.push({source: a, target: b}, {source: a, target: c}, {source: b, target: c});
        //alert (a.id);
        //}
        
    },
    add : function(){
        var self = this;
        var a = self.nodes[0];
        var d = {id: "d"+Math.random()};
        var c = self.nodes[1];
        if (!a){
             self.nodes.push(d)
        }else 
            {
            //var c = self.nodes[1];
            self.nodes.push(d);
            self.links.push({source: d, target: a}, {source: d, target: c});
            }
        self.useradd();
        self.start();
        //alert(d.id);
    },
    useradd  : function(){
        var self = this;
        //var a = self.nodes2[0];
        var a = self.nodes2[0];
        var d = {id: "d"+self.array[self.i].node, who: self.array[self.i].who};
        //alert (self.array[self.i].who);
        //var c = self.nodes[1];
        self.nodes2.push(d);
        self.nodes3.push(d);
        //self.links2.push({source: d, target: a});
        /*var j;
             var x=220;
             var y=50;
             var k=100;
            for (j=0; j < 5; j++){
                x= x+j;
                y= y+j;
                alert (" j: "+j+" x: "+x+" y: "+y);
                setTimeout(function(){ self.node.attr("transform", "translate(" + x + "," + y + ")") },j*k);
            }*/
        self.userstart();
    },
    userdel : function(){
        var self = this;
        self.nodes2.splice(self.nodes2.length-1); // borra el ultimo nodo creado
        //self.links.shift(); // remove a-b
        //self.links2.pop(); // remove b-c
        self.userstart();
    },
    del : function(){
        var self = this;
        self.nodes.splice(self.nodes.length-1); // borra el ultimo nodo creado
        //self.links.shift(); // remove a-b
        self.links.pop(); // remove b-c
        self.userdel();
        self.start();
    },
    start : function(){
        var self = this;

        self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link.enter().insert("line", ".node").attr("class", "link").attr('fill','green');
        self.link.exit().remove();

        //self.link2 = self.link2.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        //self.link2.enter().insert("line", ".node").attr("class", "link");
        //self.link2.exit().remove();

        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 6).attr('fill','red').on("zoom", function(){self.rescale()});
        self.node.exit().remove();

        self.force.start();
    },
    userstart : function(){
        
        var self = this;

        var randomValuex = Math.random()*200;
        var randomValuey = Math.random()*200;
        //alert(randomValuex);


        self.link2 = self.link2.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link2.enter().insert("line", ".node").attr("class", "link").attr("x2", randomValuex-150).attr("y2",randomValuey).transition()
      .duration(1500).attr("x2",randomValuex).attr("stroke",'white');
        self.link2.exit().remove();

        self.node2 = self.node2.data(self.force.nodes(), function(d) { return d.id;});
        self.node2.enter().append("png:image").attr("xlink:href", "/static/images/user_min.png").attr("width", 20).attr("height", 20)
        .attr("x", randomValuex-200)  .attr("y",randomValuey).transition().duration(1500).attr("x",randomValuex);
        //self.node2.enter().append("png:image").attr("xlink:href", "/static/images/user_min.png").attr("width", 40).attr("height", 40).attr("x", function(d) { return d.source.x;} )  .attr("y",function(d) { return d.source.y;}) ;
        self.node2.exit().remove();

        self.node3 = self.node3.data(self.force.nodes(), function(d) { return d.id;});
        self.node3.enter().append("text").attr("x", randomValuex).attr("y",randomValuey).text(self.array[self.i].who);
        self.node3.exit().remove();

        //self.force.start();
    }, 

    tick : function(){

        var randomValuex = Math.random()*200;
        var randomValuey = Math.random()*200;

        var self = this;

        self.node.attr("cx", function(d) { return d.x; })
            .attr("cy", function(d) { return d.y; })
            

        self.link2.attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; });


        self.node2;
        self.node3;
    },
    rescale : function() {

        var self = this;

        self.svg.attr("transform","translate(" + d3.event.translate + ")" + " scale(" + d3.event.scale + ")");

    }
});
