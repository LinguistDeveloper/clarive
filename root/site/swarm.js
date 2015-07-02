Cla.Swarm = Ext.extend( Ext.Panel, {
    
    background_color: '#FFFFFF',
    start_mode: 'manual',



    //limit: '20000',


    initComponent : function(){

        var self = this;
        
        //self.cuenta = 0;
        self.res = { data:[] };
        self.parents =  {};
        self.i=0;
        self.j=0;
        //self.contador=1000;
        self.days = 31536000000;
        self.color=0;
        self.colores = ["#86ECFF", "#A3A5A8", "#B900BF", "#BF932D", "#55FF64", "#FA0200", "#FFFF00", "#FF7C54", "#0003E8", "#FF2E99", "#16FCFF"];
        self.opuesto = self.invertir_Color(self.background_color);
        self.cambio_realtime = true;


        self.colores_usuarios=[];
        self.usuarios_colores=[];
        //EL CONTROL DE PINTAR SOLO ES VALIDO PARA COLORES DE 0 A 9.
        self.pintar=0;
        self.nodos_modificados=[];
        self.contador_modificado=0;


        self.date = new Date();
        self.fecha_fin = new Date();
        //self.origen=0;

        self.btn_start = new Ext.Button({ icon: IC('start'), disabled: false, handler: function(){ self.start_anim();} });
        self.btn_pause = new Ext.Button({ icon: IC('pause.gif'), disabled: true, handler: function(){ self.pause_anim() } });
        self.btn_stop = new Ext.Button({ icon: IC('stop'), disabled: true, handler: function(){ self.stop_anim() } });

        self.scale_bar = new Ext.Button({ text:'Scale Time', icon: IC('scaleTime'), disabled: false, 
            menu : {
                items: [{
                    text: 'Today', handler: function(){ self.get_days(0) } 
                }, {
                    text: '2D', handler: function(){ self.get_days(2) } 
                }, {
                    text: '7D', handler: function(){ self.get_days(7) } 
                }, {
                    text: '1M', handler: function(){ self.get_days(30) } 
                }, {
                    text: '3M', handler: function(){ self.get_days(90) } 
                }, {
                    text: '6M', handler: function(){ self.get_days(180) } 
                }]
            },
            //handler: function(){ self.start_anim() } 
        });

        self.slider = new Ext.Slider({
            width: 100,
            increment: 1,
            value: 5,
            minValue: 0,
            maxValue: 10,
            plugins: new Ext.slider.Tip(),
        });

        self.slidertime = new Ext.Slider({
            width: 40,
            increment: 1,
            value: 0,
            minValue: 0,
            maxValue: 1,
            plugins: new Ext.slider.Tip(),
        });


        self.bbar = [ 
        self.btn_start, 
        self.btn_pause, 
        self.btn_stop, 
        {xtype: 'tbfill'}, 
        //{ xtype: 'tbspacer', width: 100 },
        {xtype: 'tbtext', text: 'Speed', style : "color:#0066FF;font-style:italic;font-family: tahoma, arial, verdana, sans-serif;font-size: 11px;"}, 
        { xtype: 'tbspacer', width: 10 },
        {xtype: 'tbtext', text: '-', style : "color:#0066FF;font-style:italic;font-family: tahoma, arial, verdana, sans-serif;font-size: 11px;"},
        { xtype: 'tbspacer', width: 10 },
        self.slider, 
        { xtype: 'tbspacer', width: 10 },
        {xtype: 'tbtext', text:' +', style : "color:#0066FF;font-style:italic;font-family: tahoma, arial, verdana, sans-serif;font-size: 11px;"}, 
        //{xtype: 'tbtext', text: '|     |', style : "color:#000000;font-style:arial;font-size: 11px;"}, 
        { xtype: 'tbspacer', width: 100 },
        {xtype: 'tbtext', text: 'Event Driven ', style : "color:#FF0000;font-style:italic;font-family: tahoma, arial, verdana, sans-serif;font-size: 11px;"}, 
        { xtype: 'tbspacer', width: 10 },
        self.slidertime, 
        { xtype: 'tbspacer', width: 10 },
        {xtype: 'tbtext', text: ' Real Time', style : "color:#009933;font-style:italic;font-family: tahoma, arial, verdana, sans-serif;font-size: 11px;"},
        { xtype: 'tbspacer', width: 100 },
        //{xtype: 'tbtext', text: '|     |', style : "color:#000000;font-style:arial;font-size: 11px;"}, 
        self.scale_bar,
        { xtype: 'tbspacer', width: 25 },
        ];

        Cla.Swarm.superclass.initComponent.call(this);
         
        self.on('resize', function(p,w,h){
            if( self.svg ) {
            }
        });

        self.on('afterrender', function(){
            self.init();
            if( self.start_mode == 'auto' ) { self.start_anim(); }
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
            //".node": { "stroke": "#fff", fill:"#000", 'stroke-width': '1.5px' }
        });

        var id = self.body.id; 
        var selector = '#' + id; 

        self.vis = d3.select("#"+ id ).append("svg:svg").attr("width", '100%').attr("height", '100%').style("background-color", self.background_color).attr("preserveAspectRatio", "xMinYMin meet");
        //.append("text").text("HOLA ESTOY PROBANDO").attr("fill","#00CCFF");
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
            .charge(-80)
            .friction(.6)
            .linkDistance(     
                function(lnk){
                    return lnk.target.node=='iniciales' || lnk.target.node=='iniciales'  ? 1 : 80;
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


        //color = self.nodes[col].color;
        //var color_brillo = self.getLuxColor(self.nodes[col].color,0.8);
  
        //COLORES DE LOS NODOS  

        var Color_Nodos_Raiz = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos_Raiz").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos_Raiz.append("stop").attr("offset", "0%").attr("stop-color", self.opuesto).attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos_Raiz.append("stop").attr("offset", "60%").attr("stop-color", "#4682B4").attr("stop-opacity", 0.5); // Color steelblue
        Color_Nodos_Raiz.append("stop").attr("offset", "100%").attr("stop-color", "#90B4D2").attr("stop-opacity", 0).attr("brighter",1); // Color steelblue aclarado + 4

        var Color_texto_Raiz = self.svg.append("defs").append("linearGradient").attr("id", "Color_texto_Raiz").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_texto_Raiz.append("stop").attr("offset", "0%").attr("stop-color", self.opuesto).attr("stop-opacity", 1); //Luminosidad color blanco
        Color_texto_Raiz.append("stop").attr("offset", "60%").attr("stop-color", "#4682B4").attr("stop-opacity", 0.5); // Color steelblue
        Color_texto_Raiz.append("stop").attr("offset", "100%").attr("stop-color", self.opuesto).attr("stop-opacity", 1).attr("brighter",1); // Color blanco

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

        var Color_Nodos_Rojo = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos_Rojo").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos_Rojo.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos_Rojo.append("stop").attr("offset", "60%").attr("stop-color", "#FF0000").attr("stop-opacity", 0.5); // Color red
        Color_Nodos_Rojo.append("stop").attr("offset", "100%").attr("stop-color", "#FF6666").attr("stop-opacity", 0).attr("brighter",1); // Color red aclarado + 4

        var Color_Texto_Nodos_Rojo = self.svg.append("defs").append("radialGradient").attr("id", "Color_Texto_Nodos_Rojo").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Texto_Nodos_Rojo.append("stop").attr("offset", "0%").attr("stop-color", "#FF1919").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Texto_Nodos_Rojo.append("stop").attr("offset", "60%").attr("stop-color", "#FF0000").attr("stop-opacity", 0.5); // Color red
        Color_Texto_Nodos_Rojo.append("stop").attr("offset", "100%").attr("stop-color", "#FF1919").attr("stop-opacity", 1).attr("brighter",1); // Color blanco

        var Color_Nodos_Verde = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos_Verde").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos_Verde.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos_Verde.append("stop").attr("offset", "60%").attr("stop-color", "#008000").attr("stop-opacity", 0.5); // Color GREEN
        Color_Nodos_Verde.append("stop").attr("offset", "100%").attr("stop-color", "#66B366").attr("stop-opacity", 0).attr("brighter",1); // Color red aclarado + 4

        var Color_Texto_Nodos_Verde = self.svg.append("defs").append("radialGradient").attr("id", "Color_Texto_Nodos_Verde").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Texto_Nodos_Verde.append("stop").attr("offset", "0%").attr("stop-color", "#198D19").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Texto_Nodos_Verde.append("stop").attr("offset", "60%").attr("stop-color", "#008000").attr("stop-opacity", 0.5); // Color GREEN
        Color_Texto_Nodos_Verde.append("stop").attr("offset", "100%").attr("stop-color", "#198D19").attr("stop-opacity", 1).attr("brighter",1); // Color blanco

        var Color_Nodos_Morado = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos_Morado").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos_Morado.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos_Morado.append("stop").attr("offset", "60%").attr("stop-color", "#D1A3D1").attr("stop-opacity", 0.5); // Color MORADO
        Color_Nodos_Morado.append("stop").attr("offset", "100%").attr("stop-color", "#E3C8E3").attr("stop-opacity", 0).attr("brighter",1); // Color red aclarado + 4

        var Color_Texto_Nodos_Morado = self.svg.append("defs").append("radialGradient").attr("id", "Color_Texto_Nodos_Morado").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Texto_Nodos_Morado.append("stop").attr("offset", "0%").attr("stop-color", "#D6ACD6").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Texto_Nodos_Morado.append("stop").attr("offset", "60%").attr("stop-color", "#D1A3D1").attr("stop-opacity", 0.5); // Color MORADO
        Color_Texto_Nodos_Morado.append("stop").attr("offset", "100%").attr("stop-color", "#D6ACD6").attr("stop-opacity", 1).attr("brighter",1); // Color blanco

        var Color_Nodos_Marron = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos_Marron").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos_Marron.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos_Marron.append("stop").attr("offset", "60%").attr("stop-color", "#D1A3D1").attr("stop-opacity", 0.5); // Color MORADO
        Color_Nodos_Marron.append("stop").attr("offset", "100%").attr("stop-color", "#E3C8E3").attr("stop-opacity", 0).attr("brighter",1); // Color red aclarado + 4

        var Color_Texto_Nodos_Marron = self.svg.append("defs").append("radialGradient").attr("id", "Color_Texto_Nodos_Marron").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Texto_Nodos_Marron.append("stop").attr("offset", "0%").attr("stop-color", "#D6ACD6").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Texto_Nodos_Marron.append("stop").attr("offset", "60%").attr("stop-color", "#D1A3D1").attr("stop-opacity", 0.5); // Color MORADO
        Color_Texto_Nodos_Marron.append("stop").attr("offset", "100%").attr("stop-color", "#D6ACD6").attr("stop-opacity", 1).attr("brighter",1); // Color blanco

        var Color_Nodos_Azul = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos_Azul").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos_Azul.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos_Azul.append("stop").attr("offset", "60%").attr("stop-color", "#0066FF").attr("stop-opacity", 0.5); // Color MORADO
        Color_Nodos_Azul.append("stop").attr("offset", "100%").attr("stop-color", "#66A3FF").attr("stop-opacity", 0).attr("brighter",1); // Color red aclarado + 4

        var Color_Texto_Nodos_Azul = self.svg.append("defs").append("radialGradient").attr("id", "Color_Texto_Nodos_Azul").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Texto_Nodos_Azul.append("stop").attr("offset", "0%").attr("stop-color", "#1975FF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Texto_Nodos_Azul.append("stop").attr("offset", "60%").attr("stop-color", "#0066FF").attr("stop-opacity", 0.5); // Color MORADO
        Color_Texto_Nodos_Azul.append("stop").attr("offset", "100%").attr("stop-color", "#1975FF").attr("stop-opacity", 1).attr("brighter",1); // Color blanco

        var Color_Nodos_AzulOscuro = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos_AzulOscuro").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos_AzulOscuro.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos_AzulOscuro.append("stop").attr("offset", "60%").attr("stop-color", "#003366").attr("stop-opacity", 0.5); // Color MORADO
        Color_Nodos_AzulOscuro.append("stop").attr("offset", "100%").attr("stop-color", "#6685A3").attr("stop-opacity", 0).attr("brighter",1); // Color red aclarado + 4

        var Color_Texto_Nodos_AzulOscuro = self.svg.append("defs").append("radialGradient").attr("id", "Color_Texto_Nodos_AzulOscuro").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Texto_Nodos_AzulOscuro.append("stop").attr("offset", "0%").attr("stop-color", "#194775").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Texto_Nodos_AzulOscuro.append("stop").attr("offset", "60%").attr("stop-color", "#003366").attr("stop-opacity", 0.5); // Color MORADO
        Color_Texto_Nodos_AzulOscuro.append("stop").attr("offset", "100%").attr("stop-color", "#194775").attr("stop-opacity", 1).attr("brighter",1); // Color blanco

        var Color_Nodos_Amarillo = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos_Amarillo").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos_Amarillo.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos_Amarillo.append("stop").attr("offset", "60%").attr("stop-color", "#FF9900").attr("stop-opacity", 0.5); // Color MORADO
        Color_Nodos_Amarillo.append("stop").attr("offset", "100%").attr("stop-color", "#FFC266").attr("stop-opacity", 0).attr("brighter",1); // Color red aclarado + 4

        var Color_Texto_Nodos_Amarillo = self.svg.append("defs").append("radialGradient").attr("id", "Color_Texto_Nodos_Amarillo").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Texto_Nodos_Amarillo.append("stop").attr("offset", "0%").attr("stop-color", "#FFA319").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Texto_Nodos_Amarillo.append("stop").attr("offset", "60%").attr("stop-color", "#FF9900").attr("stop-opacity", 0.5); // Color MORADO
        Color_Texto_Nodos_Amarillo.append("stop").attr("offset", "100%").attr("stop-color", "#FFA319").attr("stop-opacity", 1).attr("brighter",1); // Color blanco

        var Color_Nodos_MoradoOscuro = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos_MoradoOscuro").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos_MoradoOscuro.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos_MoradoOscuro.append("stop").attr("offset", "60%").attr("stop-color", "#660066").attr("stop-opacity", 0.5); // Color MORADO
        Color_Nodos_MoradoOscuro.append("stop").attr("offset", "100%").attr("stop-color", "#A366A3").attr("stop-opacity", 0).attr("brighter",1); // Color red aclarado + 4

        var Color_Texto_Nodos_MoradoOscuro = self.svg.append("defs").append("radialGradient").attr("id", "Color_Texto_Nodos_MoradoOscuro").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Texto_Nodos_MoradoOscuro.append("stop").attr("offset", "0%").attr("stop-color", "#751975").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Texto_Nodos_MoradoOscuro.append("stop").attr("offset", "60%").attr("stop-color", "#660066").attr("stop-opacity", 0.5); // Color MORADO
        Color_Texto_Nodos_MoradoOscuro.append("stop").attr("offset", "100%").attr("stop-color", "#751975").attr("stop-opacity", 1).attr("brighter",1); // Color blanco

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
console.log("Stating anim");

        var self = this;


        if(self.i==0){

            //alert(self.days);

            self.data_load(0);

        }else{

            if( !self.initiated ) {
                //alert("inicializa");
                self.first();
                self.initiated = true;
            }

            self.anim_running = true;
            self.btn_start.disable();
            self.btn_pause.enable();
            self.btn_stop.enable();
            setTimeout(function(){ self.anim(); }, (10-self.slider.getValue())*100 );

        }


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
        self.force.stop();
        self.i = self.res.skip;
    },
    reset_all : function() {
        var self = this;
        self.i=0;
        self.res.skip = 0;
        self.j = 0;
        self.initiated=false;

        self.anim_running = false;
        self.parents =  {};
        self.nodes = [];
        self.links = [];
        self.nodos_modificados = [];

        self.node.remove();
        self.link.remove();
        self.link2.remove();
        self.node2.remove();
        self.node3.remove();
        self.node4.remove();
        self.node5.remove();
        self.node6.remove();
        self.node7.remove();
        self.node8.remove();
        self.node9.remove();
        self.texto.remove();
        self.force.stop();
        self.vis.remove();

    },
    anim : function(limit){

        var self = this;

        if( !self.anim_running ) {
console.log("Not running");
            return;
        }

        if ( self.i >= self.res.skip) {
            self.data_load(self.res.skip);
            self.j = 0;
console.log("Saltando al siguiente batch: " + self.res.skip);
            return;
        }

        // if(self.i==self.res.data.length){
        if(self.i >= self.res.total){
            self.reset_all();
console.log("Finished animation");
            self.init();
            self.start_anim();
            return;
        }
        
        var row = self.res.data[ self.j++ ];
        self.i++;


        if( !row ) {
            // no more rows? stop animation
            self.stop_anim();
            return;
        }
        row.id = Ext.id();


        var next_timer = (10-self.slider.getValue())*100;  
        //self.calculo_horas();

        if(self.slidertime.getValue()==0){
            //#########################################################################
            //PARTE PARA QUE PUEDA SOLO SALGAN LOS NODOS 
            //#########################################################################
            self.cambio_realtime=true;

            if( row.parent ) {
                if( !self.parents[row.parent] ) {

                    self.parents[row.parent] = true;
                    self.add_inicial( row.parent );
                    var row = self.res.data[ self.j-- ];
                    self.i++;

                }else{
                    
                     //console.log(self.nodes.length);
                    self.comprobar_timer_usuario(row);
                    self.comprobar_timer_nodo();

                    if(self.nodos_modificados.length >= 2){

                    self.comprobar_nodo_modificado(); 

                    }else if(row.ev == 'add') {

                        self.add(row);

                    }else if(row.ev == 'mod') {

                        self.modify(row);

                    }else if(row.ev == 'del'){

                        self.del(row);

                    }

                }
            }
            //#########################################################################
            //#########################################################################
            //#########################################################################
        }else{
            //#########################################################################
            //PARTE PARA QUE PUEDA SALIR CON LA FUNCION REALTIME
            //#########################################################################
            
            if(self.cambio_realtime){

                self.date=row.t;
                self.cambio_realtime=false;

            }
            //alert(row.t+" la fecha nodo y la fecha normal  "+self.date);
            if(row.t==self.date){
                //alert("entro aqui");
                if( row.parent ) {
                    if( !self.parents[row.parent] ) {

                        self.parents[row.parent] = true;
                        self.add_inicial( row.parent );
                        var row = self.res.data[ self.j-- ];
                        self.i--;

                    }else{

                        self.comprobar_timer_usuario(row);
                        self.comprobar_timer_nodo();

                        if(self.nodos_modificados.length >= 2){

                        self.comprobar_nodo_modificado(); 

                        }else if(row.ev == 'add') {        

                            self.add(row);

                        }else if(row.ev == 'mod') {

                            self.modify(row);

                        }else if(row.ev == 'del'){

                            self.del(row);

                        }

                    }
                }
            }else{

                var row = self.res.data[ self.j-- ];
                self.i--;


                var date = new Date(self.date);

                //CAMBIO TODO ESTO POR....
                /*var calculo = self.calcula_contador(date);
                calculo = new Date(calculo);
                self.date = self.calcular_fecha(calculo);*/

                //TODO ESTO...........

                var seconds = date.getSeconds()+1;
                var minutes = date.getMinutes()
                var hour = date.getHours();
                var day = date.getDate();
                var month = date.getMonth();
                var year = date.getFullYear();
                var fecha;

                if (seconds > 59){
                    seconds = '00';
                    minutes = minutes+1;


                    if (minutes > 59){
                        minutes = '00';
                        hour = hour+1;
                        if(date.getHours()>=23){
                            hour = '00';
                            day = date.getDate()+1;
                            if(date.getDate()>=30){
                                if(date.getDate()==31 && (date.getMonth()==0 || date.getMonth()==2 || date.getMonth()==4 || date.getMonth()==6 || date.getMonth()==7 || date.getMonth()==9 || date.getMonth()==11)){
                                   day = '01';
                                   month = date.getMonth()+1; 
                                    if(date.getMonth()>=11){
                                        month = 00;
                                        year= date.getFullYear()+1;
                                    }
                                }else{
                                    day = '01';
                                    month = date.getMonth()+1;
                                    if(date.getMonth()>=11){
                                        month = 00;
                                        year= date.getFullYear()+1;
                                    }
                                }
                            }else if (date.getDate()==28 && date.getMonth()==1){
                                day = '01';
                                month = date.getMonth()+1;
                                if(date.getMonth()>=11){
                                    month = 00;
                                    year= date.getFullYear()+1;
                                }
                            }
                        }
                    }
                }
                fecha = year+"-"+(month+1)+"-"+day+" "+hour+":"+minutes+":"+seconds;

                date = new Date(fecha);

                if(date.getDate() < 10){
                    day = "0"+date.getDate();
                }else{day = date.getDate();}

                if(date.getMonth() < 9){
                    month = "0"+(date.getMonth()+1);
                }else{month = date.getMonth()+1;}

                if(date.getHours() < 10){
                    hour = "0"+date.getHours();
                }else{hour = date.getHours();}

                if(date.getMinutes() < 10){
                    minutes = "0"+date.getMinutes();
                }else{minutes = date.getMinutes();}

                if(date.getSeconds() < 10){
                    seconds = "0"+date.getSeconds();
                }else{seconds = date.getSeconds();}

                self.date = date.getFullYear()+"-"+month+"-"+day+" "+hour+":"+minutes+":"+seconds;

                //...........................................................................................................
                //...........................................................................................................
                //...........................................................................................................

                //////////////////////////////////////////
                //var d = new Date();                   
                //d.setDate(d.getDate() + 0.00000578);  
                //self.date = d;                        
                //////////////////////////////////////////

                /*self.vis.append("text")
                        .text("dafefde")//.text(self.get_contador())//.text(self.res.data[0].t)
                        .attr("fill","#ffffff")
                        .attr("x", '45%')
                        .attr("y", '5%').transition().duration(10).remove();*/
                self.force.start();

            }
            //#########################################################################
            //#########################################################################
            //#########################################################################
        }
        setTimeout(function(){ self.anim() }, next_timer);
    },
    first : function(){

        var self = this;

        var a = { id: "9999" , node: "raiz"}
        self.nodes.push(a);

        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        //quitamos la parte de el nodo para que no aparezca, solo definimos el elemento circulo
        self.node.enter().append("circle").attr("r",0);//.attr("class", function(d) { return "node " + d.id; }).attr("r", 6).attr('fill','red').on("zoom", function(){self.rescale()});
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

        }else{

            self.nodes.push(d);
            self.links.push({source: d, target: a});

            }
        
        self.start_inicial();

    },
    start_inicial : function(){

        var self = this;

        if (self.background_color == '#000000'){
            
            self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
            self.link.enter().insert("line", ".node").attr("class", "link").attr("stroke","#FFFFFF");
            self.link.exit().remove();

            self.texto = self.texto.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });   
            self.texto.enter().append('text').attr("fill","#FFFFFF").text(function(d) { return d.source.parent;});   

            self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
            self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 10).attr("fill","#FFFFFF").attr("fill-opacity",0.4).on("zoom", function(){self.rescale()});
            self.node.exit().remove();

        }
        if (self.background_color == '#FFFFFF'){
            
            self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
            self.link.enter().insert("line", ".node").attr("class", "link").attr("stroke","#000000");
            self.link.exit().remove();

            self.texto = self.texto.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });   
            self.texto.enter().append('text').attr("fill","#000000").text(function(d) { return d.source.parent;});   

            self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
            self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 10).attr("fill","#000000").attr("fill-opacity",0.4).on("zoom", function(){self.rescale()});
            self.node.exit().remove();
        }

        if(self.background_color != "#000000" || self.background_color != "#FFFFFF") {

            self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
            self.link.enter().insert("line", ".node").attr("class", "link").attr("stroke", self.opuesto);
            self.link.exit().remove();

            self.texto = self.texto.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });   
            self.texto.enter().append('text').attr("fill",self.opuesto).text(function(d) { return d.source.parent;});   

            self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
            self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 10).attr("fill",self.opuesto).attr("fill-opacity",0.4).on("zoom", function(){self.rescale()});
            self.node.exit().remove();

        }

            self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
            self.node4.enter().append("text");//.text(function(d) { return d.node;}).attr("fill",self.background_color);
            self.node4.exit().remove();

            self.node5 = self.node5.data(self.force.nodes(), function(d) { return d.id;});
            self.node5.enter().append("text");//.text(function(d) { return d.node;}).attr("fill",self.background_color);
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
    add : function(row){

        var self = this;

        var a = self.nodes[0];
        var d = row; //{id: self.i, node:  row.parent};

        var timer = (10-self.slider.getValue())*100;  // TODO calculate from previous and next events

        if (!a){

             self.nodes.push(row);
             self.date = row.t;
             self.links.push({source: row, target: row});

        }else {

            var j = 0;
            while (j < self.nodes.length){

                if (self.nodes[j].parent ==  row.parent && self.nodes[j].node == "iniciales"){
                   
                    self.nodes.push(row);
                    self.date = row.t;
                    self.links.push({source: row, target: self.nodes[j]});
                    
                    j=self.nodes.length;

                } 

                j++;

            }

            self.start({ row: row, timer: timer });
            self.add_user(row);

        }
    },
    modify : function(row){

        var self = this;

        var a = self.nodes[0];
        var d = row; //{id: self.i, node:  row.parent};

        var timer = (10-self.slider.getValue())*100;  // TODO calculate from previous and next events

        var j = 0;

        while (j < self.nodes.length){
                //Buscamos el nodo a borrar.

                if (self.nodes[j].node == row.node){

                    self.nodes.splice(self.nodes.indexOf(self.nodes[j]),1);//borro el nodo - posicion y nº de nodos a borrar.

                    var z=0;
                    while(z < self.links.length){

                        if(self.links[z].source.node==row.node && (self.links[z].source.node != 'iniciales' || self.links[z].source.node != 'usuarios')){
                            
                            self.links.splice(self.links.indexOf(self.links[z]),1);
                            z=self.links.length;

                        }

                    z++;

                    }

                    j=self.nodes.length;

                }   

            j++;

        }

        if (!a){

            self.nodes.push(row);
            self.date = row.t;
            self.links.push({source: row, target: row});

        }else {

            var j = 0;
            while (j < self.nodes.length){

                if (self.nodes[j].parent ==  row.parent && self.nodes[j].node == "iniciales"){

                        self.nodes.push(row);
                        self.date = row.t;
                        self.links.push({source: row, target: self.nodes[j]});

                        //CONTADOR PARA SABER QUE NODOS SE HAN MODIFICADO. LO UTILIZAREMOS EN EL COMPROBAR NODO MODIFICADO
                        if(!self.nodos_modificados[0]){ 

                            self.nodos_modificados.push(row);

                        }else{

                            var contador = 0;

                            for (y=0;y<self.nodos_modificados.length;y++){

                                if (row.node == self.nodos_modificados[y].node){
                                    contador++;
                                }
                            }

                            if (contador==0){self.nodos_modificados.push(row);}

                        }
                        
                        j=self.nodes.length;

                }   

                j++;

            }

            self.start_modify({ row: row, timer: timer });
            self.add_user(row);

        }
    },     
    del : function(row){

        var self = this;


        var a = self.nodes[0];
        var d = row; //{id: self.i, node:  row.parent};

        if (!a){

            self.nodes.push(row);
            self.date = row.t;
            self.links.push({source: row, target: row});

        }else {

            //var c = self.nodes[1];
            var i = 0;
            while (j < self.nodes.length){

                if (self.nodes[i].parent ==  row.parent && self.nodes[i].node == "iniciales"){

                        self.nodes.push(row);
                        self.date = row.t;
                        self.links.push({source: row, target: self.nodes[i]});
                        
                        j=self.nodes.length;

                }   

                j++;

            }

        }

        var j = 0;

        while (j < self.nodes.length){
                //Buscamos el nodo a borrar.
                if (self.nodes[j].node == row.node){

                    self.nodes.splice(self.nodes.indexOf(self.nodes[j]),1);//borro el nodo - posicion y nº de nodos a borrar.

                    var z=0;
                    while(z < self.links.length){
                        if(self.links[z].source.node==row.node && (self.links[z].source.node != 'iniciales' || self.links[z].source.node != 'usuarios')){
                            self.links.splice(self.links.indexOf(self.links[z]),1);
                            z=self.links.length;
                        }
                    z++;
                    }

                    j=self.nodes.length;
                }   

            j++;
        }

        self.userstart(row);
        self.start({ row: row, timer: (10-self.slider.getValue())*100 });
    },
    add_user : function(row){

        var self = this;

        var a = self.nodes[0];

        var d = { id: "#u"+Math.random(), t: 1, ev: "usuarios", who: row.who, node: "usuarios", parent: "usuarios", color: "aaa" };

        //alert ("entro en el add user "+row.who);

        if (!a){

             self.nodes.push(d);
             self.links.push({source: d, target: row});

        }else {

            var j = 0;
            while (j < self.nodes.length){
                    //alert("llega al while usuario "+d.who +"  el row es  "+row.who + " el usuario  "+self.nodes[j].node);
                if (self.nodes[j].who ==  row.who && self.nodes[j].node == "usuarios"){

                        self.nodes[j].t = 5;//Reinicia el timer del usuario cuando crea un nodo
                        var i = 0;
                        while(i < self.links.length){
                            if(self.links[i].source.who == row.who && self.links[i].source.node == "usuarios"){

                                self.links.splice(self.links.indexOf(self.links[i]),1);
                                i=self.links.length;

                            } 
                            i++;
                        }

                        self.links.push({source: self.nodes[j], target: row });
                        j=self.nodes.length;

                }

                j++;

            }






















































            if(j==self.nodes.length){

                var i = "no activo";
                if(self.colores_usuarios.length == 0){

                    d.color= "/static/images/USER_"+0+".png";
                    self.color=0;
                    self.usuarios_colores.push(row.who);
                    self.colores_usuarios.push(d.color);

                }else{
                    for(j=0; j<self.usuarios_colores.length; j++){

                        if(row.who==self.usuarios_colores[j]){

                            d.color= self.colores_usuarios[j];
                            self.pintar =self.colores_usuarios[j].substr(20,1);
                            i="activo";
                            j=self.usuarios_colores.length;

                        }
                    }
                    if(i != "activo"){

                            self.color++;
                            d.color= "/static/images/USER_"+(self.color)+".png";
                            self.pintar=self.color;
                            self.usuarios_colores.push(row.who);
                            self.colores_usuarios.push(d.color);

                    }
                }

                if(self.color==9){self.color=0;}
                self.nodes.push(d);
                self.links.push({source: d, target: row });

            }      

        }
        self.userstart(d);
    },
    comprobar_timer_usuario : function(row){

        var self = this;

        var j = 0;

        while (j < self.nodes.length){

            if (self.nodes[j].node == "usuarios"){
                        
                    self.nodes[j].t = self.nodes[j].t-1;
                    if(self.nodes[j].t == 0){

                        //alert("borro el nodo "+self.nodes[j].who);

                        var i = 0;
                        while(i < self.links.length){
                                if(self.links[i].source.who == self.nodes[j].who && self.links[i].source.node == "usuarios"){

                                    self.links.splice(self.links.indexOf(self.links[i]),1);
                                    i=self.links.length;

                                } 

                                i++;

                        }

                    }
                    if(self.nodes[j].t < 0 ){

                        var i=0;
                        var contador=0;
                        while(i < self.nodes.length){
                            if(self.nodes[i].node == row.node){
                                contador++;
                            }
                            i++;
                        }
                        if (contador==0 && self.nodes[j].who != row.who){

                            self.nodes.splice(self.nodes.indexOf(self.nodes[j]),1); 
                            j=self.nodes.length;

                        }
                        
                    }
            }

            j++;

        }

        self.force.start();

    },
    comprobar_timer_nodo : function(){

        var self = this;

        var j = 0;








              













        var contador =0;

        //500 ES EL MAXIMO DE NODOS QUE PUEDE HABER EN LA PANTALLA PINTADOS.
        if(self.nodes.length > 500){
            while (j < self.nodes.length){

                for (h=1; h< self.nodes.length; h++){

                    if(self.nodes[j].parent==self.nodes[h].parent){
                        contador++;
                    }
                    //AQUI EL CONTADOR NOS DA EL NUMERO MINIMO DE NODOS POR CATEGORIA
                    if (self.nodes[j].node != "usuarios" && self.nodes[j].node != "iniciales" && self.nodes[j].node != "raiz" && contador > 7){

                        //alert("entro aqui"+ self.nodes.length);
                   
                        var i = 0;
                        while(i < self.links.length){
                                if(self.links[i].source.who == self.nodes[j].who && self.links[i].source.node == "usuarios"){

                                    self.links.splice(self.links.indexOf(self.links[i]),1);
                                    i=self.links.length;

                                } 

                                i++;
                        }

                        self.nodes.splice(self.nodes.indexOf(self.nodes[j]),1);
                        j=self.nodes.length;
                        h=self.nodes.length;

                    }
                }

                contador=0;

                j++;

            }
        }

        self.force.start();

    },
    comprobar_nodo_modificado : function(){

        var self = this;
  
        //if(self.nodos_modificados.length >= 2){

            var a = self.nodes[0];
            var modificado = self.nodos_modificados[0]; //{id: self.i, node:  row.parent};

            var timer = (10-self.slider.getValue())*100;  // TODO calculate from previous and next events

            var j = self.nodes.length-1;

            while (j >= 0){
                    //Buscamos el nodo a borrar.   
                    if (self.nodes[j].node == modificado.node){

                        self.nodes.splice(self.nodes.indexOf(self.nodes[j]),1);//borro el nodo - posicion y nº de nodos a borrar.
                        self.nodos_modificados.splice(0,1);

                        var z= self.links.length-1;

                        while(z >= 0){
                            if(self.links[z].source.node==modificado.node && (self.links[z].source.node != 'iniciales' || self.links[z].source.node != 'usuarios')){

                                self.links.splice(self.links.indexOf(self.links[z]),1);
                                z=-1;

                            }

                        z--;

                        }

                        j=-1;
                    }   
                j--;
            }

            if (!a){

                self.nodes.push(modificado);
                self.links.push({source: modificado, target: modificado});

            }else {

                var j = 0;
                while (j < self.nodes.length){

                    if (self.nodes[j].parent ==  modificado.parent && self.nodes[j].node == "iniciales"){

                            self.nodes.push(modificado);
                            self.links.push({source: modificado, target: self.nodes[j]});
                            
                            j=self.nodes.length;
                    } 

                    j++;
                }

                self.start({ row: modificado, timer: timer });
                //self.add_user(row); 
            }
        //}
      
    },
    start : function(dt){

        var self = this;
        
        var row = dt.row;
        var timer = dt.timer;

        var nodos;
        var texto_nodos;

        var color = row.color;
        var color_brillo = self.getLuxColor(row.color,0.8);

        var Color_Nodos = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos.append("stop").attr("offset", "0%").attr("stop-color", self.opuesto).attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos.append("stop").attr("offset", "60%").attr("stop-color", color).attr("stop-opacity", 0.5); // Color red
        Color_Nodos.append("stop").attr("offset", "100%").attr("stop-color", self.opuesto).attr("stop-opacity", 0).attr("brighter",1); // Color red aclarado + 4

        var Color_Texto_Nodos = self.svg.append("defs").append("radialGradient").attr("id", "Color_Texto_Nodos").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Texto_Nodos.append("stop").attr("offset", "0%").attr("stop-color", color_brillo).attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Texto_Nodos.append("stop").attr("offset", "60%").attr("stop-color", color).attr("stop-opacity", 0.5); // Color red
        Color_Texto_Nodos.append("stop").attr("offset", "100%").attr("stop-color", color_brillo).attr("stop-opacity", 1).attr("brighter",1); // Color blanco

        nodos = row.color;



        texto_nodos = row.color;






        /*switch (row.parent) {
            case "Changeset":   
                nodos = "url(#Color_Nodos_Verde)"
                texto_nodos = "url(#Color_Texto_Nodos_Verde)"
                break;
            case "Emergency":   
                nodos = "url(#Color_Nodos_Rojo)"
                texto_nodos = "url(#Color_Texto_Nodos_Rojo)"
                break;
            case "KB":          
                nodos = "url(#Color_Nodos_Marron)"
                texto_nodos = "url(#Color_Texto_Nodos_Marron)"
                break;
            case "Impact Estimation":   
                nodos = "url(#Color_Nodos_Morado)"
                texto_nodos = "url(#Color_Texto_Nodos_Morado)"
                break;
            case "Project":   
                nodos = "url(#Color_Nodos_MoradoOscuro)"
                texto_nodos = "url(#Color_Texto_Nodos_MoradoOscuro)"
                break;
            case "Release":   
                nodos = "url(#Color_Nodos_AzulOscuro)"
                texto_nodos = "url(#Color_Texto_Nodos_AzulOscuro)"
                break;
            case "Requirement":   
                nodos = "url(#Color_Nodos_Amarillo)"
                texto_nodos = "url(#Color_Texto_Nodos_Amarillo)"
                break;
            case "Test Case":   
                nodos = "url(#Color_Nodos_Azul)"
                texto_nodos = "url(#Color_Texto_Nodos_Azul)"
                break;
            default: 
                nodos = "url(#Color_Nodos)"
                texto_nodos = "url(#Color_Texto_Nodos)"
        }*/




        self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });

        self.link.enter().insert("line", ".node");//.attr("class", "link").attr("stroke","steelblue").attr("stroke-opacity",0.4);
        self.link.exit().remove();

        self.node5 = self.node5.data(self.force.nodes(), function(d) { return d.id;});
        self.node5.enter().append("text").text(row.node).attr("fill", texto_nodos).attr("fill-opacity",0.6).style("visibility", "hidden");
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

        self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
        self.node4.enter().append("text").text(row.node).attr("fill","url(#Verde)").transition().duration(timer).attr("fill", texto_nodos).remove();
        self.node4.exit().remove();
      
        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 10).attr("fill","url(#Verde)").attr("fill-opacity",0.6)
                         .on('mouseover', function(d)
                         {
                            d3.select(this).transition()
                          /*  .duration(750)
                            .attr("r", 55)
                            .attr("fill","url(#Amarillo)")
                            //.attr("fill-opacity",0.6);
                            self.node9.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(row.t).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+3).attr("fill",texto_nodos).attr("fill-opacity",0.6).style("visibility", "visible");
                            self.node6.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(row.ev).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+16).attr("fill",texto_nodos).attr("fill-opacity",0.6).style("visibility", "visible");
                            self.node7.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(row.who).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+29).attr("fill",texto_nodos).attr("fill-opacity",0.6).style("visibility", "visible");
                            self.node8.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(row.parent).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+42).attr("fill",texto_nodos).attr("fill-opacity",0.6).style("visibility", "visible");
                           */ return self.node5.attr("fill",self.opuesto).style("visibility", "visible");
                         })
                         .on("mouseout", function()
                         {
                         d3.select(this).transition()
                         /*.duration(750)
                         .attr("r", 10)
                         .attr("fill",nodos)
                         .attr("fill-opacity",0.6);
                         self.node6.style("visibility", "hidden");
                         self.node7.style("visibility", "hidden");
                         self.node8.style("visibility", "hidden");
                         self.node9.style("visibility", "hidden");*/
                         return self.node5.attr("fill",self.opuesto).style("visibility", "hidden");//})
                         })
                         .call(self.force.drag)
                         .transition().duration(timer).attr("fill",nodos).attr("fill-opacity",0.6);
        self.node.exit().remove();

        self.node3 = self.node3.data(self.force.nodes(), function(d) { return d.id;});
        self.node3.enter().append("text");
        self.node3.exit().remove();

        self.force.start();

    },
    start_modify : function(dt){

        var self = this;
        
        var row = dt.row;
        var timer = dt.timer;

        self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link.enter().insert("line", ".node");//.attr("class", "link").attr("stroke","steelblue").attr("stroke-opacity",0.4);
        self.link.exit().remove();

        self.node5 = self.node5.data(self.force.nodes(), function(d) { return d.id;});
        self.node5.enter().append("text").text(row.node).attr("fill","url(#Verde)").attr("fill-opacity",0.6).style("visibility", "hidden");
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

        self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
        self.node4.enter().append("text").text(row.node).attr("fill","url(#Verde)").transition().duration(timer).attr("fill","url(#Verde)").remove();
        self.node4.exit().remove();
      
        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 10).attr("fill","url(#Verde)").attr("fill-opacity",0.6)
                         .on('mouseover', function(d)
                         {
                            d3.select(this).transition()
                            /*.duration(750)
                            .attr("r", 55)
                            .attr("fill","url(#Amarillo)")
                            //.attr("fill-opacity",0.6);
                            self.node9.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(row.t).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+3).attr("fill","url(#Color_Texto_Nodos)").attr("fill-opacity",0.6).style("visibility", "visible");
                            self.node6.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(row.ev).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+16).attr("fill","url(#Color_Texto_Nodos)").attr("fill-opacity",0.6).style("visibility", "visible");
                            self.node7.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(row.who).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+29).attr("fill","url(#Color_Texto_Nodos)").attr("fill-opacity",0.6).style("visibility", "visible");
                            self.node8.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(row.parent).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+42).attr("fill","url(#Color_Texto_Nodos)").attr("fill-opacity",0.6).style("visibility", "visible");
                            */return self.node5.attr("fill",self.opuesto).style("visibility", "visible");
                         })
                         .on("mouseout", function()
                         {
                         d3.select(this).transition()
                         /*.duration(750)
                         .attr("r", 10)
                         .attr("fill","url(#Verde)")
                         .attr("fill-opacity",0.6);
                         self.node6.style("visibility", "hidden");
                         self.node7.style("visibility", "hidden");
                         self.node8.style("visibility", "hidden");
                         self.node9.style("visibility", "hidden");*/
                         return self.node5.attr("fill",self.opuesto).style("visibility", "hidden");//})
                         })
                         .call(self.force.drag)
                         .transition().duration(timer).attr("fill","url(#Verde)").attr("fill-opacity",0.6);
        self.node.exit().remove();

        self.node3 = self.node3.data(self.force.nodes(), function(d) { return d.id;});
        self.node3.enter().append("text");
        self.node3.exit().remove();

        self.force.start();

    },
    userstart : function(row){
        
        var self = this;

        self.texto = self.texto.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });   
        self.texto.enter().append('text'); 

        self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
        self.node4.enter().append("text");
        self.node4.exit().remove();

        self.node5 = self.node5.data(self.force.nodes(), function(d) { return d.id;});
        self.node5.enter().append("text");
        self.node5.exit().remove();

        //CREAMOS LOS NODO NODE Y NODE3 QUE SON LOS NODOS Y EL LINK DEL USUARIO   

        if (self.background_color == '#000000'){
            
            self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
            //self.link2.enter().insert("line", ".node").attr("stroke","orange").attr("stroke-opacity",0.6).attr("class", "link"); 
            self.link.enter().insert("line", ".node").attr("stroke","url(#Amarillo)").attr().attr("stroke-opacity",0.6).attr("stroke-width", 6).attr("class", "link");       
            self.link.exit().remove();

        }

        if (self.background_color == '#FFFFFF'){

            self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
            //self.link2.enter().insert("line", ".node").attr("stroke","orange").attr("stroke-opacity",0.6).attr("class", "link"); 
            self.link.enter().insert("line", ".node").attr("stroke","url(#Color_Nodos_AzulOscuro)").attr().attr("stroke-opacity",0.6).attr("stroke-width", 6).attr("class", "link");       
            self.link.exit().remove();

        }

        if(self.background_color != "#000000" || self.background_color != "#FFFFFF") {

            self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
            //self.link2.enter().insert("line", ".node").attr("stroke","orange").attr("stroke-opacity",0.6).attr("class", "link"); 
            self.link.enter().insert("line", ".node").attr("stroke", self.opuesto).attr().attr("stroke-opacity",0.6).attr("stroke-width", 6).attr("class", "link");       
            self.link.exit().remove();
        }

        self.node= self.node.data(self.force.nodes(), function(d) { return d.id;});
        //self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 10).attr("fill","url(#Color_Nodos_Raiz)").on("zoom", function(){self.rescale()});
        self.node.enter().append("png:image").attr("xlink:href", function(d) { return d.color;}).attr("width", 20).attr("height", 20);
        self.node.exit().remove();

        self.node3 = self.node3.data(self.force.nodes(), function(d) { return d.id;});



        self.node3.enter().append("text").text(row.who).attr("fill",self.colores[self.pintar])

        self.node3.exit().remove();

        self.force.start();

    }, 
    calcular_fecha : function(date){

        self = this;

        var day;
        var month;
        var hour;
        var minutes;
        var fecha;

        if(date.getDate() < 10){
            day = "0"+date.getDate();
        }else{day = date.getDate();}

        if(date.getMonth() < 9){
            month = "0"+(date.getMonth()+1);
        }else{month = date.getMonth()+1;}

        if(date.getHours() < 10){
            hour = "0"+date.getHours();
        }else{hour = date.getHours();}

        if(date.getMinutes() < 10){
            minutes = "0"+date.getMinutes();
        }else{minutes = date.getMinutes();}

        if(date.getSeconds() < 10){
            seconds = "0"+date.getSeconds();
        }else{seconds = date.getSeconds();}

        fecha = date.getFullYear()+"-"+month+"-"+day+" "+hour+":"+minutes+":"+seconds;
        return fecha;

    },
    calcula_contador : function(date){

        self = this;

        var seconds = date.getSeconds()+1;
        var minutes = date.getMinutes()
        var hour = date.getHours();
        var day = date.getDate();
        var month = date.getMonth();
        var year = date.getFullYear();
        var fecha;

        if (seconds > 59){
            seconds = '00';
            minutes = minutes+1;


            if (minutes > 59){
                minutes = '00';
                hour = hour+1;
                if(date.getHours()>=23){
                    hour = '00';
                    day = date.getDate()+1;
                    if(date.getDate()>=30){
                        if(date.getDate()==31 && (date.getMonth()==0 || date.getMonth()==2 || date.getMonth()==4 || date.getMonth()==6 || date.getMonth()==7 || date.getMonth()==9 || date.getMonth()==11)){
                           day = '01';
                           month = date.getMonth()+1; 
                            if(date.getMonth()>=11){
                                month = 00;
                                year= date.getFullYear()+1;
                            }
                        }else{
                            day = '01';
                            month = date.getMonth()+1;
                            if(date.getMonth()>=11){
                                month = 00;
                                year= date.getFullYear()+1;
                            }
                        }
                    }else if (date.getDate()==28 && date.getMonth()==1){
                        day = '01';
                        month = date.getMonth()+1;
                        if(date.getMonth()>=11){
                            month = 00;
                            year= date.getFullYear()+1;
                        }
                    }
                }
            }
        }
        fecha = year+"-"+(month+1)+"-"+day+" "+hour+":"+minutes+":"+seconds;
        return fecha;
    },
    get_days : function(days){
        
        var self = this;



        self.stop_anim();
        

        switch (days) {
            case 0: self.days=86400000
                break;
            case 2: self.days=172800000
                break;
            case 7: self.days=604800000
                break;
            case 30: self.days=2592000000
                break;
            case 90: self.days=7776000000
                break
            case 180: self.days=15552000000
                break;
            default: self.days=0
        }





        self.start_anim();
    },
    formato_imprimir : function(date){

        self = this;

        var fecha;
        var date = new Date(date);
        date.setDate(date.getDate());

         var dia;
        switch (date.getDay()) {
            case 0: dia='Domingo'
                break;
            case 1: dia='Lunes'
                break;
            case 2: dia='Martes'
                break;
            case 3: dia='Miercoles'
                break;
            case 4: dia='Jueves'
                break
            case 5: dia='Viernes'
                break;
            case 6: dia='Sabado'
                break;
            default: dia='NAN'
        }

        var mes;

        switch (date.getMonth())
        {
            case 0: mes='Enero'
                break;
            case 1: mes='Febrero'
                break;
            case 2: mes='Marzo'
                break;
            case 3: mes='Abril'
                break;
            case 4: mes='Mayo'
                break
            case 5: mes='Junio'
                break;
            case 6: mes='Julio'
                break;
            case 7: mes='Agosto'
                break;
            case 8: mes='Septiembre'
                break;
            case 9: mes='Octubre'
                break;
            case 10: mes='Noviembre'
                break;
            case 11: mes='Diciembre'
                break
            default: mes='NAN'
        }

        var day;
        var month;
        var hour;
        var minutes;

        if(date.getDate() < 10){
            day = "0"+date.getDate();
        }else{day = date.getDate();}

        if(date.getMonth() < 9){
            month = "0"+(date.getMonth()+1);
        }else{month = date.getMonth()+1;}

        if(date.getHours() < 10){
            hour = "0"+date.getHours();
        }else{hour = date.getHours();}

        if(date.getMinutes() < 10){
            minutes = "0"+date.getMinutes();
        }else{minutes = date.getMinutes();}

        fecha = dia +" , "+day+" "+mes+" "+date.getFullYear()+" "+hour+":"+minutes;

        return fecha;

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

    //alert(hex+" esto es un color "+rgb);
    return rgb;
    },
    invertir_Color : function(hex) {

        var color = hex;
        color = color.substring(1);           // remove #
        color = parseInt(color, 16);          // convert to integer
        color = 0xFFFFFF ^ color;             // invert three bytes
        color = color.toString(16);           // convert to hex
        color = ("000000" + color).slice(-6); // pad with leading zeros
        color = "#" + color;                  // prepend #

        return color;
    },
    tick : function(){

        var self = this;

        //PONIENDO EL GET_CONTROLADOR AQUI SE CUELGA LA APLICACION ¡¡¡SI PONEMOS UN TEXTO NO!!!
        self.vis.append("text")
            .text(self.date)//.text(self.get_contador())//.text(self.res.data[0].t)
            .attr("fill", self.opuesto)
            .attr("x", '45%')
            .attr("y", '5%').transition().duration(10).remove();
        //////////////////////////////////////////////////////////////////////////////////////

        //alert(self.node.t);

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

        self.node.attr("x", function(d) { return d.x; })
            .attr("y", function(d) { return d.y; });

        self.node3.attr("x", function(d) { return d.x; })
            .attr("y", function(d) { return d.y; });

    },
    rescale : function() {

        var self = this;

        self.svg.attr("transform","translate(" + d3.event.translate + ")" + " scale(" + d3.event.scale + ")");
    },
    data_load: function(skip) {
        var self = this;
        var limit = 10;
console.log("Entrando con skip = " + skip);
        Cla.ajax_json('/swarm/activity', {days: self.days, limit: limit, skip: skip}, function(res){

console.log("Res length = " + res.data.length);
            
            if(res.data.length <= 0){
                alert(_("No data for selection dates.  Please select another period"));
                //self.mostrar=true;
                self.stop_anim();
                self.i=1;
            }
            // console.log(res);
            //alert(res.data.length);
            self.res = res;
            var fecha=new Date();

            var tiempo =fecha.getTime();
            var total= fecha.setTime(tiempo-self.days);
            //var fecha_inicio = new Date(total);
          
            //var calculo = self.calcula_contador(fecha_inicio);
            //calculo = new Date(calculo);
            //self.date = self.calcular_fecha(calculo);
            //self.date = '2015-06-08 10:24';
            //alert("el calculo es "+self.date);

            if( !self.initiated ) {
                //alert("inicializa");
                self.first();
                self.initiated = true;
            }

            self.anim_running = true;
            self.btn_start.disable();
            self.btn_pause.enable();
            self.btn_stop.enable();
            setTimeout(function(){ self.anim(limit); }, (10-self.slider.getValue())*100 );
        });
    }



});

