(function() {
    var isClick = 0;
    //PANEL PRINCIPAL
var j = new Ext.Button({text: "Live Cicle General", icon: IC('start'), disabled: false });
j.on('click', function(){
  alert("dddd");
});
var k = new Ext.Button({ text: "Life Cicle Rol", icon: IC('start'), disabled: false, handler: function(){alert("adddios");} });
    var p = new Ext.Panel({
        title: 'Diagram',
        html: 'aa',
        anchor: '100% 100%',
         tbar:[{xtype: 'tbspacer', width: 250},j,k] 
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
    //PANEL DE TOOLSBAR
    /*var h = new Ext.Panel({
            x:250,
            y:0,
        title: 'Tools Bar',
        html: 'ToolsBar',
        bodyStyle:{"background-color":"white"},
        height: 250,
        width: 250,        
        animCollapse: true,
        collapsible: true
    });*/
    d.on('afterrender', function() {
      
        // For conciseness. See the "Building Parts" intro page for more
        var $ = go.GraphObject.make;
        
        /*
        //LAYOUT FORCEDIRECTEDLAYOUT
        function ContinuousForceDirectedLayout() {
          go.ForceDirectedLayout.call(this);
          this._isObserving = false;
        }
        go.Diagram.inherit(ContinuousForceDirectedLayout, go.ForceDirectedLayout);
           
          ContinuousForceDirectedLayout.prototype.isFixed = function(v) {
            return v.node.isSelected;
        }

        // optimization: reuse the ForceDirectedNetwork rather than re-create it each time
        
        ContinuousForceDirectedLayout.prototype.doLayout = function(coll) {
          if (!this._isObserving) {
            this._isObserving = true;
            // cacheing the network means we need to recreate it if nodes or links have been added or removed or relinked,
            // so we need to track structural model changes to discard the saved network.
            var lay = this;
            this.diagram.model.addChangedListener(function (e) {
              // modelChanges include a few cases that we don't actually care about, such as
              // "nodeCategory" or "linkToPortId", but we'll go ahead and recreate the network anyway
              if (e.modelChange !== "") lay.network = null;
            });
          }
          var net = this.network;
          if (net === null) {  // the first time, just create the network as normal
            this.network = net = this.makeNetwork(coll);
          } else {  // but on reuse we need to update the LayoutVertex.bounds for selected nodes
            this.diagram.nodes.each(function (n) {
              var v = net.findVertex(n);
              if (v !== null) v.bounds = n.actualBounds;
            });
          }
          // now perform the normal layout
          go.ForceDirectedLayout.prototype.doLayout.call(this, coll);
          // doLayout normally discards the LayoutNetwork by setting Layout.network to null;
          // here we remember it for next time
          this.network = net;
        }
        // end ContinuousForceDirectedLayout
        
        */              
   
      var diagram = 
      $(go.Diagram, p.body.id,  // must be the ID or reference to div
        {
          initialContentAlignment: go.Spot.Center, // start everything in the middle of the viewport
          //initialAutoScale: go.Diagram.Uniform,  // zoom to make everything fit in the viewport
          allowDelete: false
            
          //layout: new DemoForceDirectedLayout()  // use custom layout
          // other Layout properties are set by the layout function, defined below
        });

      var overview =
      $(go.Overview, d.body.id,  // the HTML DIV element for the Overview
        { 
          observed: diagram, contentAlignment: go.Spot.Center 
        });   // tell it which Diagram to show and pan


        //SI QUEREMOS AÑADIR UN NUEVO PANEL ESTE TENDRIAMOS QUE PONERLO EN h.on('afterrender', function() {
        /*var toolbar =
        $(go.Overview,h.body.id,  // the HTML DIV element for the Overview
        { 
          observed: diagram, contentAlignment: go.Spot.Center 
        });*/

        //define colours
        var bluegrad = $(go.Brush, "Linear", { 0: "white", 1: "skyblue" });
        var greengrad = $(go.Brush, "Linear", { 0: "white", 1: "green" });
        var redgrad = $(go.Brush, "Linear", { 0: "white", 1: "red" });
        var yellowgrad = $(go.Brush, "Linear", { 0: "yellow", 1: "orange" });
        var clarivegrad = $(go.Brush, "Linear", { 0: "#42225f", 0.4: "#702774", 1: "#bf932d" });
        var clariveinigrad = $(go.Brush, "Linear", { 0: "#bf932d", 1: "#702774" });
        var clarivefingrad = $(go.Brush, "Linear", { 0: "#702774", 1: "#bf932d" });
        var red = "#cc0000";
        var green = "#009933";
        var black = "#19191C";
        var blue = "#0066CC";

        // the node template describes how each Node should be constructed
        diagram.nodeTemplate =
            $(go.Node, "Auto", // the Shape automatically fits around the TextBlock
                $(go.Shape,// use this kind of figure for the Shape
                    // bind Shape.fill to Node.data.color
                    new go.Binding("figure","figure"),
                    new go.Binding("fill", "color")),
                $(go.TextBlock, {
                        margin: 3//
                  //, stroke: "white"
                      
                    }, // some room around the text
                    // bind TextBlock.text to Node.data.key
                    new go.Binding("text", "key"),
                  new go.Binding("stroke","textColor"))
              /*,
               $("TreeExpanderButton",
                    { alignment: go.Spot.Bottom, alignmentFocus: go.Spot.Bottom },
                    { visible: true })*/
            );

        // define the only Link template
        diagram.linkTemplate =
          $(go.Link,  // the whole link panel
            { reshapable: true, resegmentable: true },
            { routing: go.Link.Orthogonal },  // optional, but need to keep LinkingTool.temporaryLink in sync, above
            //{ adjusting: go.Link.Scale },  // optional
            { curve: go.Link.JumpOver }, //Bezier
            { fromPortId: "" },
            new go.Binding("fromPortId", "fromport"),            
            $(go.Shape,  // the link shape
              { stroke: "#B2B2CC", strokeWidth: 3 }),   
            $(go.Shape,
              { toArrow: "Standard", stroke: "#B2B2CC" , strokeWidth: 4}),                    
            $(go.TextBlock,  // the "from" label
              {
                textAlign: "left",
                font: "bold 8px sans-serif",
                stroke: "#0066CC",
                  
                //segmentIndex: 0,
                segmentOffset: new go.Point(10, NaN),
                segmentOrientation: go.Link.OrientUpright
              },
              new go.Binding("text", "text")),
            $(go.Picture,
              { width: 13, height: 35, segmentOffset: new go.Point(NaN, 10) },
              new go.Binding("source", "source"))

           );         
        
          diagram.groupTemplate =
            $(go.Group, "Vertical",
              $(go.Panel, "Auto",
                $(go.Shape, "RoundedRectangle",  // surrounds the Placeholder
                  { parameter1: 14,
                    fill: "rgba(128,128,128,0.33)" }),
                $(go.Placeholder,    // represents the area of all member parts,
                  { padding: 5})  // with some extra padding around them
              ),
              $(go.TextBlock,         // group title
                { alignment: go.Spot.Right, font: "Bold 12pt Sans-Serif", stroke: "#42225F" },
                new go.Binding("text", "key"))
            );
          
        
        Baseliner.ajaxEval( '/topicadmin/list_workflow', {categoryId:'6'}, function(res) {

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

                  if (objectNode.length==0){
                    if(res.data[i].status_type == "I"){
                        objectNode.push({ "key" : res.data[i].status_from, "color"  : green, "textColor": invertir_Color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                    }else{
                      objectNode.push({ "key" : res.data[i].status_from, "color"  : res.data[i].status_color, "textColor": invertir_Color(res.data[i].status_color),  "figure"  : "RoundedRectangle", group: res.data[i].role});
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
                            objectNode.push({ "key" : res.data[i].status_from, "color"  : res.data[i].status_color, "textColor": invertir_Color(res.data[i].status_color), "figure"  : "RoundedRectangle", group: res.data[i].role});
                        }
                    }

                  }
              i++;
              }

              var i=0;
              while (i < res.data.length){
                  var k = 0;
                  while(k < res.data[i].statuses_to.length){
                      if (objectNode.length==0){
                        if(res.data[i].statuses_to_type[k] == 'F'){
                          objectNode.push({ "key" : res.data[i].statuses_to[k], "color"  : black,"textColor": invertir_Color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                        }else if(res.data[i].statuses_to_type[k] == 'FC'){
                          objectNode.push({ "key" : res.data[i].statuses_to[k], "color"  : red, "textColor": invertir_Color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                        }
                        else{
                          objectNode.push({ "key" : res.data[i].statuses_to[k], "color"  : res.data[i].status_color, "textColor": invertir_Color(res.data[i].status_color), "figure"  : "Ellipse", group: res.data[i].role});
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
                            objectNode.push({ "key" : res.data[i].statuses_to[k], "color"  : res.data[i].status_color, "textColor": invertir_Color(res.data[i].status_color), "figure"  : "Ellipse", group: res.data[i].role});
                          }
                        }

                      }
                  k++;
                  }
              i++;
              }

                           
              /*var objectLink = [];  
              var i=0;
              while (i < res.data.length){
                    //objectLink.push({ from: res.data[i].role, to: res.data[i].status_from });
                    var j=0;
                    while(j < res.data[i].statuses_to.length){
                      if(res.data[i].role_job_type == "static"){
                        objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: res.data[i].role, source: "/static/gojs/srojo.png"  });
                      }else if(res.data[i].role_job_type == "promote"){
                        objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: res.data[i].role, source: "/static/gojs/sverde.png" });
                      }else if(res.data[i].role_job_type == "demote"){
                        objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: res.data[i].role, source: "/static/gojs/samarillo.png" });
                      }else{
                       objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: res.data[i].role, source: ""});
                      }
                    j++;
                    }
              i++;
              }*/   
            
              var objectLink = [];  
              var i=0;
              while (i < res.data.length){
                    //objectLink.push({ from: res.data[i].role, to: res.data[i].status_from });
                    var j=0;
                    while(j < res.data[i].statuses_to.length){
                      if(res.data[i].role_job_type == "static"){
                        objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: res.data[i].role, source: "/static/gojs/srojo.png"  });
                      }else if(res.data[i].role_job_type == "promote"){
                        objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: res.data[i].role, source: "/static/gojs/sverde.png" });
                      }else if(res.data[i].role_job_type == "demote"){
                        objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: res.data[i].role, source: "/static/gojs/samarillo.png" });
                      }else{
                       objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: res.data[i].role, source: ""});
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
        // the Model holds only the essential information describing the diagram
        diagram.model = new go.GraphLinksModel(objectNode, objectLink);

        //FUNCION PARA MOSTRAR UN DIAGRAMA U OTRO AL PULSAR CLICK
        diagram.doubleClick = function(e) {
               
            if(isClick == 0){
                          
                  var objectLink = [];  
                  var i=0;
                  while (i < res.data.length){
                  //objectLink.push({ from: res.data[i].role, to: res.data[i].status_from });
                    var j=0;
                    while(j < res.data[i].statuses_to.length){
                      if(res.data[i].role_job_type == "static"){
                        objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: "", source: ""  });
                      }else if(res.data[i].role_job_type == "promote"){
                        objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: "", source: "" });
                      }else if(res.data[i].role_job_type == "demote"){
                        objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: "", source: "" });
                      }else{
                        objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: "", source: ""});
                      }
                    j++;
                    }
                  i++;
                  }
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
                          aux[i].text = objectLink[j].text; //aux[i].text = aux[i].text + " , " + objectLink[j].text;
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
                  diagram.model = new go.GraphLinksModel(objectNode, objectLink);
                  diagram.layout = $(go.LayeredDigraphLayout, 
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
                        objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: res.data[i].role, source: "/static/gojs/srojo.png"  });
                      }else if(res.data[i].role_job_type == "promote"){
                        objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: res.data[i].role, source: "/static/gojs/sverde.png" });
                      }else if(res.data[i].role_job_type == "demote"){
                        objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: res.data[i].role, source: "/static/gojs/samarillo.png" });
                      }else{
                        objectLink.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: res.data[i].role, source: ""});
                      }
                    j++;
                    }
                  i++;
                  }
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
                  diagram.layout = $(go.LayeredDigraphLayout, 
                  { 
                  direction: 0, 
                  layerSpacing: 100,      
                  columnSpacing: 90,
                  layeringOption: go.LayeredDigraphLayout.LayerLongestPathSource
                  });

                  //diagram.model = new go.GraphLinksModel(objectNode, objectLink);
                  //alert(isClick);
              isClick = 0;
            }

          };  
          //FIN DE LA FUNCION PARA CAMBIAR EL DIAGRAMA CON UN CLICK


        });


        diagram.layout = $(go.LayeredDigraphLayout, 
                       { 
                        direction: 0, 
                        layerSpacing: 100,      
                        columnSpacing: 90,
                        layeringOption: go.LayeredDigraphLayout.LayerLongestPathSource
                        });

        diagram.initialContentAlignment = go.Spot.Center;
        // enable Ctrl-Z to undo and Ctrl-Y to redo
        diagram.undoManager.isEnabled = false;

        //FUNCION QUE USAMOS PARA CONSEGUIR EL COLOR OPUESTO AL DEL BACKGROUND
        function invertir_Color(hex) {

          var color = hex;
          color = color.substring(1);           // remove #
          color = parseInt(color, 16);          // convert to integer
          color = 0xFFFFFF ^ color;             // invert three bytes
          color = color.toString(16);           // convert to hex
          color = ("000000" + color).slice(-6); // pad with leading zeros
          color = "#" + color;                  // prepend #

          return color;
        }



    });

     var container = new Ext.Panel({
         width: 800,
         height: 600,
         layout: 'absolute', 
         items:[p,d]
     });
    return container;    
});