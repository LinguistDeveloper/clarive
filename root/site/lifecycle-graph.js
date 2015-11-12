(function(params) {
    
var general_text= false;
var general_source = false;
var general_color = false;
var rol_text= false;
var rol_source = false;
var rol_color = false;

var isClick = 0;
id_category = params.id_category;

//define colours
var red = "#cc0000";
var green = "#009933";
var black = "#19191C";
var blue = "#0066CC";

//Creamos los checkitems del menu desplegable de opciones.
var gEtiquetas = new Ext.menu.CheckItem({text: 'Con Etiquetas', checked: false, checkHandler: function(){general_text=this.checked;general(diagram, overview);}});
var gIconos = new Ext.menu.CheckItem({text: 'Iconos', checked: false, checkHandler: function(){general_source=this.checked;general(diagram, overview);}});
var gColorEstados = new Ext.menu.CheckItem({text: 'Estados con color', checked: false, checkHandler: function(){general_color=this.checked;general(diagram, overview);}});

var rEtiquetas = new Ext.menu.CheckItem({text: 'Con Etiquetas', checked: false, checkHandler: function(){rol_text=this.checked;rol(diagram, overview);}});
var rIconos = new Ext.menu.CheckItem({text: 'Iconos', checked: false, checkHandler: function(){rol_source=this.checked;rol(diagram, overview);}});
var rColorEstados = new Ext.menu.CheckItem({text: 'Estados con color', checked: false, checkHandler: function(){rol_color=this.checked;rol(diagram, overview);}});

var menus = new Ext.Button({ text:'Life Cycle', icon: IC('life_cycle'), iconCls: 'x-btn-icon', disabled: false, 
    menu : {
            items: [{
            text: 'General', handler: function(){general(diagram, overview);}, menu:{
                items: [
                    gEtiquetas, gIconos, gColorEstados,
                    '-',{
                        text: 'Select All',
                            handler: function() {
                                var bool = true;

                                gEtiquetas.setChecked(bool);
                                gIconos.setChecked(bool);
                                gColorEstados.setChecked(bool);
                                general_text=bool;
                                general_source=bool;
                                general_color=bool;
                            }
                        },{
                        text: 'Unselect All',
                            handler: function() {
                                var bool = false;

                                gEtiquetas.setChecked(bool);
                                gIconos.setChecked(bool);
                                gColorEstados.setChecked(bool);
                                general_text=bool;
                                general_source=bool;
                                general_color=bool;
                            }
                        }
                ]
            }},{
            text: 'Rol', handler: function(){rol(diagram, overview);}, menu:{
              items: [
                rEtiquetas, rIconos, rColorEstados,
                '-',{
                    text: 'Select All',
                    handler: function() {
                        var bool = true;

                        rEtiquetas.setChecked(bool);
                        rIconos.setChecked(bool);
                        rColorEstados.setChecked(bool);
                        rol_text=bool;
                        rol_source=bool;
                        rol_color=bool;
                        }
                    },
                {
                    text: 'Unselect All',
                    handler: function() {
                    var bool = false;                      
                    
                    rEtiquetas.setChecked(bool);
                    rIconos.setChecked(bool);
                    rColorEstados.setChecked(bool);
                    rol_text=bool;
                    rol_source=bool;
                    rol_color=bool;
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
        diagram = go_api(go.Diagram, p.body.id, {
          initialContentAlignment: go.Spot.Center, 
          allowDelete: false
        });

        overview = go_api(go.Overview, d.body.id, { 
          observed: diagram, contentAlignment: go.Spot.Center 
        });   // tell it which Diagram to show and pan

        general(diagram, overview);
    };

    function general(diagram, overview){

        this.diagram = diagram;
        this.overview = overview;

        go_api = go.GraphObject.make;
 
        // the node template describes how each Node should be constructed
        diagram.nodeTemplate = go_api(go.Node, "Auto", 
            go_api(go.Shape,
                new go.Binding("figure","figure"),
                new go.Binding("fill", "color")),
            go_api(go.TextBlock, { margin: 3 }, 
                new go.Binding("text", "key"),
                new go.Binding("stroke","textColor"))
        );

            var UnselectedBrush = "";  // item appearance, if not "selected"
    var SelectedBrush = "green";   // item appearance, if "selected"

        // define the only Link template
        diagram.linkTemplate =
          go_api(go.Link,  
            { reshapable: true, resegmentable: true },
            { routing: go.Link.Orthogonal },  
            { curve: go.Link.JumpOver },
            { fromPortId: "" },
            new go.Binding("fromPortId", "fromport"),            
            go_api(go.Shape, { stroke: "#000000", strokeWidth: 1 }),   
            go_api(go.Shape, { toArrow: "Standard"}),                    
            go_api(go.TextBlock,{
                textAlign: "left",
                font: "bold 8px sans-serif",
                stroke: "#0066CC",
                segmentOffset: new go.Point(10, NaN),
                segmentOrientation: go.Link.OrientUpright
            },
              new go.Binding("text", "text")),
                        go_api(go.TextBlock,{
                textAlign: "center",
                font: "bold 12px sans-serif",

                //stroke: stroke,
                segmentOffset: new go.Point(30, NaN),
                segmentOrientation: go.Link.OrientUpright
            },
              //new go.Binding("text", "block")),
                new go.Binding("text", "isSelected", function(b) { return b ? SelectedBrush : UnselectedBrush; }).ofObject()),
            go_api(go.Picture, { width: 32, height: 32, segmentOffset: new go.Point(NaN, 10) },
              new go.Binding("source", "source"))

        );         
        
        console.log(diagram.linkTemplate);
        if(diagram.linkTemplate.isSelected){
            console.log("llega aqui");
            diagram.linkTemplate.fill.background(green);

        }
          diagram.groupTemplate =
            go_api(go.Group, "Vertical",
              go_api(go.Panel, "Auto",
                go_api(go.Shape, "RoundedRectangle", 
                  { parameter1: 14,
                    fill: "rgba(128,128,128,0.33)" }),
                go_api(go.Placeholder,
                  { padding: 5})  
              ),
              go_api(go.TextBlock,
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

              var i=0;
              while (i < res.data.length){

                  if(general_color){
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
                      if(general_color){
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
        objectLink = insertLinks(res, general_text, general_source);              

        // the Model holds only the essential information describing the diagram
        diagram.model = new go.GraphLinksModel(objectNode, objectLink);

        });

        //diagram.model = new go.GraphLinksModel(objectNode, objectLink);
        if(general_text == true || general_source == true){
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
              { width: 32, height: 32, segmentOffset: new go.Point(NaN, 10) },
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

            //Order data for creation date.
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
                  if(rol_color){
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
                      if(rol_color){
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
              if(rol_source){
                isource = ["/static/gojs/static.png","/static/gojs/promote.png","/static/gojs/demote.png"];
              }
              var i=0;
              while (i < res.data.length){

                    var j=0;
                    while(j < res.data[i].statuses_to.length){
                      if(rol_text){
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

              //Delete duplicate links
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
                          if(rol_text){
                            aux[i].text = aux[i].text + " , " + objectLink[j].text;
                          }else{
                            aux[i].text = "";
                          }
                          if(!aux[i].source){
                            aux[i].source = objectLink[j].source;
                          }
                        objectLink.splice(objectLink.indexOf(objectLink[j]),1);
                      }
                    }
                  j++;
                  }             
                i++;
              }
              //Insert text in links
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

        });


        diagram.layout = go_api(go.LayeredDigraphLayout, { 
            direction: 0, 
            layerSpacing: 10,      
            columnSpacing: 10,
            layeringOption: go.LayeredDigraphLayout.LayerLongestPathSource
        });
        diagram.groupTemplate.layout = go_api(go.LayeredDigraphLayout, { 
            direction: 0, 
            layerSpacing: 50,      
            columnSpacing: 20,
            layeringOption: go.LayeredDigraphLayout.LayerLongestPathSource
        });

        diagram.initialContentAlignment = go.Spot.Center;
        diagram.undoManager.isEnabled = false;

    }


    function insertLinks(res,general_text, general_source){
      var objectLink = [];
      this.res = res;
      this.general_text = general_text;
      this.general_source =  general_source;
      var texto = "";
      var isource = [];

      if(general_source){
        isource = ["/static/gojs/static.png","/static/gojs/promote.png","/static/gojs/demote.png"];
      }


      var i=0;
      while (i < res.data.length){
            //objectLink.push({ from: res.data[i].role, to: res.data[i].status_from });
            var j=0;
            while(j < res.data[i].statuses_to.length){
              if(general_text){
                texto = res.data[i].role;
              }
              if(res.data[i].role_job_type == "static"){
                objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: texto, source: isource[0], block: "texto"  });
              }else if(res.data[i].role_job_type == "promote"){
                objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: texto, source: isource[1], block: "texto"  });
              }else if(res.data[i].role_job_type == "demote"){
                objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: texto, source: isource[2], block: "texto"  });
              }else{
               objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: texto, source: "", block: "texto" });
              }


            j++;
            }
      i++;
      }

      //Delete duplicate links
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
                if(general_text){
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
      //Insert text in links
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



    //Function make the oposite color to the background
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