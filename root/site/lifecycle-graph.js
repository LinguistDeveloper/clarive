(function(params) {

var checked_general= false;
var checked_rol= false;    

var general_text= false;
var general_source = false;
var general_color = false;
var rol_text= false;
var rol_source = false;
var rol_color = false;

var is_click = 0;

id_category = params.id_category;

//define colours
var red = "#CC0000";
var green = "#009933";
var black = "#19191C";
var blue = "#0066CC";

//Create the checkitems to the option menu.
var general_labels = new Ext.menu.CheckItem({text: _('With Labels'), checked: false, checkHandler: function(){if(!checked_general){general_text=this.checked;general(diagram, overview);}}});
var general_icons = new Ext.menu.CheckItem({text: _('Icons'), checked: false, checkHandler: function(){if(!checked_general){general_source=this.checked;general(diagram, overview);}}});
var general_statuses_color = new Ext.menu.CheckItem({text: _('Color Statuses'), checked: false, checkHandler: function(){if(!checked_general){general_color=this.checked;general(diagram, overview);}}});

var rol_labels = new Ext.menu.CheckItem({text: _('With Labels'), checked: false, checkHandler: function(){if(!checked_rol){rol_text=this.checked;rol(diagram, overview);}}});
var rol_icons = new Ext.menu.CheckItem({text: _('Icons'), checked: false, checkHandler: function(){if(!checked_rol){rol_source=this.checked;rol(diagram, overview);}}});
var rol_statuses_color = new Ext.menu.CheckItem({text: _('Color Statuses'), checked: false, checkHandler: function(){if(!checked_rol){rol_color=this.checked;rol(diagram, overview);}}});

//Create menus
var iid = Ext.id();

//General Button
var btn_general = new Ext.Button({ text: _('Plain'), icon: IC('life_cycle_general'), pressed: true, toggleGroup: 'process-'+iid, handler: function(){
    general(diagram, overview);
    menu_general.show();
    menu_role.hide();
}});

//Role Button
var btn_role = new Ext.Button({ text: _('Role'), icon: IC('life_cycle_rol'), pressed: false, toggleGroup: 'process-'+iid, handler: function(){
    rol(diagram, overview);
    menu_general.hide();
    menu_role.show();
}});

//Zoom +
var btn_increaseZoom = new Ext.Button({ text: _('Zoom +'), handler: function(){
    diagram.commandHandler.increaseZoom();
}});

//Zoom -
var btn_decreaseZoom = new Ext.Button({ text: _('Zoom -'), handler: function(){
    diagram.commandHandler.decreaseZoom();
}});

// Option menu to General Button
var menu_general = new Ext.Button({
    text: _('Options'), icon: IC('life_cycle_general'), menu:{
        items: [
            general_labels, general_icons, general_statuses_color,
            '-',{
                text: 'Select All',
                    handler: function() {
                        var bool = true;
                        checked_general=true;

                        general_labels.setChecked(bool);
                        general_icons.setChecked(bool);
                        general_statuses_color.setChecked(bool);
                        general_text=bool;
                        general_source=bool;
                        general_color=bool;
                        general(diagram, overview);
                        checked_general=false;
                    }
                },{
                text: 'Unselect All',
                    handler: function() {
                        var bool = false;
                        checked_general=true;

                        general_labels.setChecked(bool);
                        general_icons.setChecked(bool);
                        general_statuses_color.setChecked(bool);
                        general_text=bool;
                        general_source=bool;
                        general_color=bool;
                        general(diagram, overview);
                        checked_general=false;
                    }
                }
        ]
    }
});

// Option menu to Rol Button
var menu_role = new Ext.Button({
    text: _('Options'), icon: IC('life_cycle_rol'), hidden: true, menu:{
      items: [
        rol_labels, rol_icons, rol_statuses_color,
        '-',{
            text: 'Select All',
            handler: function() {
                var bool = true;
                checked_rol=true;

                rol_labels.setChecked(bool);
                rol_icons.setChecked(bool);
                rol_statuses_color.setChecked(bool);
                rol_text=bool;
                rol_source=bool;
                rol_color=bool;
                rol(diagram, overview);
                checked_rol=false;
                }
            },
        {
            text: 'Unselect All',
            handler: function() {
            var bool = false;                      
            checked_rol=true;

            rol_labels.setChecked(bool);
            rol_icons.setChecked(bool);
            rol_statuses_color.setChecked(bool);
            rol_text=bool;
            rol_source=bool;
            rol_color=bool;
            rol(diagram, overview);
            checked_rol=false;
            }
        }
      ]
    }
});

    //PRINCIPAL PANEL
    var pn_diagram = new Ext.Panel({
        html: 'Diagram',
        anchor: '100% 100%',
        tbar:[ btn_general, btn_role, '-', menu_general, menu_role, btn_decreaseZoom, btn_increaseZoom] 
    });

    //OVERVIEW PANEL 
    var pn_overview = new Ext.Panel({
        title: _('Overview'),
        html: 'overview',
        bodyStyle:{"z-index":10},
        floating: true,
        height: 250,
        width: 250,        
        animCollapse: true,
        collapsible: true,
    });

    pn_overview.on('afterrender', function() {
        init_overview();
        var left = pn_diagram.container.getWidth() - 250;
        pn_overview.setPosition(left,0);
    });

    var init_overview = function(){

        var go_api;
        var diagram;

        var overview;
        go_api = go.GraphObject.make;
        diagram = go_api(go.Diagram, pn_diagram.body.id, {
          initialContentAlignment: go.Spot.Center, 
          allowDelete: false
        });

        overview = go_api(go.Overview, pn_overview.body.id, { 
          observed: diagram, contentAlignment: go.Spot.Center 
        });   

        general(diagram, overview);
    };

    var general = function(diagram, overview){

        this.diagram = diagram;
        this.overview = overview;

        // when the user clicks on the background of the Diagram, remove all highlighting
        diagram.click = function(e) {
          diagram.startTransaction("no highlighteds");
          diagram.clearHighlighteds();
          diagram.commitTransaction("no highlighteds");
        };
        go_api = go.GraphObject.make;
 
        // the node template describes how each Node should be constructed
        diagram.nodeTemplate = go_api(go.Node, "Auto", {click: function(e, node) { showConnections(node); }}, 
            go_api(go.Shape,
                new go.Binding("stroke", "isHighlighted", function(h) { return h ? "red" : "black"; }).ofObject(),
                new go.Binding("figure","figure"),
                new go.Binding("fill", "color")),
            go_api(go.TextBlock, { margin: 3 }, 
                new go.Binding("text", "key"),
                new go.Binding("stroke","text_color"))
        );

        // define the only Link template
        diagram.linkTemplate =
          go_api(go.Link,// {click: function(e, link) { showLinks(link); }},   
            { reshapable: true, resegmentable: false},
            { routing: go.Link.Orthogonal },  
            { curve: go.Link.JumpOver },
            { fromPortId: "" },
            new go.Binding("fromPortId", "fromport"), 
            new go.Binding("opacity", "isSelected", function(b) { return b ? 1 : 0.5; }).ofObject(),           
            go_api(go.Shape, { stroke: "#000000", strokeWidth: 1 },new go.Binding("stroke", "isHighlighted", function(h) { return h ? "red" : "black"; }).ofObject(),new go.Binding("strokeWidth", "isHighlighted", function(h) { return h ? 3 : 1; }).ofObject()),   
            go_api(go.Shape, { toArrow: "Standard"},new go.Binding("stroke", "isHighlighted", function(h) { return h ? "red" : "black"; }).ofObject(),new go.Binding("strokeWidth", "isHighlighted", function(h) { return h ? 3 : 1; }).ofObject()),                    
            go_api(go.TextBlock,{
                textAlign: "left",
                font: "bold 8px sans-serif",
                stroke: "#0066CC",
                segmentOffset: new go.Point(10, NaN),
            },
              new go.Binding("text", "text")),

            go_api(go.TextBlock,{
                visible: false,
                textAlign: "center",
                font: "bold 10px sans-serif",
                margin: 2,
                segmentOffset: new go.Point(20, NaN)
            },
                new go.Binding("visible", "isSelected", function(b) { return b ? true : false; }).ofObject(),
                new go.Binding("text", "selected_text"),
                new go.Binding("stroke", "isSelected", function(b) { return b ? "#FFFFFF" : "transparent"; }).ofObject(),
                new go.Binding("background", "isSelected", function(b) { return b ? "#1E90FF" : "transparent"; }).ofObject()),
            go_api(go.Picture, { width: 32, height: 32, segmentOffset: new go.Point(NaN, 10) },
              new go.Binding("source", "source"))
        );         

        // define the diagram of groupTemplate
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

            //Order data for creation date.
            for(i=0;i<res.data.length-1;i++){
                 for(j=0;j<res.data.length-1;j++){
                     var date = new Date(res.data[j].status_time);
                     var date2 = new Date(res.data[j+1].status_time);
                      if(date>date2){
                            //save the max number in aux
                           aux=res.data[j];
                            //save the min number in the correct position
                            res.data[j]=res.data[j+1];
                            //save the aux in the min position (change max with min)
                            res.data[j+1]=aux;         
                      }         
                 }
            }

            //In the statuses_to delete the text after to []                 
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

            //In the status_from delete the text after to []  
            var i=0;     
            while (i < res.data.length){
                var z = res.data[i].status_from;
                res.data[i].status_from = String(z.split(" [", 1));
              i++;
            }

            //In the statuses_to_type delete the text after to []                  
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

            var object_node = [];
            var node_background_color = "#FFFFFF";
            var node_text_color = "#000000";

              var i=0;
              while (i < res.data.length){

                  if(general_color){
                    node_background_color = res.data[i].status_color;
                    node_text_color = change_color(res.data[i].status_color);
                  }
                  if (object_node.length==0){
                    if(res.data[i].status_type == "I"){
                        object_node.push({ "key" : res.data[i].status_from, "color"  : green, "text_color": change_color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                    }else{
                      object_node.push({ "key" : res.data[i].status_from, "color"  : node_background_color, "text_color": node_text_color ,  "figure"  : "RoundedRectangle", group: res.data[i].role});
                    }
                  }else{
                    var j=0;
                    var equal = 1;
                    while(j < object_node.length){

                      if(object_node[j].key == res.data[i].status_from){
                        j= object_node.length;
                        equal = 0;
                      }
                     j++;
                    }
                    if(equal!=0){
                        if(res.data[i].status_type == "I"){
                            object_node.push({ "key" : res.data[i].status_from, "color"  : green, "text_color": change_color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                        }else{
                            object_node.push({ "key" : res.data[i].status_from, "color"  : node_background_color, "text_color": node_text_color, "figure"  : "RoundedRectangle", group: res.data[i].role});
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
                        node_background_color = res.data[i].status_color;
                        node_text_color = change_color(res.data[i].status_color);
                      }
                      if (object_node.length==0){
                        if(res.data[i].statuses_to_type[k] == 'F'){
                          object_node.push({ "key" : res.data[i].statuses_to[k], "color"  : black,"text_color": change_color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                        }else if(res.data[i].statuses_to_type[k] == 'FC'){
                          object_node.push({ "key" : res.data[i].statuses_to[k], "color"  : red, "text_color": change_color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                        }
                        else{
                          object_node.push({ "key" : res.data[i].statuses_to[k], "color"  : node_background_color, "text_color": node_text_color, "figure"  : "Ellipse", group: res.data[i].role});
                        }
                      }else{
                        var j=0;
                        var equal = 1;
                        while(j < object_node.length){

                          if(object_node[j].key == res.data[i].statuses_to[k]){
                            j= object_node.length;
                            equal = 0;
                          }
                         j++;
                        }
                        if(equal!=0){
                          if(res.data[i].statuses_to_type[k] == 'F'){
                            object_node.push({ "key" : res.data[i].statuses_to[k], "color"  : black, "text_color": change_color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                          }else if(res.data[i].statuses_to_type[k] == 'FC'){
                            object_node.push({ "key" : res.data[i].statuses_to[k], "color"  : red, "text_color": change_color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                          }
                          else{
                            object_node.push({ "key" : res.data[i].statuses_to[k], "color"  : node_background_color, "text_color": node_text_color, "figure"  : "Ellipse", group: res.data[i].role});
                          }
                        }

                      }
                  k++;
                  }
              i++;
              }
              
        var object_link = [];  
        object_link = insert_links(res, general_text, general_source);      

        // the Model holds only the essential information describing the diagram
        diagram.model = new go.GraphLinksModel(object_node, object_link);

        });

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
        diagram.undoManager.isEnabled = false;

    };

    var rol = function(diagram, overview){

      this.diagram = diagram;
      this.overview = overview;

      // when the user clicks on the background of the Diagram, remove all highlighting
      diagram.click = function(e) {
        diagram.startTransaction("no highlighteds");
        diagram.clearHighlighteds();
        diagram.commitTransaction("no highlighteds");
      };

        // the node template describes how each Node should be constructed
        diagram.nodeTemplate = go_api(go.Node, "Auto", {click: function(e, node) { showConnections(node); }}, 
          go_api(go.Shape,
            new go.Binding("stroke", "isHighlighted", function(h) { return h ? "red" : "black"; }).ofObject(),
            new go.Binding("figure","figure"),
            new go.Binding("fill", "color")),
          go_api(go.TextBlock, { margin: 3 }, 
            new go.Binding("text", "text"),
            new go.Binding("stroke","text_color"))
        );

        // define the only Link template
        diagram.linkTemplate = go_api(go.Link,
          { reshapable: true, resegmentable: false },
          { routing: go.Link.Orthogonal },  
          { curve: go.Link.JumpOver }, //Bezier
          { fromPortId: "" },
          new go.Binding("fromPortId", "fromport"), 
          new go.Binding("opacity", "isSelected", function(b) { return b ? 1 : 0.5; }).ofObject(),           
            go_api(go.Shape, { stroke: "#000000", strokeWidth: 1 },new go.Binding("stroke", "isHighlighted", function(h) { return h ? "red" : "black"; }).ofObject(),new go.Binding("strokeWidth", "isHighlighted", function(h) { return h ? 3 : 1; }).ofObject()),   
            go_api(go.Shape, { toArrow: "Standard"},new go.Binding("stroke", "isHighlighted", function(h) { return h ? "red" : "black"; }).ofObject(),new go.Binding("strokeWidth", "isHighlighted", function(h) { return h ? 3 : 1; }).ofObject()),                                 
          go_api(go.TextBlock, {
              textAlign: "left",
              font: "bold 8px sans-serif",
              stroke: "#0066CC",
              segmentOffset: new go.Point(10, NaN),
            },
            new go.Binding("text", "text")
          ),
          go_api(go.TextBlock,{
                visible: false,
                textAlign: "center",
                font: "bold 10px sans-serif",
                margin: 2,
                segmentOffset: new go.Point(20, NaN)
            },
                new go.Binding("visible", "isSelected", function(b) { return b ? true : false; }).ofObject(),
                new go.Binding("text", "selected_text"),
                new go.Binding("stroke", "isSelected", function(b) { return b ? "#FFFFFF" : "transparent"; }).ofObject(),
                new go.Binding("background", "isSelected", function(b) { return b ? "#1E90FF" : "transparent"; }).ofObject()),

          go_api(go.Picture, { width: 32, height: 32, segmentOffset: new go.Point(NaN, 10) },
            new go.Binding("source", "source")
          )
        );        

        diagram.groupTemplate = go_api(go.Group, "Vertical",
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
                            //save the max number in aux
                           aux=res.data[j];
                            //save the min number in the correct position
                            res.data[j]=res.data[j+1];
                            //save the aux in the min position (change max with min)
                            res.data[j+1]=aux;         
                      }         
                 }
            }

            //In the statuses_to delete the text after to []                 
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

            //In the status_from delete the text after to []  
            var i=0;     
            while (i < res.data.length){
                var z = res.data[i].status_from;
                res.data[i].status_from = String(z.split(" [", 1));
              i++;
            }

            //In the statuses_to_type delete the text after to []                  
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
            var object_node = [];
            var node_background_color = "#FFFFFF";
            var node_text_color = "#000000";

              //CREATE THE PRINCIPAL NODES FOR CREATE THE GROUPS OF ROLES
              var i=0;
              while (i < res.data.length){

                  if (object_node.length==0){
                    object_node.push({ "key" : res.data[i].role, "color"  : bluegrad, "figure"  : "RoundedRectangle", isGroup: true });
                  }else{
                    var j=0;
                    var equal = 1;
                    while(j < object_node.length){

                      if(object_node[j].key == res.data[i].role){
                        j= object_node.length;
                        equal = 0;
                      }
                     j++;
                    }
                    if(equal!=0){
                      object_node.push({ "key" : res.data[i].role, "color"  : bluegrad, "figure"  : "RoundedRectangle", isGroup: true });
                    }

                  }
              i++;
              }

              var i=0;
              while (i < res.data.length){
                  if(rol_color){
                    node_background_color = res.data[i].status_color;
                    node_text_color = change_color(res.data[i].status_color);
                  }
                  if (object_node.length==0){
                    if(res.data[i].status_type == "I"){
                        object_node.push({ "key" : res.data[i].role+res.data[i].status_from, "text": res.data[i].status_from, "color"  : green, "text_color": change_color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                    }else{
                      object_node.push({ "key" : res.data[i].role+res.data[i].status_from, "text": res.data[i].status_from, "color"  : node_background_color, "text_color": node_text_color,  "figure"  : "RoundedRectangle", group: res.data[i].role});
                    }
                  }else{
                    var j=0;
                    var equal = 1;
                    while(j < object_node.length){

                      if(object_node[j].key == res.data[i].role+res.data[i].status_from){
                        j= object_node.length;
                        equal = 0;
                      }
                     j++;
                    }
                    if(equal!=0){
                        if(res.data[i].status_type == "I"){
                            object_node.push({ "key" : res.data[i].role+res.data[i].status_from, "text": res.data[i].status_from, "color"  : green, "text_color": change_color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                        }else{
                            object_node.push({ "key" : res.data[i].role+res.data[i].status_from, "text": res.data[i].status_from, "color"  : node_background_color, "text_color": node_text_color, "figure"  : "RoundedRectangle", group: res.data[i].role});
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
                        node_background_color = res.data[i].status_color;
                        node_text_color = change_color(res.data[i].status_color);
                      }
                      if (object_node.length==0){
                        if(res.data[i].statuses_to_type[k] == 'F'){
                          object_node.push({ "key" : res.data[i].role+res.data[i].statuses_to[k], "text": res.data[i].statuses_to[k], "color"  : black,"text_color": change_color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                        }else if(res.data[i].statuses_to_type[k] == 'FC'){
                          object_node.push({ "key" : res.data[i].role+res.data[i].statuses_to[k], "text": res.data[i].statuses_to[k], "color"  : red, "text_color": change_color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                        }
                        else{
                          object_node.push({ "key" : res.data[i].role+res.data[i].statuses_to[k], "text": res.data[i].statuses_to[k], "color"  : node_background_color, "text_color": node_text_color, "figure"  : "Ellipse", group: res.data[i].role});
                        }
                      }else{
                        var j=0;
                        var equal = 1;
                        while(j < object_node.length){

                          if(object_node[j].key == res.data[i].role+res.data[i].statuses_to[k]){
                            j= object_node.length;
                            equal = 0;
                          }
                         j++;
                        }
                        if(equal!=0){
                          if(res.data[i].statuses_to_type[k] == 'F'){
                            object_node.push({ "key" : res.data[i].role+res.data[i].statuses_to[k], "text": res.data[i].statuses_to[k], "color"  : black, "text_color": change_color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                          }else if(res.data[i].statuses_to_type[k] == 'FC'){
                            object_node.push({ "key" : res.data[i].role+res.data[i].statuses_to[k], "text": res.data[i].statuses_to[k], "color"  : red, "text_color": change_color("#000000"), "figure"  : "Ellipse", group: res.data[i].role});
                          }
                          else{
                            object_node.push({ "key" : res.data[i].role+res.data[i].statuses_to[k], "text": res.data[i].statuses_to[k], "color"  : node_background_color, "text_color": node_text_color, "figure"  : "Ellipse", group: res.data[i].role});
                          }
                        }

                      }
                  k++;
                  }
              i++;
              }
            
              var object_link = []; 
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
                        object_link.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: texto, source: isource[0], selected_text: ""+"\nRol: "+res.data[i].role+"\nFrom: "+res.data[i].status_from+" To: "+res.data[i].statuses_to[j]+"\n Name: "+"\n"  });
                      }else if(res.data[i].role_job_type == "promote"){
                        object_link.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: texto, source: isource[1], selected_text: ""+"\nRol: "+res.data[i].role+"\nFrom: "+res.data[i].status_from+" To: "+res.data[i].statuses_to[j]+"\n Name: "+"\n"  });
                      }else if(res.data[i].role_job_type == "demote"){
                        object_link.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: texto, source: isource[2], selected_text: ""+"\nRol: "+res.data[i].role+"\nFrom: "+res.data[i].status_from+" To: "+res.data[i].statuses_to[j]+"\n Name: "+"\n"  });
                      }else{
                       object_link.push({ from: res.data[i].role+res.data[i].status_from, to: res.data[i].role+res.data[i].statuses_to[j], text: texto, source: "", selected_text: ""+"\nRol: "+res.data[i].role+"\nFrom: "+res.data[i].status_from+" To: "+res.data[i].statuses_to[j]+"\n Name: "+"\n"  });
                      }
                    j++;
                    }
              i++;
              }

              //Delete duplicate links
              var i=0;
              var aux = object_link;
              while (i < object_link.length){
                var j = 0;
                var count = 0;
                  while (j < object_link.length){
                    if(aux[i].from == object_link[j].from && aux[i].to == object_link[j].to){
                      if(count==0){
                        count=1;
                      }else{
                          if(rol_text){
                            aux[i].text = aux[i].text + " , " + object_link[j].text;
                          }else{
                            aux[i].text = "";
                          }
                          if(!aux[i].source){
                            aux[i].source = object_link[j].source;
                          }
                        object_link.splice(object_link.indexOf(object_link[j]),1);
                      }
                    }
                  j++;
                  }             
                i++;
              }
              //Insert text in links
              var i=0;
              while (i < object_link.length){
                var j = 0;
                  while (j < object_link.length){
                    if(aux[i].from == object_link[j].from && aux[i].to == object_link[j].to){
                        object_link[j].text = aux[i].text;
                        object_link[j].source = aux[i].source;
                    }
                  j++;
                  }             
                i++;
              }

        diagram.model = new go.GraphLinksModel(object_node, object_link);

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

    };

    var insert_links = function(res,general_text, general_source){
      var object_link = [];
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
            //object_link.push({ from: res.data[i].role, to: res.data[i].status_from });
            var j=0;
            while(j < res.data[i].statuses_to.length){
              if(general_text){
                texto = res.data[i].role;
              }
              if(res.data[i].role_job_type == "static"){
                object_link.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: texto, source: isource[0], selected_text: ""+"\nRol: "+res.data[i].role+"\nFrom: "+res.data[i].status_from+" To: "+res.data[i].statuses_to[j]+"\n Name: "+"\n"  });
              }else if(res.data[i].role_job_type == "promote"){
                object_link.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: texto, source: isource[1], selected_text: ""+"\nRol: "+res.data[i].role+"\nFrom: "+res.data[i].status_from+" To: "+res.data[i].statuses_to[j]+"\n Name: "+"\n"  });
              }else if(res.data[i].role_job_type == "demote"){
                object_link.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: texto, source: isource[2], selected_text: ""+"\nRol: "+res.data[i].role+"\nFrom: "+res.data[i].status_from+" To: "+res.data[i].statuses_to[j]+"\n Name: "+"\n"  });
              }else{
               object_link.push({ from: res.data[i].status_from, to: res.data[i].statuses_to[j], text: texto, source: "", selected_text: ""+"\nRol: "+res.data[i].role+"\nFrom: "+res.data[i].status_from+" To: "+res.data[i].statuses_to[j]+"\n Name: "+"\n"  });
              }


            j++;
            }
      i++;
      }

      //Delete duplicate links
      var i=0;
      var aux = object_link;
      while (i < object_link.length){
        var j = 0;
        var count = 0;
          while (j < object_link.length){
            if(aux[i].from == object_link[j].from && aux[i].to == object_link[j].to){
              if(count==0){
                count=1;
              }else{
                if(general_text){
                  aux[i].text = aux[i].text + " , " + object_link[j].text;
                }else{
                  aux[i].text = "";
                }
                  if(!aux[i].source){
                    aux[i].source = object_link[j].source;
                  }
                object_link.splice(object_link.indexOf(object_link[j]),1);
              }
            }
          j++;
          }             
        i++;
      }
      //Insert text in links
      var i=0;
      while (i < object_link.length){
        var j = 0;
          while (j < object_link.length){
            if(aux[i].from == object_link[j].from && aux[i].to == object_link[j].to){
                object_link[j].text = aux[i].text;
                object_link[j].source = aux[i].source;
            }
          j++;
          }             
        i++;
      }

      return object_link;
    };

    // highlight all Links and Nodes coming out of a given Node
    var showConnections = function(node) {
      var diagram = node.diagram;
      diagram.startTransaction("highlight");
      // remove any previous highlighting
      diagram.clearHighlighteds();
      // for each Link coming out of the Node, set Link.isHighlighted
      node.findLinksOutOf().each(function(l) { l.isHighlighted = true; });
      // for each Node destination for the Node, set Node.isHighlighted
      node.findNodesOutOf().each(function(n) { n.isHighlighted = true; });
      diagram.commitTransaction("highlight");
    };

    //Function make the oposite color to the background
    var change_color = function(hex) {

      var color = hex;
      color = color ? color.substring(1) : 'ffffff';            // remove #
      color = parseInt(color, 16);                              // convert to integer
      color = 0xFFFFFF ^ color;                                 // invert three bytes
      color = color.toString(16);                               // convert to hex
      color = ("000000" + color).slice(-6);                     // pad with leading zeros
      color = "#" + color;                                      // prepend #

      return color;
    };

    var container = new Ext.Panel({
         width: 800,
         height: 600,
         layout: 'absolute', 
         items:[pn_diagram,pn_overview]
    });

    return container;    
});
