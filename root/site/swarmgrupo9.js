Cla.Swarm = Ext.extend( Ext.Panel, {
    
    initComponent : function(){
        var self = this;
        self.i = 0;

        self.identificador_nodos = 00000000;
        self.posicionx = 0;
        self.posiciony = 0;

        self.titulos = 0;

        self.origen=0;

        self.tbar = [
            { text:_('Start Anim'), handler:function(){ self.start_anim() } },
            { text:_('Stop Anim'), handler:function(){ self.stop_anim() } },
            '-',
            { text:_('First'), handler:function(){ self.first() } },
            '-',
            { text:_('Add'), handler:function(){ self.i++; self.add() } },
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

        self.nodes = [];
        self.links = [];
        self.nodes2 = [];
        self.nodes3 = [];


        self.array =  [];
        self.datos(self.array);


        for(cnt = 0 ; cnt < self.array.length; cnt++){
            self.array.data[cnt].t = 1000*(cnt+1);
        }

        $.injectCSS({
            //".link": { "stroke": "green", 'stroke-width': '2.5px'},
            //".node": { "stroke": "#fff", fill:"#000", 'stroke-width': '1.5px' },
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
        self.texto_nodos_iniciales = self.svg.selectAll("text");
        self.node2_copia = self.svg.selectAll(".path");
        self.node3_copia = self.svg.selectAll(".path");
 

        //COLORES DE LOS NODOS  
/*
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
        */

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

        if(self.array.data[self.i].ev == 'add') {
            self.add();
            self.i++;
        }else if(self.array.data[self.i].ev == 'mod')

        {
            //self.userdel();
            self.modify();
            self.i++;
        }else if(self.array.data[self.i].ev == 'del'){
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

        //TRUCO SE NOS MUEVEN LOS COLORES TODOS UNA POSICION
        //self.nodes[0].color = "white";
        self.nodos_iniciales();
        
    },
    nodos_iniciales : function(){

        var self = this;

        var arrayOriginal = [];  
        var arraySinDuplicados = [];
        var i = 0;
        var h = 0;

        for (i=0; i< self.array.data.length; i++){
            arrayOriginal[i] = self.array.data[i].parent;
        }
        
        $.each(arrayOriginal, function(i, el){
        if($.inArray(el, arraySinDuplicados) === -1) arraySinDuplicados.push(el);
        });

        for(j=0; j< arraySinDuplicados.length; j++){
            self.add_inicial(arraySinDuplicados[j]);
            self.force.tick();
        }

    },
    add_inicial : function(array){

        var self = this;
        var a = self.nodes[0];
        var d = {id: "#d"+self.titulos + "d"+ Math.random(), t: "iniciales", ev: "iniciales", who: "iniciales", node: "iniciales", parent: array, color: "blue", posicionx: 0, posiciony: 0};           

        if (!a){
             self.nodes.push(d)
        }else 
            {
            //var c = self.nodes[1];
            self.nodes.push(d);
            self.links.push({source: d, target: a});
            }
        
        self.titulos++;
        self.start_inicial();
    },
    start_inicial : function(){

        var self = this;




        //Damos colores
        var colores = ['#FFFFFF','#FF0000','#0000FF','#008000','#FFFF00','#A52A2A','#FFA500','#4682B4','#FFC0CB','#CD5C5C','#CC99FF','#808080'];
        //var colores = ['white','red','blue','green','yellow','brown','orange','steelblue','ping','indianRed','purple','gray'];

        //OJO HAY QUE TENER EN CUENTA QUE EL NODO RAIZ ESTA AUNQUE NO SE PINTE
        var color = colores[self.nodes.length-2];//self.nodes.length-2 es la posicion 0
        //alert(colorRE);

        self.nodes[self.nodes.length-2].color = color;//self.nodes.length-1 es la posicion 1
        //var color_brillo = self.getLuxColor(color,0.8);



        var Color_Nodos_Raiz = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos_Raiz").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos_Raiz.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos_Raiz.append("stop").attr("offset", "60%").attr("stop-color", color).attr("stop-opacity", 0.5); // Color steelblue
        Color_Nodos_Raiz.append("stop").attr("offset", "100%").attr("stop-color", "#FFFFFF" ).attr("stop-opacity", 0).attr("brighter",1); // Color steelblue aclarado + 4

        var Color_texto_Raiz = self.svg.append("defs").append("linearGradient").attr("id", "Color_texto_Raiz").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_texto_Raiz.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_texto_Raiz.append("stop").attr("offset", "60%").attr("stop-color", color).attr("stop-opacity", 0.5); // Color steelblue
        Color_texto_Raiz.append("stop").attr("offset", "100%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1).attr("brighter",1); // Color blanco

        //Creamos los links y los nodos.

        self.node = self.node.data(self.force.nodes(), function(d) { nodoid= d.id ; return d.id;});
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 10).attr("fill","url(#Color_Nodos_Raiz)").on("zoom", function(){self.rescale()});
        self.node.exit().remove();


        self.texto_nodos_iniciales = self.texto_nodos_iniciales.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });   
        self.texto_nodos_iniciales.enter().append('text').attr("fill","url(#Color_texto_Raiz)").text(function(d) { return d.source.parent;});   

        self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link.enter().insert("line", ".node").attr("class", "link").attr("stroke","steelblue").attr("stroke-opacity",0.4).attr("stroke-width",3).attr("globalCompositeOperation", "lighter");
        self.link.exit().remove();

        //INICIAMOS EL RESTO DE NODOS PERO NO LE DAMOS VALORES PARA QUE NO SE MUESTREN

        self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
        //Nos pasa igual que con el circulo. Si hacemos visible el .text vemos el texto del nodo raiz.
        self.node4.enter().append("text");//.text(a.node);
        self.node4.exit().remove();


        self.node5 = self.node5.data(self.force.nodes(), function(d) { return d.id;});
        self.node5.enter().append("text")//.text(function(d) { return d.node;}).attr("fill","url(#Color_texto_Raiz)");
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

    },
    add : function(){


        var self = this;
        var a = self.nodes[0];

        var nodos_ini = 0;

        var d = {id: self.identificador_nodos, t: self.array.data[self.i].t, ev: self.array.data[self.i].ev, who: self.array.data[self.i].who, node: self.array.data[self.i].node, parent: self.array.data[self.i].parent, color: "blue", posicionx: 0, posiciony: 0};           

        //CONTADOR DE APLICACION
       if((self.i-1) <0){
            self.timer = self.array.data[self.i].t;
        }else{
            self.timer = self.array.data[self.i].t-self.array.data[self.i-1].t;

        }

        if (!a){
             self.nodes.push(d);
             self.links.push({source: d, target: d});
        }else 
            {
            //var c = self.nodes[1];
            var j = 0;
            while (j < self.nodes.length){

                if (self.nodes[j].parent == self.array.data[self.i].parent){
                        self.nodes.push(d);
                        self.links.push({source: d, target: self.nodes[j]});
                        j=self.nodes.length;
                }   
                j++;
            }

        self.identificador_nodos++;
        self.userstart();
        self.start();
        }
    },    
    modify : function(){

        var self = this;
        var a = self.nodes[0];

        var d = {id: self.identificador_nodos, t: self.array.data[self.i].t, ev: self.array.data[self.i].ev, who: self.array.data[self.i].who, node: self.array.data[self.i].node, parent: self.array.data[self.i].parent, color: "blue", posicionx: 0, posiciony: 0};                    
        var j = 0;

        while (j < self.nodes.length){
                //Buscamos el nodo a borrar.
                if (self.nodes[j].node == self.array.data[self.i].node){
                    //alert("borro el nodo  " + self.nodes[j].node + "  tamano nodo " + self.nodes.length + "posicion  "+ j );
                    self.nodes.splice(self.nodes.indexOf(self.nodes[j]),1);//borro el nodo - posicion y nº de nodos a borrar.
                    self.links.splice(self.links.indexOf(self.links[j]),1);//borro el link - posicion y nº de links a borrar.
                    //alert("tamano nodo " + self.nodes.length);
                    j=self.nodes.length;
                }   
            j++;
        }


        if (!a){
             self.nodes.push(d);
             self.links.push({source: d, target: d});
        }else 
            {
            //var c = self.nodes[1];
            var k = 0;
            while (k < self.nodes.length){

                if (self.nodes[k].parent == self.array.data[self.i].parent){
                        self.nodes.push(d);
                        self.links.push({source: d, target: self.nodes[k]});
                        k=self.nodes.length;
                }   
                k++;
            }
        }

        /* while (j < self.nodes.length){
            //Buscamos el nodo a borrar.
            if (self.nodes[j].node == self.array.data[self.i].node){

                //alert("borro el nodo  " + self.nodes[j].node + "  tamano nodo " + self.nodes.length + "posicion  "+ j );
                self.nodes[j].node
                //alert("nodo antes del cambio"+ self.nodes[j].id);
                self.nodes[j].t = self.array.data[self.i].t;
                self.nodes[j].ev = self.array.data[self.i].ev;
                self.nodes[j].who = self.array.data[self.i].who;
                self.nodes[j].node = self.array.data[self.i].node;
                self.nodes[j].parent = self.array.data[self.i].parent;

                self.node_modify = self.nodes[j]

                self.node_modify = self.nodes.indexOf(self.nodes[j]);
                j=self.nodes.length;

            }   
            j++;
        }*/

        self.identificador_nodos++;
        self.userstart();
        self.start_modify();

    },
    del : function(){

        var self = this;

        var j = 0;

        while (j < self.nodes.length){
                //Buscamos el nodo a borrar.
                if (self.nodes[j].node == self.array.data[self.i].node){
                    //alert("borro el nodo  " + self.nodes[j].node + "  tamano nodo " + self.nodes.length + "posicion  "+ j );
                    self.nodes.splice(self.nodes.indexOf(self.nodes[j]),1);//borro el nodo - posicion y nº de nodos a borrar.
                    self.links.splice(self.links.indexOf(self.links[j]),1);//borro el link - posicion y nº de links a borrar.
                    //alert("tamano nodo " + self.nodes.length);
                    j=self.nodes.length;
                }   
            j++;
        }

        self.userstart();
        self.start();
    },
    start : function(){

        var self = this;
        var color = 0;

        var col = 0;
            while (col <= self.nodes.length){

                if (self.nodes[col].parent == self.nodes[self.nodes.length-1].parent && self.nodes[col].node=="iniciales"){
                        color = self.nodes[col].color;
                        var color_brillo = self.getLuxColor(self.nodes[col].color,0.8);
                        self.nodes[self.nodes.length-1].color = self.nodes[col].color;


                        col=self.nodes.length;
                }   
                col++;
            }


        var Color_Nodos = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos.append("stop").attr("offset", "60%").attr("stop-color", color).attr("stop-opacity", 0.5); // Color red
        Color_Nodos.append("stop").attr("offset", "100%").attr("stop-color", color_brillo).attr("stop-opacity", 0).attr("brighter",1); // Color red aclarado + 4

        var Color_Texto_Nodos = self.svg.append("defs").append("radialGradient").attr("id", "Color_Texto_Nodos").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Texto_Nodos.append("stop").attr("offset", "0%").attr("stop-color", "#FF1919").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Texto_Nodos.append("stop").attr("offset", "60%").attr("stop-color", color).attr("stop-opacity", 0.5); // Color red
        Color_Texto_Nodos.append("stop").attr("offset", "100%").attr("stop-color", "#FF1919").attr("stop-opacity", 1).attr("brighter",1); // Color blanco
        
        self.node5 = self.node5.data(self.force.nodes(), function(d) { return d.id;});
        self.node5.enter().append("text").text(self.array.data[self.i].node).attr("fill","url(#Color_Texto_Nodos)").style("visibility", "hidden");
        self.node5.exit().remove();
       
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
        self.link.enter().insert("line", ".node").attr("class", "link");//.attr("stroke","green");
        self.link.exit().remove();

        self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
        self.node4.enter().append("text").text(function(d) { return d.node;}).attr("fill","url(#Verde)").transition().duration(self.timer).attr("fill","url(#Color_Texto_Nodos)").remove();
        self.node4.exit().remove();
      
        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 10).attr("fill","url(#Verde)")
                         .on('mouseover', function(d)
                         {
                            d3.select(this).transition()
                            .duration(750)
                            .attr("r", 55)
                            .attr("fill","url(#Amarillo)")
                            //.attr("fill-opacity",0.6);
                            self.node9.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(d.t).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+3).attr("fill","url(#Color_Texto_Nodos)").style("visibility", "visible");
                            self.node6.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(d.who).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+16).attr("fill","url(#Color_Texto_Nodos)").style("visibility", "visible");
                            self.node7.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(d.color).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+29).attr("fill","url(#Color_Texto_Nodos)").style("visibility", "visible");
                            self.node8.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(d.parent).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+42).attr("fill","url(#Color_Texto_Nodos)").style("visibility", "visible");
                            return self.node5.attr("fill","url(#Color_Texto_Nodos)").style("visibility", "visible");
                         })
                         .on("mouseout", function()
                         {
                         d3.select(this).transition()
                         .duration(750)
                         .attr("r", 10)
                         .attr("fill","url(#Color_Nodos)")
                         //.attr("fill-opacity",0.6);
                         self.node6.style("visibility", "hidden");
                         self.node7.style("visibility", "hidden");
                         self.node8.style("visibility", "hidden");
                         self.node9.style("visibility", "hidden");
                         return self.node5.attr("fill","url(#Color_Texto_Nodos)").style("visibility", "hidden");//})
                         })
                         .call(self.force.drag)
                         .transition().duration(self.timer).attr("fill","url(#Color_Nodos)");//.attr("fill-opacity",0.6);
        self.node.exit().remove();

        self.force.start();


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
    start_modify : function(){

        var self = this;

        self.node5 = self.node5.data(self.force.nodes(), function(d) { return d.id;});
        self.node5.enter().append("text").text(self.array.data[self.i].node).attr("fill","url(#Color_Texto_Nodos)").style("visibility", "hidden");
        self.node5.exit().remove();
       
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
        self.link.enter().insert("line", ".node").attr("class", "link");//.attr("stroke","green");
        self.link.exit().remove();

        self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
        self.node4.enter().append("text").text(function(d) { return d.node;}).attr("fill","url(#Verde)").transition().duration(self.timer).attr("fill","url(#Color_Texto_Nodos)").remove();
        self.node4.exit().remove();
      
        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 10).attr("fill","url(#Verde)")
                         .on('mouseover', function(d)
                         {
                            d3.select(this).transition()
                            .duration(750)
                            .attr("r", 55)
                            .attr("fill","url(#Amarillo)")
                            //.attr("fill-opacity",0.6);
                            self.node9.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(d.t).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+3).attr("fill","url(#Color_Texto_Nodos)").style("visibility", "visible");
                            self.node6.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(d.ev).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+16).attr("fill","url(#Color_Texto_Nodos)").style("visibility", "visible");
                            self.node7.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(d.who).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+29).attr("fill","url(#Color_Texto_Nodos)").style("visibility", "visible");
                            self.node8.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(d.parent).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+42).attr("fill","url(#Color_Texto_Nodos)").style("visibility", "visible");
                            return self.node5.attr("fill","url(#Color_Texto_Nodos)").style("visibility", "visible");
                         })
                         .on("mouseout", function()
                         {
                         d3.select(this).transition()
                         .duration(750)
                         .attr("r", 10)
                         .attr("fill","url(#Color_Nodos)")
                         //.attr("fill-opacity",0.6);
                         self.node6.style("visibility", "hidden");
                         self.node7.style("visibility", "hidden");
                         self.node8.style("visibility", "hidden");
                         self.node9.style("visibility", "hidden");
                         return self.node5.attr("fill","url(#Color_Texto_Nodos)").style("visibility", "hidden");//})
                         })
                         .call(self.force.drag)
                         .transition().duration(self.timer).attr("fill","url(#Verde)");//.attr("fill-opacity",0.6);
        self.node.exit().remove();

        self.force.start();


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
    userstart : function(){
        
        var self = this;

        //var randomValuex = Math.random()*200;
        //var randomValuey = Math.random()*200;

        //quitamos esto para quitar la linea de link2
        self.link2 = self.link2.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link2.enter().insert("line", ".node").attr("stroke","url(#Amarillo)").attr().attr("stroke-opacity",0.6).attr("stroke-width", 6).attr("class", "link");       
        self.link2.exit().remove();

        self.node2 = self.node2.data(self.force.nodes(), function(d) { return d.id;});
        self.node2.enter().append("png:image").attr("xlink:href", "/static/images/user_min.png").attr("width", 20).attr("height", 20);
        self.node2.exit().remove();

        self.node3 = self.node3.data(self.force.nodes(), function(d) { return d.id;});
        self.node3.enter().append("text").text(self.array.data[self.i].who).attr("fill","#00CCFF");
        self.node3.exit().remove();

    }, 
    tick : function(){

        var self = this;

        self.origen= self.origen-1;
        //alert("llego aqui");

        self.node.attr("cx", function(d) { self.nodes[self.nodes.length-1].posicionx= d.x; return d.x; })
            .attr("cy", function(d) { self.nodes[self.nodes.length-1].posiciony= d.y; return d.y; })

        self.node4.attr("x", function(d) { return d.x-10; })
            .attr("y", function(d) { return d.y-10; })

        self.node5.attr("x", function(d) { return d.x-10; })
            .attr("y", function(d) { return d.y-10; })

        self.texto_nodos_iniciales.attr('x',function(d){ return (d.source.x+d.target.x)/2;})
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

        //self.pintar_usuario();

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
    },
    pintar_usuario : function(){

        //console.log(self.timer);
        var self = this;
        //alert ("el nodo 2 es  "+self.node2.who);
        var aleatorio_x = Math.random();
        var aleatorio_y = Math.random();

        self.node2_copia
            .transition()//.duration(self.timer)
            .ease("elastic")
            .remove();
        self.node2_copia.exit().remove();

        self.node3_copia
            .transition()//.duration(self.timer)
            .ease("elastic")
            .remove();
        self.node3_copia.exit().remove();
      
    },    
    datos : function(array) {
        
        var self = this;
           
        Baseliner.ajaxEval('/controllerlogdiego/leer_log/', { }, function(res){
           
        self.array = res;
               //alert("llego aqui"+ self.array.data[0].ev);
               console.log(self.array);

        });
    },
    getLuxColor : function(hex,lum) {

        // validate hex string
        hex = String(hex).replace(/[^0-9a-f]/gi, '');
        if (hex.length < 6) {
            hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2];
        }
        lum = lum || 0;

        // convert to decimal and change luminosity
        var rgb = "#", c, i;
        for (i = 0; i < 3; i++) {
            c = parseInt(hex.substr(i*2,2), 16);
            c = Math.round(Math.min(Math.max(0, c + (c * lum)), 255)).toString(16);
            rgb += ("00"+c).substr(c.length);
        }

    //alert(rgb);
    return rgb;
    },
    getRandomColor : function() {
    
        var letters = '0123456789ABCDEF'.split('');
        var color = '#';
        for (var i = 0; i < 6; i++ ) {
            color += letters[Math.floor(Math.random() * 16)];
        }

    //alert(color);
    return color;
    }
});