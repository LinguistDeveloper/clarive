Cla.Swarm = Ext.extend( Ext.Panel, {
    initComponent : function(){
        var self = this;
        self.i = 0;
        self.identificador_nodos = 00000000;
        self.posicionx = 0;
        self.posiciony = 0;

        self.cuenta = 0;
        self.origen=0;

        self.tbar = [
            { text:_('Start Anim'), handler:function(){ self.start_anim() } },
            { text:_('Stop Anim'), handler:function(){ self.stop_anim() } },
            '-',
            { text:_('First'), handler:function(){ self.first() } },
            '-',
            { text:_('Add'), handler:function(){ self.i++; self.add() } },
            '-',
            { text:_('Add2'), handler:function(){ self.i++; self.add2() } },
            '-',
            { text:_('Del'), handler:function(){ self.i++; self.del() } }
        ];

        Cla.Swarm.superclass.initComponent.call(this);
         
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

        //var color = d3.scale.category10();

        self.nodes = [];

        self.user = [];
        self.links = [];
        self.nodes2 = [];
        self.nodes3 = [];


        self.array =  [];
        self.datos(self.array);


        for(cnt = 0 ; cnt < self.array.length; cnt++){
            self.array[cnt].t = 1000*(cnt+1);
        }

        $.injectCSS({
            //".link": { "stroke": "green", 'stroke-width': '2.5px'},
            //".link2": { "stroke": "blue", 'stroke-width': '2.5px'},
            //".node": { "stroke": "#fff", fill:"#000", 'stroke-width': '1.5px' },
            //".node.a": { "fill": "red" },
            //".node.b": { "fill": "green" },
            //".node3": { "fill": "#1f77b4" }
        });

        var id = self.body.id; 
        var selector = '#' + id; 

        self.vis = d3.select("#"+ id ).append("svg:svg").attr("width", '100%').attr("height", '100%').style("background-color", "black").attr("preserveAspectRatio", "xMinYMin meet");
        self.svg = self.vis.append("svg:g").call(d3.behavior.zoom().on("zoom", function(){self.rescale()})).on("dblclick.zoom", null).append('svg:g');
        
        //CREAMOS UN RECTANGULO EN BLANCO DONDE SE VA A PINTAR TODO Y ES EL QUE HACE EL ZOOM
        self.svg.append('svg:rect')
            .attr('width', '100%')
            .attr('height', '100%')
            .attr('fill', 'black')
        //LLAMAMOS AL LAYOUT
        self.force = d3.layout.force()
            .nodes(self.nodes)
            .links(self.links)
            .charge(function(lnk,cnt){
                return lnk.type=="real"? 0 : lnk.type=="actor"?lnk.charge-- : -40;
            })
            .linkDistance(
                    function(lnk){
                        return lnk.source.type=='real' || lnk.source.type=='real'  ? 10 : 80;
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
        self.texto_nodos_iniciales = self.svg.selectAll("text");
        self.node2_copia = self.svg.selectAll(".path");
        self.node3_copia = self.svg.selectAll(".path");
 

        //COLORES DE LOS NODOS  

        //self.getRandomColor();
                         //alert(" el color es " +self.nodos_ini);
        //self.getLuxColor(self.getRandomColor(),0.8);
                 //alert(" y los nodos inciales son " +self.nodos_ini);


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

        self.anim_running = true;
        setTimeout(function(){ self.anim() },self.timer*1.1);
    },
    stop_anim : function(){

        var self = this;

        self.anim_running = false;
    },
    anim : function(){

        var self = this;

        if( !self.anim_running ) return;
        
        if(self.array.ev[self.i] == 'add') {
            self.add();
            self.i++;
        }else if(self.array.ev[self.i] == 'modify')

        {
            //self.userdel();
            self.modify();
            self.i++;
        }else if(self.array.ev[self.i] == 'del'){
            //self.userdel();
            self.del();
            self.i++;

        }
        setTimeout(function(){ self.anim() },self.timer*1.1);
    },
    first : function(){

        var self = this;

        var a = { id: "9999" , t: "raiz", ev: "raiz", who: "raiz", node: "raiz", parent: "raiz", color: "white", posicionx: 0, posiciony: 0};     
        self.nodes.push(a);

        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        //quitamos la parte de el nodo para que no aparezca, solo definimos el elemento circulo
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 6).attr('fill','red').on("zoom", function(){self.rescale()});
        self.node.exit().remove();
        
        self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
        //Nos pasa igual que con el circulo. Si hacemos visible el .text vemos el texto del nodo raiz.
        self.node4.enter().append("text");//.text(a.node);
        self.node4.exit().remove();

        self.node5 = self.node5.data(self.force.nodes(), function(d) { return d.id;});
        //Nos pasa igual que con el circulo. Si hacemos visible el .text vemos el texto del nodo raiz.
        self.node5.enter().append("text");//.text(a.node);
        self.node5.exit().remove();

        //TRUCO SE NOS MUEVEN LOS COLORES TODOS UNA POSICION
        //self.nodes[0].color = "white";
        //self.nodos_iniciales();
        
        self.force.start();

    },
    add_group_node : function(a,d){
        var self = this;
        self.nodes.push(d);
        self.links.push({source: d, target: a});

        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 6).attr('fill',d.color||'red').on("zoom", function(){self.rescale()});
        self.node.exit().remove();

        self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link.enter().insert("line", ".node").attr("class", "link").attr("stroke","steelblue"); //.attr("stroke-opacity",0.4).attr("stroke-width",3).attr("globalCompositeOperation", "lighter");
        self.link.exit().remove();

        self.force.start();
    },
    add_single_node : function(a,d){
        var self = this;
        self.nodes.push(d);
        self.links.push({source: d, target: a});

        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("circle").attr("r", 6).attr('fill',d.color||'blue').on("zoom", function(){self.rescale()});
        self.node.exit().remove();

        self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link.enter().insert("line", ".node").attr("class", "link").attr("stroke","steelblue"); //.attr("stroke-opacity",0.4).attr("stroke-width",3).attr("globalCompositeOperation", "lighter");
        self.link.exit().remove();

        self.force.start();

    },
    add_user_node : function(a,d){
        var self = this;
        self.nodes.push(d);
        self.links.push({source: d, target: a},{source: d, target: self.nodes[2]});

        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("png:image").attr("xlink:href", "/static/images/user_min.png").attr("width", 20).attr("height", 20);
   
        self.node.exit().remove();

        self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link.enter().insert("line", ".node").attr("class", "link").attr("stroke","steelblue")//.style("visibility", "hidden"); //.attr("stroke-opacity",0.4).attr("stroke-width",3).attr("globalCompositeOperation", "lighter");
        self.link.exit().remove();

        self.force.start();

    },
    add_user_mover : function(a,d,anterior){
        
       var self = this;

       var jas = 0;
       if(jas!=self.nodes.length){
       alert(a.node + self.nodes.length);
        while (jas < self.nodes.length){
                //Buscamos el nodo a borrar.
                if (self.nodes[jas].node == a.node){
                    //alert("borro el nodo  " + self.nodes[j].node + "  tamano nodo " + self.nodes.length + "posicion  "+ j );
                    self.links.splice(self.links.indexOf(3),1);//borro el link - posicion y nº de links a borrar.
                    //alert("tamano nodo " + self.nodes.length);
                    jas=self.nodes.length;
                }   
            jas++;
        }

        }

        alert("pasa de mi");

        self.links.splice(self.links.indexOf(3),1);

        self.links.push({source: a, target: anterior},{source: a, target: anterior});

        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("png:image").attr("xlink:href", "/static/images/user_min.png").attr("width", 20).attr("height", 20);
   
        self.node.exit().remove();

        self.link = self.link.data(self.force.links(), function(d) {return d.source.id + "-" + d.target.id;  });
        self.link.enter().insert("line", ".node").attr("class", "link").attr("stroke","steelblue")//.style("visibility", "hidden"); //.attr("stroke-opacity",0.4).attr("stroke-width",3).attr("globalCompositeOperation", "lighter");
        self.link.exit().remove();

        self.force.start();

    },
    add2 : function(){
        var self = this;

        self.add_group_node( self.nodes[0],{id: "#d"+Math.random(), t: "iniciales", ev: "iniciales", who: "iniciales", node: "iniciales", 
            parent: 'xxx', color: "yellow", posicionx: 0, posiciony: 0} ); 

          for( var i=0; i<1; i++) {
            self.add_single_node( self.nodes[1],{id: "#d"+Math.random(), type:"real", t: "iniciales", ev: "iniciales", who: "iniciales", node: "iniciales", 
                parent: 'xxx', color: "blue", posicionx: 0, posiciony: 0} ); 
        }


        self.add_user_node( self.nodes[0],{id: "#d"+Math.random(), t: "iniciales", ev: "iniciales", who: "iniciales", node: "usuario", 
            parent: 'xxx', color: "green", posicionx: 0, posiciony: 0} ); 
      
        self.add_user_mover( self.nodes[3],self.node[2], self.nodes[0] ); 
    },
    

    tick : function(){
        var self = this;
        self.origen= self.origen-1;

        self.node.attr("x", function(d) {  return d.x; })
            .attr("y", function(d) {  return d.y; })
            
        self.node.attr("cx", function(d) {  return d.x; })
            .attr("cy", function(d) {  return d.y; })

        self.node4.attr("x", function(d) { return d.x-10; })
            .attr("y", function(d) { return d.y-10; })

        self.node5.attr("x", function(d) { return d.x-10; })
            .attr("y", function(d) { return d.y-10; })

        self.link.attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; })
          .attr("x2", function(d) { return d.target.x; })
          .attr("y2", function(d) { return d.target.y; });

         //self.pintar_usuario();

    },
    rescale : function() {

        var self = this;

        self.svg.attr("transform","translate(" + d3.event.translate + ")" + " scale(" + d3.event.scale + ")");

    },
    datos : function(array) {
        
        var self = this;
           
            Baseliner.ajaxEval('/controllerlogdiego/leer_log/', { }, function(res){
               
            self.array = res;

               //alert("llego aqui"+ self.array.ev[0]);
               //console.log(self.array);
               
               /* self.links = [];
                
                var link = function(source){
                    Ext.each( source.children, function(chi){
                        self.links.push({ source: source.name, target: chi.name, type:"child" });
                        link( chi );
                    });
                }
                link( res.data );a

                self.nodes = {};

                // Compute the distinct nodes from the links.
                self.links.forEach(function(link) {
                  link.source = self.nodes[link.source] || (self.nodes[link.source] = {name: link.source});
                  link.target = self.nodes[link.target] || (self.nodes[link.target] = {name: link.target});
                });
                
                self.draw();*/

            });
    }
});


