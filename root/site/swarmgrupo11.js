Cla.Swarm = Ext.extend( Ext.Panel, {
    background_color: '#fff',
    start_mode: 'manual',
    initComponent : function(){
        var self = this;
        self.cuenta = 0;
        self.res = { data:[] };
        self.parents =  {};
        self.origen=0;

        self.btn_start = new Ext.Button({ icon: IC('start'), disabled: false, handler: function(){ self.start_anim() } });
        self.btn_pause = new Ext.Button({ icon: IC('pause.gif'), disabled: true, handler: function(){ self.pause_anim() } });
        self.btn_stop = new Ext.Button({ icon: IC('stop'), disabled: true, handler: function(){ self.stop_anim() } });

        self.bbar = [ self.btn_start, self.btn_pause, self.btn_stop ];

        Cla.Swarm.superclass.initComponent.call(this);
         
        self.on('resize', function(p,w,h){
            if( self.svg ) {
            }
        });
        self.on('afterrender', function(){
            self.init();
            if( self.start_mode == 'auto' ) self.start_anim();
        });
    },
    init : function(){
        var self = this;

        //var color = d3.scale.category10();

        self.nodes = [];
        self.links = [];
        self.nodes2 = [];
        self.nodes3 = [];

        $.injectCSS({
            //".link": { "stroke": "green", 'stroke-width': '2.5px'},
            //".link2": { "stroke": "blue", 'stroke-width': '2.5px'},
            //".node": { "stroke": "#fff", fill:"#000", 'stroke-width': '1.5px' },
            ".node.a": { "fill": "red" },
            ".node.b": { "fill": "green" },
            ".node3": { "fill": "#1f77b4" }
        });

        var id = self.body.id; 
        var selector = '#' + id; 

        self.vis = d3.select("#"+ id ).append("svg:svg").attr("width", '100%').attr("height", '100%').style("background-color", self.background_color).attr("preserveAspectRatio", "xMinYMin meet");
        self.svg = self.vis.append("svg:g").call(d3.behavior.zoom().on("zoom", function(){self.rescale()})).on("dblclick.zoom", null).append('svg:g');
        
        //CREAMOS UN RECTANGULO EN BLANCO DONDE SE VA A PINTAR TODO Y ES EL QUE HACE EL ZOOM
        self.svg.append('svg:rect')
            .attr('width', '100%')
            .attr('height', '100%')
            .attr('fill', self.background_color )
        //LLAMAMOS AL LAYOUT
        self.force = d3.layout.force()
            .nodes(self.nodes)
            .links(self.links)
            .charge(-100)
            .linkDistance(     
                function(lnk){
                    return lnk.target.node=='iniciales' || lnk.target.node=='iniciales'  ? 1 : 100;
                }
            )
            //.linkStrength(.1)
            .size([self.width, self.height])
            .on("tick", function(){ self.tick() });

        self.node = self.svg.selectAll(".node");
        self.link = self.svg.selectAll(".link");
        self.link2 = self.svg.selectAll(".link");
        self.node2 = self.svg.selectAll(".path");
        self.node3 = self.svg.selectAll(".path");
        self.node4 = self.svg.selectAll(".path");
        self.node5 = self.svg.selectAll(".path");
        self.node6 = self.svg.selectAll(".path");
        self.node7 = self.svg.selectAll(".path");
        self.node8 = self.svg.selectAll(".path");
        self.node9 = self.svg.selectAll(".path");
        self.texto = self.svg.selectAll("text");
  
        //COLORES DE LOS NODOS  

        var Color_Nodos_Raiz = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos_Raiz").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos_Raiz.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos_Raiz.append("stop").attr("offset", "60%").attr("stop-color", "#4682B4").attr("stop-opacity", 0.5); // Color steelblue
        Color_Nodos_Raiz.append("stop").attr("offset", "100%").attr("stop-color", "#90B4D2").attr("stop-opacity", 0).attr("brighter",1); // Color steelblue aclarado + 4

        var Color_texto_Raiz = self.svg.append("defs").append("linearGradient").attr("id", "Color_texto_Raiz").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_texto_Raiz.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_texto_Raiz.append("stop").attr("offset", "60%").attr("stop-color", "#4682B4").attr("stop-opacity", 0.5); // Color steelblue
        Color_texto_Raiz.append("stop").attr("offset", "100%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1).attr("brighter",1); // Color blanco


        var Color_Nodos = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos.append("stop").attr("offset", "60%").attr("stop-color", "#FF0000").attr("stop-opacity", 0.5); // Color red
        Color_Nodos.append("stop").attr("offset", "100%").attr("stop-color", "#FF6666").attr("stop-opacity", 0).attr("brighter",1); // Color red aclarado + 4


        var Color_Texto_Nodos = self.svg.append("defs").append("radialGradient").attr("id", "Color_Texto_Nodos").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Texto_Nodos.append("stop").attr("offset", "0%").attr("stop-color", "#FF1919").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Texto_Nodos.append("stop").attr("offset", "60%").attr("stop-color", "#FF0000").attr("stop-opacity", 0.5); // Color red
        Color_Texto_Nodos.append("stop").attr("offset", "100%").attr("stop-color", "#FF1919").attr("stop-opacity", 1).attr("brighter",1); // Color blanco

        var Amarillo = self.svg.append("defs").append("radialGradient").attr("id", "Amarillo").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Amarillo.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Amarillo.append("stop").attr("offset", "60%").attr("stop-color", "#FFFF00").attr("stop-opacity", 0.5); // Color amarillo
        Amarillo.append("stop").attr("offset", "100%").attr("stop-color", "#FFFF66").attr("stop-opacity", 0).attr("brighter",1); // Color amarillo aclarado + 4

        var Verde = self.svg.append("defs").append("radialGradient").attr("id", "Verde").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Verde.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Verde.append("stop").attr("offset", "60%").attr("stop-color", "#00FF00").attr("stop-opacity", 0.5); // Color verde
        Verde.append("stop").attr("offset", "100%").attr("stop-color", "#66FF66").attr("stop-opacity", 0).attr("brighter",1); // Color verde aclarado + 4
    },
    start_anim : function(){
        var self = this;
        Cla.ajax_json('/swarm/activity', {}, function(res){
            self.res = res;
            self.i = 0;
            if( !self.initiated ) {
                self.first();
                self.initiated = true;
            }
            self.anim_running = true;
            self.btn_start.disable();
            self.btn_pause.enable();
            self.btn_stop.enable();
            setTimeout(function(){ self.anim() }, 100 );
        });
    },
    pause_anim : function(){
        var self = this;
        self.btn_start.enable();
        self.btn_pause.disable();
        self.btn_stop.disable();
        self.anim_running = false;
    },
    stop_anim : function(){
        var self = this;
        self.btn_start.enable();
        self.btn_pause.disable();
        self.btn_stop.disable();
        self.anim_running = false;
    },
    anim : function(){
        var self = this;
        if( !self.anim_running ) return;

        var row = self.res.data[ self.i++ ];
        if( !row ) {
            // no more rows? stop animation
            self.stop_anim();
            return;
        }
        row.id = Ext.id();
        var next_timer = 1000;

        //alert("llego aqui "+row.parent + "posicion" + self.i);
        if( row.parent ) {
            if( !self.parents[row.parent] ) {
                self.parents[row.parent] = true;
                self.add_inicial( row.parent );
                var row = self.res.data[ self.i-- ];
            }else{
            if(row.ev == 'add') {
                self.add(row);
            }else {
                self.del(row);
            }
        }
        }
        setTimeout(function(){ self.anim() }, next_timer);
    },
    first : function(){
        var self = this;

        var a = { id: "9999" , node: "raiz"}
        self.nodes.push(a);

        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        //quitamos la parte de el nodo para que no aparezca, solo definimos el elemento circulo
        self.node.enter().append("circle");//.attr("class", function(d) { return "node " + d.id; }).attr("r", 6).attr('fill','red').on("zoom", function(){self.rescale()});
        self.node.exit().remove();
        
        self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
        //Nos pasa igual que con el circulo. Si hacemos visible el .text vemos el texto del nodo raiz.
        self.node4.enter().append("text");//.text(a.node);
        self.node4.exit().remove();

        self.node5 = self.node5.data(self.force.nodes(), function(d) { return d.id;});
        //Nos pasa igual que con el circulo. Si hacemos visible el .text vemos el texto del nodo raiz.
        self.node5.enter().append("text");//.text(a.node);
        self.node5.exit().remove();

    },
    add_inicial : function(parent_node){
        var self = this;
        var a = self.nodes[0];
        var d = { id: "#d"+Math.random(), t: "iniciales", ev: "iniciales", 
            who: "iniciales", node: "iniciales", parent: parent_node };

        if (!a){
             self.nodes.push(d)
        }else 
            {
            //var c = self.nodes[1];
            self.nodes.push(d);
            self.links.push({source: d, target: a});
            }
        
        self.start_inicial();
    },
    start_inicial : function(){

        var self = this;

        self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link.enter().insert("line", ".node").attr("class", "link").attr("stroke","steelblue").attr("stroke-opacity",0.4);
        self.link.exit().remove();


        self.texto = self.texto.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });   
        self.texto.enter().append('text').attr("fill","url(#Color_texto_Raiz)").text(function(d) { return d.source.parent;});   

        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 10).attr("fill","url(#Color_Nodos_Raiz)").on("zoom", function(){self.rescale()});
        self.node.exit().remove();

        self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
        self.node4.enter().append("text").text(function(d) { return d.node;}).attr("fill",self.background_color);
        self.node4.exit().remove();


        self.node5 = self.node5.data(self.force.nodes(), function(d) { return d.id;});
        self.node5.enter().append("text").text(function(d) { return d.node;}).attr("fill",self.background_color);
        self.node5.exit().remove();

        //CREAMOS EL LINK2 Y LOS NODOS 2 Y 3 VACIOS YA QUE EN EL ARBOL INICIAL NO HAY USUARIOS   
        self.link2 = self.link2.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link2.enter().insert("line", ".node");
        self.link2.exit().remove();

        self.node2 = self.node2.data(self.force.nodes(), function(d) { return d.id;});
        self.node2.enter().append("png:image");
        self.node2.exit().remove();

        self.node3 = self.node3.data(self.force.nodes(), function(d) { return d.id;});
        self.node3.enter().append("text");
        self.node3.exit().remove();

        self.force.start();
        //self.borrar_nodo(self.timer);
    },
    add : function(row){
        var self = this;
        var a = self.nodes[0];
        var d = row; //{id: self.i, node:  row.parent};

        var timer = 1000;  // TODO calculate from previous and next events

        if (!a){
             self.nodes.push(row);
             self.links.push({source: row, target: row});
        }else {
            //var c = self.nodes[1];
            var j = 0;
            while (j < self.nodes.length){
                //alert("dentro el while "+self.nodes[j].node +" el parent es "+ row.parent);
                if (self.nodes[j].parent ==  row.parent && self.nodes[j].node == "iniciales"){
                        self.nodes.push(row);
                        self.links.push({source: row, target: self.nodes[j]});
                        j=self.nodes.length;
                }   
                j++;
            }
            // self.useradd(row);
            self.userstart(row);
            self.start({ row: row, timer: timer });
        }
    },
    del : function(row){

        var self = this;

        var j = 0;

        while (j < self.nodes.length){
                //Buscamos el nodo a borrar.
                if (self.nodes[j].node == row.node){

                    self.nodes.splice(self.nodes.indexOf(self.nodes[j]),1);//borro el nodo - posicion y nº de nodos a borrar.
                    //self.links.splice(self.links.indexOf(self.links[j]),1);//borro el link - posicion y nº de links a borrar.

                    j=self.nodes.length;
                }   
            j++;
        }

        self.userstart(row);
        self.start({ row: row, timer: 1000 });
    },
    start : function(dt){
        var self = this;
        var row = dt.row;
        var timer = dt.timer;

        self.node5 = self.node5.data(self.force.nodes(), function(d) { return d.id;});
        self.node5.enter().append("text").text(row.node).attr("fill","url(#Color_Texto_Nodos)").attr("fill-opacity",0.6).style("visibility", "hidden");
        self.node5.exit().remove();
       
        self.texto = self.texto.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });   
        self.texto.enter().append('text').attr("fill",self.background_color).text(function(d) { return d.source.parent;}).style("visibility", "hidden");   

        self.node6 = self.node6.data(self.force.nodes(), function(d) { return d.id;});
        self.node6.enter().append("text").style("visibility", "hidden");
        self.node6.exit().remove();
        self.node7 = self.node7.data(self.force.nodes(), function(d) { return d.id;});
        self.node7.enter().append("text").style("visibility", "hidden");
        self.node7.exit().remove();
        self.node8 = self.node8.data(self.force.nodes(), function(d) { return d.id;});
        self.node8.enter().append("text").style("visibility", "hidden");
        self.node8.exit().remove();
        self.node9 = self.node9.data(self.force.nodes(), function(d) { return d.id;});
        self.node9.enter().append("text").style("visibility", "hidden");
        self.node9.exit().remove();
        
        self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link.enter().insert("line", ".node");//.attr("class", "link").attr("stroke","green");
       // self.link.exit().remove();

        self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
        self.node4.enter().append("text").text(row.node).attr("fill","url(#Verde)").transition().duration(timer).attr("fill","url(#Color_Texto_Nodos)").remove();
        self.node4.exit().remove();
      
        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 10).attr("fill","url(#Verde)").attr("fill-opacity",0.6)
                         .on('mouseover', function(d)
                         {
                            d3.select(this).transition()
                            .duration(750)
                            .attr("r", 55)
                            .attr("fill","url(#Amarillo)")
                            //.attr("fill-opacity",0.6);
                            self.node9.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(row.t).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+3).attr("fill","url(#Color_Texto_Nodos)").attr("fill-opacity",0.6).style("visibility", "visible");
                            self.node6.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(row.ev).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+16).attr("fill","url(#Color_Texto_Nodos)").attr("fill-opacity",0.6).style("visibility", "visible");
                            self.node7.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(row.who).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+29).attr("fill","url(#Color_Texto_Nodos)").attr("fill-opacity",0.6).style("visibility", "visible");
                            self.node8.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(row.parent).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+42).attr("fill","url(#Color_Texto_Nodos)").attr("fill-opacity",0.6).style("visibility", "visible");
                            return self.node5.attr("fill","url(#Color_Texto_Nodos)").style("visibility", "visible");
                         })
                         .on("mouseout", function()
                         {
                         d3.select(this).transition()
                         .duration(750)
                         .attr("r", 10)
                         .attr("fill","url(#Color_Nodos)")
                         .attr("fill-opacity",0.6);
                         self.node6.style("visibility", "hidden");
                         self.node7.style("visibility", "hidden");
                         self.node8.style("visibility", "hidden");
                         self.node9.style("visibility", "hidden");
                         return self.node5.attr("fill","url(#Color_Texto_Nodos)").style("visibility", "hidden");//})
                         })
                         .call(self.force.drag)
                         .transition().duration(timer).attr("fill","url(#Color_Nodos)").attr("fill-opacity",0.6);
        self.node.exit().remove();
        self.force.start();
        //self.pintar_usuario();

        self.node2.attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*60); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*60); });
        self.node2.exit().remove();

        self.node3.attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*60); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*60); });
        self.node3.exit().remove();


        self.link2.attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; })
          .attr("x2", function(d) { return d.target.x-(self.calculo_direcciones_x(d.target.x)*60); })
            .attr("y2", function(d) { return d.target.y-(self.calculo_direcciones_y(d.target.y)*60); });
        self.link2.exit().remove();

        self.origen = 50;
    },
    userstart : function(row){
        var self = this;

        var randomValuex = Math.random()*200;
        var randomValuey = Math.random()*200;

        //quitamos esto para quitar la linea de link2
        self.link2 = self.link2.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link2.enter().insert("line", ".node").attr("stroke","orange").attr("stroke-opacity",0.6).attr("class", "link");       
        self.link2.exit().remove();

        self.node2 = self.node2.data(self.force.nodes(), function(d) { return d.id;});
        self.node2.enter().append("png:image").attr("xlink:href", "/static/images/user_min.png").attr("width", 20).attr("height", 20);
        self.node2.exit().remove();

        self.node3 = self.node3.data(self.force.nodes(), function(d) { return d.id;});
        self.node3.enter().append("text").text(row.who).attr("fill","#00CCFF")

    }, 
    tick : function(){
        var self = this;
        self.origen= self.origen-1;

        self.node.attr("cx", function(d) { return d.x; })
            .attr("cy", function(d) { return d.y; })
            
        self.node4.attr("x", function(d) { return d.x-10; })
            .attr("y", function(d) { return d.y-10; })

        self.node5.attr("x", function(d) { return d.x-10; })
            .attr("y", function(d) { return d.y-10; })

        self.texto.attr('x',function(d){ return (d.source.x+d.target.x)/2;})
        .attr('y',function(d){ return (d.source.y+d.target.y)/2;});

        self.link.attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; })
          .attr("x2", function(d) { return d.target.x; })
          .attr("y2", function(d) { return d.target.y; });

        self.node2.attr("x", function(d) { return d.x+(self.calculo_direcciones_x(d.x)*self.origen); })
            .attr("y", function(d) { return d.y+(self.calculo_direcciones_y(d.y)*self.origen); });
        self.node2.exit().remove();

        self.node3.attr("x", function(d) { return d.x+(self.calculo_direcciones_x(d.x)*self.origen); })
            .attr("y", function(d) { return d.y+(self.calculo_direcciones_y(d.y)*self.origen); });
        self.node3.exit().remove();

        self.link2.attr("x1", function(d) { return d.source.x; })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.source.x+(self.calculo_direcciones_x(d.source.x)*self.origen); })
            .attr("y2", function(d) { return d.source.y+(self.calculo_direcciones_y(d.source.y)*self.origen); });

        if(self.origen < 0 ){
            self.link2.transition().duration(0).remove();       
            self.link2.exit().remove();

            self.node2.transition().duration(0).remove();       
            self.node2.exit().remove();

            self.node3.transition().duration(0).remove();       
            self.node3.exit().remove();
        }
    },
    rescale : function() {
        var self = this;
        self.svg.attr("transform","translate(" + d3.event.translate + ")" + " scale(" + d3.event.scale + ")");
    },
    calculo_direcciones_x : function(x){
        if(x < 350){
            x=1;
        }else{
            x=-1;
        }
        return x;
    },
    calculo_direcciones_y : function(y){

        if(y < 250){
            y=1;
        }else{
            y=-1;
        }
        return y;
    }
});