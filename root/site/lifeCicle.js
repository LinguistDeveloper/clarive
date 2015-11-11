(function(params) {
    
var text= false;
var source = false;
var color = false;
var rolText= false;
var rolSource = false;
var rolColor = false;

var isClick = 0;
id_category = params.id_category;

//define colours
var red = "#cc0000";
var green = "#009933";
var black = "#19191C";
var blue = "#0066CC";

//Creamos los checkitems del menu desplegable de opciones.
var gEtiquetas = new Ext.menu.CheckItem({text: 'Con Etiquetas', checked: false, checkHandler: function(){text=this.checked;general(diagram, overview);}});
var gIconos = new Ext.menu.CheckItem({text: 'Iconos', checked: false, checkHandler: function(){source=this.checked;general(diagram, overview);}});
var gColorEstados = new Ext.menu.CheckItem({text: 'Estados con color', checked: false, checkHandler: function(){color=this.checked;general(diagram, overview);}});

var rEtiquetas = new Ext.menu.CheckItem({text: 'Con Etiquetas', checked: false, checkHandler: function(){rolText=this.checked;rol(diagram, overview);}});
var rIconos = new Ext.menu.CheckItem({text: 'Iconos', checked: false, checkHandler: function(){rolSource=this.checked;rol(diagram, overview);}});
var rColorEstados = new Ext.menu.CheckItem({text: 'Estados con color', checked: false, checkHandler: function(){rolColor=this.checked;rol(diagram, overview);}});

var menus = new Ext.Button({ text:'Life Cycle', icon: IC('start'), disabled: false, 
    menu : {
         items: [
            {
            text: 'General', handler: function(){general(diagram, overview);}, menu:{
              items: [
                gEtiquetas, gIconos, gColorEstados,
                '-',
                {
                    text: 'Select All',
                    handler: function() {
                    var bool = true;

                    gEtiquetas.setChecked(bool);
                    gIconos.setChecked(bool);
                    gColorEstados.setChecked(bool);
                    text=bool;
                    source=bool;
                    color=bool;
                    }
                },
                {
                    text: 'Unselect All',
                    handler: function() {
                    var bool = false;

                    gEtiquetas.setChecked(bool);
                    gIconos.setChecked(bool);
                    gColorEstados.setChecked(bool);
                    text=bool;
                    source=bool;
                    color=bool;
                    }
                }
              ]
            }},
            {
            text: 'Rol', handler: function(){rol(diagram, overview);}, menu:{
              items: [
                rEtiquetas, rIconos, rColorEstados,
                '-',
                {
                    text: 'Select All',
                    handler: function() {
                    var bool = true;

                    rEtiquetas.setChecked(bool);
                    rIconos.setChecked(bool);
                    rColorEstados.setChecked(bool);
                    rolText=bool;
                    rolSource=bool;
                    rolColor=bool;
                    }
                },
                {
                    text: 'Unselect All',
                    handler: function() {
                    var bool = false;                      
                    
                    rEtiquetas.setChecked(bool);
                    rIconos.setChecked(bool);
                    rColorEstados.setChecked(bool);
                    rolText=bool;
                    rolSource=bool;
                    rolColor=bool;
                    }
                }
              ]
            }}
          ]
    },
});

    //PANEL PRINCIPAL
    var p = new Ext.Panel({
        title: 'Diagram',
        html: 'Diagram',
        anchor: '100% 100%',

         tbar:[{xtype: 'tbspacer', width: 250},menus] 
    });
    //PANEL OVERVIEW
        var d = new Ext.Panel({
        title: 'Overview',
        html: 'overview',
        bodyStyle:{"z-index":10},
        height: 250,
        width: 250,        
        animCollapse: true,
        collapsible: true,
       
    });
    d.on('afterrender', function() {
      init();
       
    });
    function init(){
      var go_api;
      var diagram;
      var overview;
      go_api = go.GraphObject.make;
      diagram = 
      go_api(go.Diagram, p.body.id,  // must be the ID or reference to div
        {
          initialContentAlignment: go.Spot.Center, // start everything in the middle of the viewport
          //initialAutoScale: go.Diagram.Uniform,  // zoom to make everything fit in the viewport
          allowDelete: false
            
          //layout: new DemoForceDirectedLayout()  // use custom layout
          // other Layout properties are set by the layout function, defined below
        });

      overview =
      go_api(go.Overview, d.body.id,  // the HTML DIV element for the Overview
        { 
          observed: diagram, contentAlignment: go.Spot.Center 
        });   // tell it which Diagram to show and pan

      general(diagram, overview);
    };
    function general(diagram, overview){

      this.diagram = diagram;
      this.overview = overview;

      go_api = go.GraphObject.make;
 
        // the node template describes how each Node should be constructed
        diagram.nodeTemplate =
            go_api(go.Node, "Auto", // the Shape automatically fits around the TextBlock
                go_api(go.Shape,// use this kind of figure for the Shape
                    // bind Shape.fill to Node.data.color
                    new go.Binding("figure","figure"),
                    new go.Binding("fill", "color")),
                go_api(go.TextBlock, {
                        margin: 3//
                  //, stroke: "white"
                      
                    }, // some room around the text
                    // bind TextBlock.text to Node.data.key
                    new go.Binding("text", "key"),
                  new go.Binding("stroke","textColor"))
              /*,
               go_api("TreeExpanderButton",
                    { alignment: go.Spot.Bottom, alignmentFocus: go.Spot.Bottom },
                    { visible: true })*/
            );

        // define the only Link template
        diagram.linkTemplate =
          go_api(go.Link,  // the whole link panel
            { reshapable: true, resegmentable: true },
            { routing: go.Link.Orthogonal },  // optional, but need to keep LinkingTool.temporaryLink in sync, above
            //{ adjusting: go.Link.Scale },  // optional
            { curve: go.Link.JumpOver }, //Bezier
            { fromPortId: "" },
            new go.Binding("fromPortId", "fromport"),            
            go_api(go.Shape,  // the link shape
              { stroke: "#000000", strokeWidth: 1 }),   
            go_api(go.Shape,
              { toArrow: "Standard"}),                    
            go_api(go.TextBlock,  // the "from" label
              {
                textAlign: "left",
                font: "bold 8px sans-serif",
                stroke: "#0066CC",
                  
                //segmentIndex: 0,
                segmentOffset: new go.Point(10, NaN),
                segmentOrientation: go.Link.OrientUpright
              },
              new go.Binding("text", "text")),
            go_api(go.Picture,
              { width: 13, height: 35, segmentOffset: new go.Point(NaN, 10) },
              new go.Binding("source", "source"))

           );         
        
          diagram.groupTemplate =
            go_api(go.Group, "Vertical",
              go_api(go.Panel, "Auto",
                go_api(go.Shape, "RoundedRectangle",  // surrounds the Placeholder
                  { parameter1: 14,
                    fill: "rgba(128,128,128,0.33)" }),
                go_api(go.Placeholder,    // represents the area of all member parts,
                  { padding: 5})  // with some extra padding around them
              ),
              go_api(go.TextBlock,         // group title
                { alignment: go.Spot.Right, font: "Bold 12pt Sans-Serif", stroke: "#42225F" },
                new go.Binding("text", "key"))
            );
          
        
        Baseliner.ajaxEval( '/topicadmin/list_workflow', {categoryId:id_category}, function(res) {

            //ORDENAMOS LOS DATOS POR FECHA DE CREACION
            for(i=0;i<res.data.length-1;i++){
                 for(j=0;j<res.data.length-1;j++){
                     var date = new Date(res.data[j].status_time);
                     var date2 = new Date(res.data[j+1].status_time);
                      if(date>date2){
                            //guardamos el numero mayor en el auxiliar
                           aux=res.data[j];
                            //guardamos el numero menor en el lugar correspondiente
                            res.data[j]=res.data[j+1];
                            //asignamos el auxiliar en el lugar correspondiente
                            res.data[j+1]=aux;         
                      }         
                 }
            }

            // tratamos los datos y quitamos todo lo que haya posterior al [] para los statuses_to                
            var i=0;
            while (i < res.data.length){
                var k = 0;
                while(k < res.data[i].statuses_to.length){
                  var z = res.data[i].statuses_to[k];
                  res.data[i].statuses_to[k] = String(z.split(" [", 1));
                k++;
                }
            i++;
            }

            // tratamos los datos y quitamos todo lo que haya posterior al [] para los status_from    
            var i=0;     
            while (i < res.data.length){
                var z = res.data[i].status_from;
                res.data[i].status_from = String(z.split(" [", 1));
              i++;
            }

            // tratamos los datos y quitamos todo lo que haya posterior al [] para los statuses_to_type                
            var i=0;
            while (i < res.data.length){
                var k = 0;
                while(k < res.data[i].statuses_to_type.length){
                  var z = res.data[i].statuses_to_type[k];
                  res.data[i].statuses_to_type[k] = String(z.split(" [", 1));
                k++;
                }
            i++;
            }

            var objectNode = [];
            var eColor = "#FFFFFF";
            var tColor = "#000000";
              //AÑADIMOS LOS NODOS PRINCIPALES LOS ROLES QUE PUEDEN REALIZAR LAS TAREAS
              var i=0;
              while (i < res.data.length){

                  if (objectNode.length==0){
                    //objectNode.push({ "key" : res.data[i].role, "color"  : bluegrad, "figure"  : "RoundedRectangle", isGroup: true });
                  }else{
                    var j=0;
                    var equal = 1;
                    while(j < objectNode.length){

                      if(objectNode[j].key == res.data[i].role){
                        j= objectNode.length;
                        equal = 0;
                      }
                     j++;
                    }
                    if(equal!=0){
                      //objectNode.push({ "key" : res.data[i].role, "color"  : bluegrad, "figure"  : "RoundedRectangle", isGroup: true });
                    }

                  }
              i++;
              }
            //var objectStatus = [];
              var i=0;
              while (i < res.data.length){

                  if(color){
                    eColor = res.data[i].status_color;
                    tColor = invertir_Color(res.data[i].status_color);
                  }
                  if (objectNode.length==0){
                    if(res.data[i].status_type == "I"){
                        objectNode.push({ "key" : res.data[i].status_from, "color"  : green, "textColor": invertir_Color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                    }else{
                      objectNode.push({ "key" : res.data[i].status_from, "color"  : eColor, "textColor": tColor ,  "figure"  : "RoundedRectangle", group: res.data[i].role});
                    }
                  }else{
                    var j=0;
                    var equal = 1;
                    while(j < objectNode.length){

                      if(objectNode[j].key == res.data[i].status_from){
                        j= objectNode.length;
                        equal = 0;
                      }
                     j++;
                    }
                    if(equal!=0){
                        if(res.data[i].status_type == "I"){
                            objectNode.push({ "key" : res.data[i].status_from, "color"  : green, "textColor": invertir_Color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                        }else{
                            objectNode.push({ "key" : res.data[i].status_from, "color"  : eColor, "textColor": tColor, "figure"  : "RoundedRectangle", group: res.data[i].role});
                        }
                    }

                  }
              i++;
              }

              var i=0;
              while (i < res.data.length){
                  var k = 0;
                  while(k < res.data[i].statuses_to.length){
                      if(color){
                        eColor = res.data[i].status_color;
                        tColor = invertir_Color(res.data[i].status_color);
                      }
                      if (objectNode.length==0){
                        if(res.data[i].statuses_to_type[k] == 'F'){
                          objectNode.push({ "key" : res.data[i].statuses_to[k], "color"  : black,"textColor": invertir_Color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                        }else if(res.data[i].statuses_to_type[k] == 'FC'){
                          objectNode.push({ "key" : res.data[i].statuses_to[k], "color"  : red, "textColor": invertir_Color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                        }
                        else{
                          objectNode.push({ "key" : res.data[i].statuses_to[k], "color"  : eColor, "textColor": tColor, "figure"  : "Ellipse", group: res.data[i].role});
                        }
                      }else{
                        var j=0;
                        var equal = 1;
                        while(j < objectNode.length){

                          if(objectNode[j].key == res.data[i].statuses_to[k]){
                            j= objectNode.length;
                            equal = 0;
                          }
                         j++;
                        }
                        if(equal!=0){
                          if(res.data[i].statuses_to_type[k] == 'F'){
                            objectNode.push({ "key" : res.data[i].statuses_to[k], "color"  : black, "textColor": invertir_Color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                          }else if(res.data[i].statuses_to_type[k] == 'FC'){
                            objectNode.push({ "key" : res.data[i].statuses_to[k], "color"  : red, "textColor": invertir_Color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                          }
                          else{
                            objectNode.push({ "key" : res.data[i].statuses_to[k], "color"  : eColor, "textColor": tColor, "figure"  : "Ellipse", group: res.data[i].role});
                          }
                        }

                      }
                  k++;
                  }
              i++;
              }
              
        var objectLink = [];  
        objectLink = insertLinks(res, text, source);              

        // the Model holds only the essential information describing the diagram
        diagram.model = new go.GraphLinksModel(objectNode, objectLink);

        //FUNCION PARA MOSTRAR UN DIAGRAMA U OTRO AL PULSAR CLICK
        /*diagram.doubleClick = function(e) {
               
            if(isClick == 0){
                          
                  var objectLink = [];  
                  var i=0;
                  text = false;
                  source = false;
                  objectLink = insertLinks(res, text, source);

                  diagram.model = new go.GraphLinksModel(objectNode, objectLink);
       
                  //diagram.model = new go.GraphLinksModel(objectNode, objectLink);
                  // alert(isClick);
                  diagram.layout = go_api(go.LayeredDigraphLayout, 
                    { 
                    direction: 0, 
                    layerSpacing: 50,      
                    columnSpacing: 20,
                    layeringOption: go.LayeredDigraphLayout.LayerLongestPathSource
                    });

              isClick = 1;
            }else{
                  var objectLink = [];  
                  text = true;
                  source = true;
                  objectLink = insertLinks(res, text, source);

                  diagram.model = new go.GraphLinksModel(objectNode, objectLink);
                  //diagram.model = new go.GraphLinksModel(objectNode, objectLink);
                  //alert(isClick);
                  diagram.layout = go_api(go.LayeredDigraphLayout, 
                    { 
                    direction: 0, 
                    layerSpacing: 100,      
                    columnSpacing: 90,
                    layeringOption: go.LayeredDigraphLayout.LayerLongestPathSource
                    });


              isClick = 0;
            }

          };*/  
          //FIN DE LA FUNCION PARA CAMBIAR EL DIAGRAMA CON UN CLICK


        });

        //diagram.model = new go.GraphLinksModel(objectNode, objectLink);
        if(text == true || source == true){
          diagram.layout = go_api(go.LayeredDigraphLayout, 
            { 
            direction: 0, 
            layerSpacing: 100,      
            columnSpacing: 90,
            layeringOption: go.LayeredDigraphLayout.LayerLongestPathSource
            });
        }else{
          diagram.layout = go_api(go.LayeredDigraphLayout, 
            { 
            direction: 0, 
            layerSpacing: 50,      
            columnSpacing: 20,
            layeringOption: go.LayeredDigraphLayout.LayerLongestPathSource
            });

        }
        diagram.initialContentAlignment = go.Spot.Center;
        // enable Ctrl-Z to undo and Ctrl-Y to redo
        diagram.undoManager.isEnabled = false;





    };

    function rol(diagram,overview){
      this.diagram = diagram;
      this.overview = overview;

        // the node template describes how each Node should be constructed
        diagram.nodeTemplate =
            go_api(go.Node, "Auto", // the Shape automatically fits around the TextBlock
                go_api(go.Shape,// use this kind of figure for the Shape
                    // bind Shape.fill to Node.data.color
                    new go.Binding("figure","figure"),
                    new go.Binding("fill", "color")),
                go_api(go.TextBlock, {
                        margin: 3//
                  //, stroke: "white"
                      
                    }, // some room around the text
                    // bind TextBlock.text to Node.data.key
                  new go.Binding("text", "text"),
                  new go.Binding("stroke","textColor"))
            );

        // define the only Link template
        diagram.linkTemplate =
          go_api(go.Link,  // the whole link panel
            { reshapable: true, resegmentable: true },
            { routing: go.Link.Orthogonal },  // optional, but need to keep LinkingTool.temporaryLink in sync, above
            //{ adjusting: go.Link.Scale },  // optional
            { curve: go.Link.JumpOver }, //Bezier
            { fromPortId: "" },
            new go.Binding("fromPortId", "fromport"),            
            go_api(go.Shape,  // the link shape
              { stroke: "#000000", strokeWidth: 1 }),   
            go_api(go.Shape,
              { toArrow: "Standard"}),                    
            go_api(go.TextBlock,  // the "from" label
              {
                textAlign: "left",
                font: "bold 8px sans-serif",
                stroke: "#0066CC",
                  
                //segmentIndex: 0,
                segmentOffset: new go.Point(10, NaN),
                segmentOrientation: go.Link.OrientUpright
              },
              new go.Binding("text", "text")),
            go_api(go.Picture,
              { width: 13, height: 35, segmentOffset: new go.Point(NaN, 10) },
              new go.Binding("source", "source"))

           );         
        
          diagram.groupTemplate =
            go_api(go.Group, "Vertical",
              go_api(go.Panel, "Auto",
                go_api(go.Shape, "RoundedRectangle",  // surrounds the Placeholder
                  { parameter1: 14,
                    fill: "rgba(128,128,128,0.33)" }),
                go_api(go.Placeholder,    // represents the area of all member parts,
                  { padding: 5})  // with some extra padding around them
              ),
              go_api(go.TextBlock,         // group title
                { alignment: go.Spot.Right, font: "Bold 12pt Sans-Serif", stroke: "#42225F" },
                new go.Binding("text", "key"))
            );
          
        
        Baseliner.ajaxEval( '/topicadmin/list_workflow', {categoryId:id_category}, function(res) {

            //ORDENAMOS LOS DATOS POR FECHA DE CREACION
            for(i=0;i<res.data.length-1;i++){
                 for(j=0;j<res.data.length-1;j++){
                     var date = new Date(res.data[j].status_time);
                     var date2 = new Date(res.data[j+1].status_time);
                      if(date>date2){
                            //guardamos el numero mayor en el auxiliar
                           aux=res.data[j];
                            //guardamos el numero menor en el lugar correspondiente
                            res.data[j]=res.data[j+1];
                            //asignamos el auxiliar en el lugar correspondiente
                            res.data[j+1]=aux;         
                      }         
                 }
            }

            // tratamos los datos y quitamos todo lo que haya posterior al [] para los statuses_to                
            var i=0;
            while (i < res.data.length){
                var k = 0;
                while(k < res.data[i].statuses_to.length){
                  var z = res.data[i].statuses_to[k];
                  res.data[i].statuses_to[k] = String(z.split(" [", 1));
                k++;
                }
            i++;
            }

            // tratamos los datos y quitamos todo lo que haya posterior al [] para los status_from    
            var i=0;     
            while (i < res.data.length){
                var z = res.data[i].status_from;
                res.data[i].status_from = String(z.split(" [", 1));
              i++;
            }

            // tratamos los datos y quitamos todo lo que haya posterior al [] para los statuses_to_type                
            var i=0;
            while (i < res.data.length){
                var k = 0;
                while(k < res.data[i].statuses_to_type.length){
                  var z = res.data[i].statuses_to_type[k];
                  res.data[i].statuses_to_type[k] = String(z.split(" [", 1));
                k++;
                }
            i++;
            }

            var bluegrad = go_api(go.Brush, "Linear", { 0: "white", 1: "skyblue" });
            var objectNode = [];
            var eColor = "#FFFFFF";
            var tColor = "#000000";

              //AÑADIMOS LOS NODOS PRINCIPALES LOS ROLES QUE PUEDEN REALIZAR LAS TAREAS
              var i=0;
              while (i < res.data.length){

                  if (objectNode.length==0){
                    objectNode.push({ "key" : res.data[i].role, "color"  : bluegrad, "figure"  : "RoundedRectangle", isGroup: true });
                  }else{
                    var j=0;
                    var equal = 1;
                    while(j < objectNode.length){

                      if(objectNode[j].key == res.data[i].role){
                        j= objectNode.length;
                        equal = 0;
                      }
                     j++;
                    }
                    if(equal!=0){
                      objectNode.push({ "key" : res.data[i].role, "color"  : bluegrad, "figure"  : "RoundedRectangle", isGroup: true });
                    }

                  }
              i++;
              }
            //var objectStatus = [];
              var i=0;
              while (i < res.data.length){
                  if(rolColor){
                    eColor = res.data[i].status_color;
                    tColor = invertir_Color(res.data[i].status_color);
                  }
                  if (objectNode.length==0){
                    if(res.data[i].status_type == "I"){
                        objectNode.push({ "key" : res.data[i].role+res.data[i].status_from, "text": res.data[i].status_from, "color"  : green, "textColor": invertir_Color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                    }else{
                      objectNode.push({ "key" : res.data[i].role+res.data[i].status_from, "text": res.data[i].status_from, "color"  : eColor, "textColor": tColor,  "figure"  : "RoundedRectangle", group: res.data[i].role});
                    }
                  }else{
                    var j=0;
                    var equal = 1;
                    while(j < objectNode.length){

                      if(objectNode[j].key == res.data[i].role+res.data[i].status_from){
                        j= objectNode.length;
                        equal = 0;
                      }
                     j++;
                    }
                    if(equal!=0){
                        if(res.data[i].status_type == "I"){
                            objectNode.push({ "key" : res.data[i].role+res.data[i].status_from, "text": res.data[i].status_from, "color"  : green, "textColor": invertir_Color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                        }else{
                            objectNode.push({ "key" : res.data[i].role+res.data[i].status_from, "text": res.data[i].status_from, "color"  : eColor, "textColor": tColor, "figure"  : "RoundedRectangle", group: res.data[i].role});
                        }
                    }

                  }
              i++;
              }

              var i=0;
              while (i < res.data.length){
                  var k = 0;
                  while(k < res.data[i].statuses_to.length){
                      if(rolColor){
                        eColor = res.data[i].status_color;
                        tColor = invertir_Color(res.data[i].status_color);
                      }
                      if (objectNode.length==0){
                        if(res.data[i].statuses_to_type[k] == 'F'){
                          objectNode.push({ "key" : res.data[i].role+res.data[i].statuses_to[k], "text": res.data[i].statuses_to[k], "color"  : black,"textColor": invertir_Color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                        }else if(res.data[i].statuses_to_type[k] == 'FC'){
                          objectNode.push({ "key" : res.data[i].role+res.data[i].statuses_to[k], "text": res.data[i].statuses_to[k], "color"  : red, "textColor": invertir_Color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                        }
                        else{
                          objectNode.push({ "key" : res.data[i].role+res.data[i].statuses_to[k], "text": res.data[i].statuses_to[k], "color"  : eColor, "textColor": tColor, "figure"  : "Ellipse", group: res.data[i].role});
                        }
                      }else{
                        var j=0;
                        var equal = 1;
                        while(j < objectNode.length){

                          if(objectNode[j].key == res.data[i].role+res.data[i].statuses_to[k]){
                            j= objectNode.length;
                            equal = 0;
                          }
                         j++;
                        }
                        if(equal!=0){
                          if(res.data[i].statuses_to_type[k] == 'F'){
                            objectNode.push({ "key" : res.data[i].role+res.data[i].statuses_to[k], "text": res.data[i].statuses_to[k], "color"  : black, "textColor": invertir_Color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                          }else if(res.data[i].statuses_to_type[k] == 'FC'){
                            objectNode.push({ "key" : res.data[i].role+res.data[i].statuses_to[k], "text": res.data[i].statuses_to[k], "color"  : red, "textColor": invertir_Color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                          }
                          else{
                            objectNode.push({ "key" : res.data[i].role+res.data[i].statuses_to[k], "text": res.data[i].statuses_to[k], "color"  : eColor, "textColor": tColor, "figure"  : "Ellipse", group: res.data[i].role});
                          }
                        }

                      }
                  k++;
                  }
              i++;
              }
            
              var objectLink = []; 
              var texto = "";
              var isource = [];
              if(rolSource){
              isource = ["/static/gojs/srojo.png","/static/gojs/sverde.png","/static/gojs/samarillo.png"];
              }
              var i=0;
              while (i < res.data.length){
                    //objectLink.push({ from: res.data[i].role, to: res.data[i].status_from });
                    var j=0;
                    while(j < res.data[i].statuses_to.length){
                      if(rolText){
                        texto = res.data[i].role;
                      }
                      if(res.data[i].role_job_type == "static"){
                        objectLink.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: texto, source: isource[0]  });
                      }else if(res.data[i].role_job_type == "promote"){
                        objectLink.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: texto, source: isource[1]  });
                      }else if(res.data[i].role_job_type == "demote"){
                        objectLink.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: texto, source: isource[2]  });
                      }else{
                       objectLink.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: texto, source: ""});
                      }
                    j++;
                    }
              i++;
              }

              //BORRAMOS LOS LINKS DUPLICADOS
              var i=0;
              var aux = objectLink;
              while (i < objectLink.length){
                var j = 0;
                var count = 0;
                  while (j < objectLink.length){
                    if(aux[i].from == objectLink[j].from && aux[i].to == objectLink[j].to){
                      if(count==0){
                        count=1;
                      }else{
                          if(rolText){
                            aux[i].text = aux[i].text + " , " + objectLink[j].text;
                          }else{
                            aux[i].text = "";
                          }
                          if(!aux[i].source){
                            aux[i].source = objectLink[j].source;
                          }
                        //aux[i].source = aux[i].source + " , " + objectLink[j].source;
                        objectLink.splice(objectLink.indexOf(objectLink[j]),1);
                        //aux[i].text = text;
                      }
                    }
                  j++;
                  }             
                i++;
              }
              //INSERTAMOS LOS TEXTOS
              var i=0;
              while (i < objectLink.length){
                var j = 0;
                  while (j < objectLink.length){
                    if(aux[i].from == objectLink[j].from && aux[i].to == objectLink[j].to){
                        objectLink[j].text = aux[i].text;
                        objectLink[j].source = aux[i].source;
                    }
                  j++;
                  }             
                i++;
              }
        // the Model holds only the essential information describing the diagram
        diagram.model = new go.GraphLinksModel(objectNode, objectLink);

        //FUNCION PARA MOSTRAR UN DIAGRAMA U OTRO AL PULSAR CLICK
        /*diagram.doubleClick = function(e) {
               
            if(isClick == 0){
                          
                  var objectLink = [];  
              var i=0;
              while (i < res.data.length){
                    //objectLink.push({ from: res.data[i].role, to: res.data[i].status_from });
                    var j=0;
                    while(j < res.data[i].statuses_to.length){
                      if(res.data[i].role_job_type == "static"){
                        objectLink.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: "", source: ""  });
                      }else if(res.data[i].role_job_type == "promote"){
                        objectLink.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: "", source: "" });
                      }else if(res.data[i].role_job_type == "demote"){
                        objectLink.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: "", source: "" });
                      }else{
                       objectLink.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: "", source: ""});
                      }
                    j++;
                    }
              i++;
              }

              //BORRAMOS LOS LINKS DUPLICADOS
              var i=0;
              var aux = objectLink;
              while (i < objectLink.length){
                var j = 0;
                var count = 0;
                  while (j < objectLink.length){
                    if(aux[i].from == objectLink[j].from && aux[i].to == objectLink[j].to){
                      if(count==0){
                        count=1;
                      }else{
                        aux[i].text = aux[i].text + " , " + objectLink[j].text;
                          if(!aux[i].source){
                            aux[i].source = objectLink[j].source;
                          }
                        //aux[i].source = aux[i].source + " , " + objectLink[j].source;
                        objectLink.splice(objectLink.indexOf(objectLink[j]),1);
                        //aux[i].text = text;
                      }
                    }
                  j++;
                  }             
                i++;
              }
              //INSERTAMOS LOS TEXTOS
              var i=0;
              while (i < objectLink.length){
                var j = 0;
                  while (j < objectLink.length){
                    if(aux[i].from == objectLink[j].from && aux[i].to == objectLink[j].to){
                        objectLink[j].text = aux[i].text;
                        objectLink[j].source = aux[i].source;
                    }
                  j++;
                  }             
                i++;
              }

                  diagram.model = new go.GraphLinksModel(objectNode, objectLink);
                  diagram.groupTemplate.layout = go_api(go.LayeredDigraphLayout, 
                    { 
                      direction: 0, 
                      layerSpacing: 50,      
                      columnSpacing: 20,
                      layeringOption: go.LayeredDigraphLayout.LayerLongestPathSource
                    });          
                  //diagram.model = new go.GraphLinksModel(objectNode, objectLink);
                  // alert(isClick);
              isClick = 1;
            }else{
                  var objectLink = [];  
              var i=0;
              while (i < res.data.length){
                    //objectLink.push({ from: res.data[i].role, to: res.data[i].status_from });
                    var j=0;
                    while(j < res.data[i].statuses_to.length){
                      if(res.data[i].role_job_type == "static"){
                        objectLink.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: res.data[i].role, source: "/static/gojs/srojo.png"  });
                      }else if(res.data[i].role_job_type == "promote"){
                        objectLink.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: res.data[i].role, source: "/static/gojs/sverde.png" });
                      }else if(res.data[i].role_job_type == "demote"){
                        objectLink.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: res.data[i].role, source: "/static/gojs/samarillo.png" });
                      }else{
                       objectLink.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: res.data[i].role, source: ""});
                      }
                    j++;
                    }
              i++;
              }

              //BORRAMOS LOS LINKS DUPLICADOS
              var i=0;
              var aux = objectLink;
              while (i < objectLink.length){
                var j = 0;
                var count = 0;
                  while (j < objectLink.length){
                    if(aux[i].from == objectLink[j].from && aux[i].to == objectLink[j].to){
                      if(count==0){
                        count=1;
                      }else{
                        aux[i].text = aux[i].text + " , " + objectLink[j].text;
                          if(!aux[i].source){
                            aux[i].source = objectLink[j].source;
                          }
                        //aux[i].source = aux[i].source + " , " + objectLink[j].source;
                        objectLink.splice(objectLink.indexOf(objectLink[j]),1);
                        //aux[i].text = text;
                      }
                    }
                  j++;
                  }             
                i++;
              }
              //INSERTAMOS LOS TEXTOS
              var i=0;
              while (i < objectLink.length){
                var j = 0;
                  while (j < objectLink.length){
                    if(aux[i].from == objectLink[j].from && aux[i].to == objectLink[j].to){
                        objectLink[j].text = aux[i].text;
                        objectLink[j].source = aux[i].source;
                    }
                  j++;
                  }             
                i++;
              }


                  diagram.model = new go.GraphLinksModel(objectNode, objectLink);
                  diagram.groupTemplate.layout = go_api(go.LayeredDigraphLayout, 
                    { 
                      direction: 0, 
                      layerSpacing: 10,      
                      columnSpacing: 10,
                      layeringOption: go.LayeredDigraphLayout.LayerLongestPathSource
                    });  
              isClick = 0;
            }

          };*/  
          //FIN DE LA FUNCION PARA CAMBIAR EL DIAGRAMA CON UN CLICK


        });


        diagram.layout = go_api(go.LayeredDigraphLayout, 
                       { 
                        direction: 0, 
                        layerSpacing: 10,      
                        columnSpacing: 10,
                        layeringOption: go.LayeredDigraphLayout.LayerLongestPathSource
                        });
        diagram.groupTemplate.layout = go_api(go.LayeredDigraphLayout, 
                       { 
                        direction: 0, 
                        layerSpacing: 50,      
                        columnSpacing: 20,
                        layeringOption: go.LayeredDigraphLayout.LayerLongestPathSource
                        });

        diagram.initialContentAlignment = go.Spot.Center;
        //diagram.initialAutoScale= false; 
        // enable Ctrl-Z to undo and Ctrl-Y to redo
        diagram.undoManager.isEnabled = false;

    }


    function insertLinks(res,text, source){
      var objectLink = [];
      this.res = res;
      this.text = text;
      this.source =  source;
      var texto = "";
      var isource = [];

      if(source){
        isource = ["/static/gojs/srojo.png","/static/gojs/sverde.png","/static/gojs/samarillo.png"];
      }


      var i=0;
      while (i < res.data.length){
            //objectLink.push({ from: res.data[i].role, to: res.data[i].status_from });
            var j=0;
            while(j < res.data[i].statuses_to.length){
              if(text){
                texto = res.data[i].role;
              }
              if(res.data[i].role_job_type == "static"){
                objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: texto, source: isource[0]  });
              }else if(res.data[i].role_job_type == "promote"){
                objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: texto, source: isource[1] });
              }else if(res.data[i].role_job_type == "demote"){
                objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: texto, source: isource[2] });
              }else{
               objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: texto, source: ""});
              }


            j++;
            }
      i++;
      }

      //BORRAMOS LOS LINKS DUPLICADOS
      var i=0;
      var aux = objectLink;
      while (i < objectLink.length){
        var j = 0;
        var count = 0;
          while (j < objectLink.length){
            if(aux[i].from == objectLink[j].from && aux[i].to == objectLink[j].to){
              if(count==0){
                count=1;
              }else{
                if(text){
                  aux[i].text = aux[i].text + " , " + objectLink[j].text;
                }else{
                  aux[i].text = "";
                }
                  if(!aux[i].source){
                    aux[i].source = objectLink[j].source;
                  }
                //aux[i].source = aux[i].source + " , " + objectLink[j].source;
                objectLink.splice(objectLink.indexOf(objectLink[j]),1);
                //aux[i].text = text;
              }
            }
          j++;
          }             
        i++;
      }
      //INSERTAMOS LOS TEXTOS
      var i=0;
      while (i < objectLink.length){
        var j = 0;
          while (j < objectLink.length){
            if(aux[i].from == objectLink[j].from && aux[i].to == objectLink[j].to){
                objectLink[j].text = aux[i].text;
                objectLink[j].source = aux[i].source;
            }
          j++;
          }             
        i++;
      }

      return objectLink;
    }



    //FUNCION QUE USAMOS PARA CONSEGUIR EL COLOR OPUESTO AL DEL BACKGROUND
    function invertir_Color(hex) {

      var color = hex;
      color = color ? color.substring(1) : 'ffffff';           // remove #
      color = parseInt(color, 16);          // convert to integer
      color = 0xFFFFFF ^ color;             // invert three bytes
      color = color.toString(16);           // convert to hex
      color = ("000000" + color).slice(-6); // pad with leading zeros
      color = "#" + color;                  // prepend #

      return color;
    }


     var container = new Ext.Panel({
         width: 800,
         height: 600,
         layout: 'absolute', 
         items:[p,d]
     });
    return container;    
});