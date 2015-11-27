(function(params) {

    mid = params.mid;
    color = params.title;
    var position = color.indexOf("background-color");
    color = color.substring(position+17);
    color = color.substring(0,7);

    var diagram;
    var overview;

    var getLuxColor = function(hex,lum) {

        if ( !hex || hex == null || hex == 'null') return;
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
    return rgb;
    };

    //Zoom +
    var btn_increaseZoom = new Ext.Button({ text: _('Zoom +'), handler: function(){
        diagram.commandHandler.increaseZoom();
    }});

    //Zoom -
    var btn_decreaseZoom = new Ext.Button({ text: _('Zoom -'), handler: function(){
        diagram.commandHandler.decreaseZoom();
    }});

    //PRINCIPAL PANEL
    var pn_diagram = new Ext.Panel({
        html: 'Diagram',
        anchor: '100% 100%',
        tbar:[ btn_decreaseZoom, btn_increaseZoom] 
    }
    );
    
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
    }
    );
    
    pn_overview.on('afterrender', function() {
        start();
        var left = pn_diagram.container.getWidth() - 250;
        pn_overview.setPosition(left,0);
    }
    );    

    var start = function(){

      var go_api = go.GraphObject.make;


      diagram = go_api(go.Diagram, pn_diagram.body.id, // must be the ID or reference to an HTML DIV
                 {
                     initialContentAlignment: go.Spot.Center,
                     allowCopy: false,
                     allowDelete: false,
                     //linkingTool: go_api(MessagingTool),  // defined below
                     "resizingTool.isGridSnapEnabled": true,
                     //"draggingTool.gridSnapCellSize": new go.Size(1, MessageSpacing/4),
                     "draggingTool.isGridSnapEnabled": false,
                     // automatically extend Lifelines as Activities are moved or resized
                     //"SelectionMoved": ensureLifelineHeights,
                     //"PartResized": ensureLifelineHeights,
                     "undoManager.isEnabled": false
                 }
                );
      
      overview = go_api(go.Overview, pn_overview.body.id,  // the HTML DIV element for the Overview
                 {                       
                     observed: diagram, contentAlignment: go.Spot.Center 
                 }
                );
      init_overview(diagram,overview);

    };

    var init_overview = function(diagram,overview){   
        this.diagram = diagram;
        this.overview = overview;

        var go_api = go.GraphObject.make;

        function MessageLink() {
            go.Link.call(this);
            this.time = 0;
        }
            
        go.Diagram.inherit(MessageLink, go.Link);
        
        function ensureLifelineHeights(e) {
            var arr = diagram.model.nodeDataArray;
            var max = -1;
            for (var i = 0; i < arr.length; i++) {
                var act = arr[i];
                if (act.isGroup) continue;
                max = Math.max(max, act.start + act.duration);
            }
            if (max > 0) {
                for (var i = 0; i < arr.length; i++) {
                    var gr = arr[i];
                    if (!gr.isGroup) continue;
                    if (max > gr.duration) {
                        diagram.model.setDataProperty(gr, "duration", max);
                    }
                }
            }
        }
        
        // some parameters
        var LinePrefix = 20;
        // vertical starting point in document for all Messages and Activations
        var LineSuffix = 30;
        // vertical length beyond the last message time
        var MessageSpacing = 25;
        // vertical distance between Messages at different steps
        var ActivityWidth = 15;
        // width of each vertical activity bar
        var ActivityStart = 5;
        // height before start message time
        var ActivityEnd = 5;
        // height beyond end message time
        
        function computeLifelineHeight(duration) {
          return LinePrefix + duration * MessageSpacing + LineSuffix;
        }
        
        function computeActivityLocation(act) {
          var groupdata = diagram.model.findNodeDataForKey(act.group);
          if (groupdata === null) return new go.Point();
          var grouploc = go.Point.parse(groupdata.loc);
          return new go.Point(grouploc.x, convertTimeToY(act.start) - ActivityStart);
        }

        function backComputeActivityLocation(loc, act) {
          diagram.model.setDataProperty(act, "start", convertYToTime(loc.y + ActivityStart));
        }
        
        function computeActivityHeight(duration) {
          return ActivityStart + duration * MessageSpacing + ActivityEnd;
        }

        function backComputeActivityHeight(height) {
          return (height - ActivityStart - ActivityEnd) / MessageSpacing;
        }
        
        function convertTimeToY(t) {
          return t * MessageSpacing + LinePrefix;
        }

        function convertYToTime(y) {
          return (y - LinePrefix) / MessageSpacing;
        }
                
        /** @override */
        MessageLink.prototype.getLinkPoint = function(node, port, spot, from, ortho, othernode, otherport) {
          var p = port.getDocumentPoint(go.Spot.Center);
          var r = new go.Rect(port.getDocumentPoint(go.Spot.TopLeft), port.getDocumentPoint(go.Spot.BottomRight));
          var op = otherport.getDocumentPoint(go.Spot.Center);
          
          var data = this.data;
          var time = data !== null ? data.time : this.time;
          
          var aw = this.findActivityWidth(node, time);
          var x = (op.x > p.x ? p.x + aw / 2 : p.x - aw / 2);
          var y = convertTimeToY(time);
          return new go.Point(x, y);
        };
        
        MessageLink.prototype.findActivityWidth = function(node, time) {
          var aw = ActivityWidth;
          if (node instanceof go.Group) {
              if (!node.memberParts.any(function(mem) {
                  var act = mem.data;
                  return (act !== null && act.start <= time && time <= act.start + act.duration);
              })) {
                  aw = 0;
              }
          }
          return aw;
        };

        MessageLink.prototype.getLinkDirection = function(node, port, linkpoint, spot, from, ortho, othernode, otherport) {
          var p = port.getDocumentPoint(go.Spot.Center);
          var op = otherport.getDocumentPoint(go.Spot.Center);
          var right = op.x > p.x;
          return right ? 0 : 180;
        };

        MessageLink.prototype.computePoints = function() {
          if (this.fromNode === this.toNode) {
              var data = this.data;
              var time = data !== null ? data.time : this.time;

              var p = this.fromNode.port.getDocumentPoint(go.Spot.Center);
              var aw = this.findActivityWidth(this.fromNode, time);
              
              var x = p.x + aw / 2;
              var y = convertTimeToY(time);
              this.clearPoints();
              this.addPoint(new go.Point(x, y));
              this.addPoint(new go.Point(x + 50, y));
              this.addPoint(new go.Point(x + 50, y + 5));
              this.addPoint(new go.Point(x, y + 5));
              return true;
          }
          else {
            try {
              return go.Link.prototype.computePoints.call(this);
            }
            catch(err) {
              console.log("aqui salta un error");
              //init_overview(panel.diagram, panel.overview);
            }        
          }
        }
        
        // define the Lifeline Node template.
        diagram.groupTemplate =
            go_api(go.Group, "Vertical",
                   {
                       locationSpot: go.Spot.Bottom,
                       locationObjectName: "HEADER",
                       minLocation: new go.Point(0, 0),
                       maxLocation: new go.Point(9999, 0),
                       selectionObjectName: "HEADER",
                       movable: false
                   }
                   ,
                   new go.Binding("location", "loc", go.Point.parse).makeTwoWay(go.Point.stringify),
                   go_api(go.Panel, "Auto",
                          {
                              name: "HEADER" }
                          ,
                          go_api(go.Shape, "Rectangle",
                                 {
                                     fill: color, stroke: "white" }
                                ),
                          go_api(go.TextBlock,
                                 {
                                     margin: 10, stroke: "white" }
                                 ,
                                 new go.Binding("text", "text"))
                         ),
                   go_api(go.Shape,
                          {
                              figure: "LineV",
                              fill: null,
                              stroke: getLuxColor(color,0.2),
                              strokeDashArray: [3, 3],
                              width: 1,
                              alignment: go.Spot.Center,
                              portId: "",
                              fromLinkable: false,
                              fromLinkableDuplicates: false,
                              toLinkable: false,
                              toLinkableDuplicates: false,
                              cursor: "pointer"
                          }
                          ,
                          new go.Binding("height", "duration", computeLifelineHeight))
                  );
        
        // define the Activity Node template
        diagram.nodeTemplate =
            go_api(go.Node,
                   {
                       locationSpot: go.Spot.Top,
                       minLocation: new go.Point(NaN, LinePrefix-ActivityStart),
                       maxLocation: new go.Point(NaN, 19999),
                       selectionObjectName: "SHAPE",
                       resizable: false,
                       movable: false
                   }
                   ,
                   new go.Binding("location", "", computeActivityLocation).makeTwoWay(backComputeActivityLocation),
                   go_api(go.Panel, "Auto",

                      go_api(go.Shape, "Rectangle",
                            {
                                name: "SHAPE",
                                fill: "white", stroke: "black",
                                width: ActivityWidth,
                                // allow Activities to be resized down to 1/4 of a time unit
                                minSize: new go.Size(ActivityWidth, computeActivityHeight(0.50))
                            },
                            new go.Binding("height", "duration", computeActivityHeight).makeTwoWay(backComputeActivityHeight)),
                      go_api(go.TextBlock, { angle: 90, font: "bold 11px sans-serif", stroke: "black"  },
                          new go.Binding("text", "text"),
                          new go.Binding("stroke","black")
                      )
                    )
                  );
        
        // define the Message Link template.
        diagram.linkTemplate =
            go_api(MessageLink,  
                   {
                       selectionAdorned: true, 
                       curviness: 0 
                   },
                   go_api(go.Shape, "Rectangle",
                          {
                              stroke: "black" }
                         ),
                   go_api(go.Shape,
                          {
                              toArrow: "OpenTriangle", stroke: "black" }
                         ),
                   go_api(go.TextBlock,
                          {
                              segmentIndex: 0,
                              segmentOffset: new go.Point(110, 20),
                              stroke: "black",
                              isMultiline: true,
                              editable: false
                          },
                          new go.Binding("text", "text").makeTwoWay()),
                   go_api(go.Picture, { width: 28, height: 28, segmentIndex: 0, segmentOffset: new go.Point(NaN, 20) },
                          new go.Binding("source", "source")),
                   go_api(go.TextBlock,{
                          visible: false,
                          textAlign: "center",
                          font: "bold 10px sans-serif",
                          margin: 2,
                          segmentOffset: new go.Point(25, -25)
                          },
                          new go.Binding("visible", "isSelected", function(b) { return b ? true : false; }).ofObject(),
                          new go.Binding("text", "selected_text"),
                          new go.Binding("stroke", "isSelected", function(b) { return b ? "#FFFFFF" : "transparent"; }).ofObject(),
                          new go.Binding("background", "isSelected", function(b) { return b ? "#1E90FF" : "transparent"; }).ofObject())
                  );
        
        // create the graph by reading the JSON data saved in "mySavedModel" textarea element         
        Baseliner.ajaxEval( '/topic/list_status_changes', {mid: mid}, function(res) {

            //Order data for creation date.
            for(i=0;i<res.data.length-1;i++){
                 for(j=0;j<res.data.length-1;j++){
                     var date = new Date(res.data[j].when);
                     var date2 = new Date(res.data[j+1].when);
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

            //delete the duplicate steps in the same statuses
            for(i=0;i<res.data.length-1;i++){
              var datas = res.data[i];
              var datas2 = res.data[i+1];
              if(datas.old_status == datas2.old_status && datas.status == datas2.status && datas.username == datas2.username){
                var date = new Date(res.data[i].when);
                var date2 = new Date(res.data[i+1].when);
                if (date.getFullYear() == date2.getFullYear() && date.getMonth() == date2.getMonth() && date.getDate() == date2.getDate() && date.getHours() == date2.getHours()){
                  res.data.splice(res.data.indexOf(res.data[i]),1);
                }
              }

            }
            
            var object_node = [];          

            //Create group of nodes for status
            var i=0;
            var locx=200;
            var local =0;
            while (i < res.data.length){

                if (object_node.length==0){
                  object_node.push({ "key" : res.data[i].old_status, "text"  : res.data[i].old_status, "isGroup":true, "loc": "0 0", "duration":"change"});
                  object_node.push({ "key" : res.data[i].status, "text"  : res.data[i].status, "isGroup":true, "loc": "200 0", "duration":"change"});
                }else{
                  var j=0;
                  var equal = 1;
                  while(j < object_node.length){

                    if(object_node[j].key == res.data[i].status){
                      j= object_node.length;
                      equal = 0;
                    }
                   j++;
                  }
                  if(equal!=0){
                    locx=locx+200;
                    object_node.push({ "key" : res.data[i].status, "text"  : res.data[i].status, "isGroup":true, "loc": locx + " 0", "duration":"change"});
                  }

                }
            i++;

            }

            //create nodes timeline for user and status
            var i=0;
            var start = [];
            var duration = [];
            var text = [];
            var sum_duration = 0;

            while (i < res.data.length){

              if(i==0){
                start[i]=1;
                duration[i]=1;
                text[i]= "start";
                sum_duration = sum_duration + duration[i];
                object_node.push({ "group" : res.data[i].status, "start":start[i], "duration":duration[i], "key": -(i+res.data.length)});
              }else{
                start[i] = start[i-1] + duration[i-1];
                var date = new Date(res.data[i].when);
                var date2 = new Date(res.data[i-1].when);

                // CALCULATE THE VALUE OF DURATION TO NODES.
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                // YEAR         DURATION 16.6 -        
                // MONTH        DURATION 15.4 - 16.6     
                // DAYS         DURATION 9.2 - 15.4      
                // HOURS        DURATION 2 - 9.2 

                var sum_date = date.getTime() - date2.getTime();
                var date_compare = date.getFullYear() - date2.getFullYear();
                var leap_calculate = date_compare % 4; 
                var number_text = 0;
                var leap_year = 31622400000;
                var year = 31536000000;
                var leap_month = 2505600000;
                var february_month = 2419200000;
                var thirty_month = 2592000000;
                var month = 2678400000;
                var day = 86400000;
                var hours = 3600000; 
                var min = 60000;

                //leap-year
                if (leap_calculate == 0 && sum_date >= leap_year){

                  number_text = sum_date / leap_year;
                  number_text = Math.round(number_text);
                  if(number_text == 0){ number_text = 1;}

                  duration[i]=number_text+20.6;
                  text[i] = number_text+" "+_('Year');

                }else{
                  //year
                  if(sum_date >= year){

                    number_text = sum_date / year;
                    number_text = Math.round(number_text);
                    if(number_text == 0){ number_text = 1;}

                    duration[i]=number_text+20.6;
                    text[i] = number_text+" "+_('Year');

                  }else{
                    //Month with 31 days
                    date_compare = (date.getMonth()+1) - (date2.getMonth()+1);
                    if((date_compare == 1 || date_compare == 3 || date_compare == 5 || date_compare == 7 || date_compare == 8 || date_compare == 10 || date_compare == 12) && sum_date >= month){
                      
                      number_text = sum_date / month;
                      number_text = Math.round(number_text);
                      if(number_text == 0){ number_text = 1;}  

                      duration[i]=(number_text*0.1)+18.4;
                      number_text = new Date(sum_date);  
                      var hour = (number_text.getHours()-1);      
                      if (hour < 10){ hour = "0"+(number_text.getHours()-1)} 
                      var minutes = number_text.getMinutes();
                      if (minutes < 10){ minutes = "0"+number_text.getMinutes()}   
                      text[i] = number_text.getMonth()+" "+_('Month')+" "+  (number_text.getDate()-1) +" "+_('Days')+" " + hour +":"+ minutes +" H ";

                    }else {
                      //Month with 30 days
                      if((date_compare == 4 || date_compare == 6 || date_compare == 9 || date_compare == 11) && sum_date >= thirty_month){

                        number_text = sum_date / thirty_month;
                        number_text = Math.round(number_text);
                        if(number_text == 0){ number_text = 1;}   
                                             
                        duration[i]=(number_text*0.1)+18.4;
                        number_text = new Date(sum_date);  
                        var hour = (number_text.getHours()-1);      
                        if (hour < 10){ hour = "0"+(number_text.getHours()-1)} 
                        var minutes = number_text.getMinutes();
                        if (minutes < 10){ minutes = "0"+number_text.getMinutes()}   
                        text[i] = number_text.getMonth()+" "+_('Month')+" "+  (number_text.getDate()-1) +" "+_('Days')+" " + hour +":"+ minutes +" H ";

                      }else{
                        //Leap-Month
                        if(leap_calculate == 0 && date_compare == 2 && sum_date >= leap_month ){

                          number_text = sum_date / leap_month;
                          number_text = Math.round(number_text);
                          if(number_text == 0){ number_text = 1;}      

                          duration[i]=(number_text*0.1)+18.4;
                          number_text = new Date(sum_date);  
                          var hour = (number_text.getHours()-1);      
                          if (hour < 10){ hour = "0"+(number_text.getHours()-1)} 
                          var minutes = number_text.getMinutes();
                          if (minutes < 10){ minutes = "0"+number_text.getMinutes()}   
                          text[i] = number_text.getMonth()+" "+_('Month')+" "+  (number_text.getDate()-1) +" "+_('Days')+" " + hour +":"+ minutes +" H ";

                        }else{
                          //February Month
                          if(date_compare == 2 && sum_date >= february_month){

                            number_text = sum_date / february_month;
                            number_text = Math.round(number_text);
                            if(number_text == 0){ number_text = 1;}

                            duration[i]=(number_text*0.1)+18.4;
                            number_text = new Date(sum_date);  
                            var hour = (number_text.getHours()-1);      
                            if (hour < 10){ hour = "0"+(number_text.getHours()-1)} 
                            var minutes = number_text.getMinutes();
                            if (minutes < 10){ minutes = "0"+number_text.getMinutes()}   
                            text[i] = number_text.getMonth()+" "+_('Month')+" "+  (number_text.getDate()-1) +" "+_('Days')+" " + hour +":"+ minutes +" H ";

                          }else{
                            //Days
                            if(sum_date >= day){

                              number_text = sum_date / day;
                              number_text = Math.round(number_text);
                              if(number_text == 0){ number_text = 1;}

                              duration[i]=(number_text*0.2)+12.2;
                              number_text = new Date(sum_date);  
                              var hour = (number_text.getHours()-1);      
                              if (hour < 10){ hour = "0"+(number_text.getHours()-1)} 
                              var minutes = number_text.getMinutes();
                              if (minutes < 10){ minutes = "0"+number_text.getMinutes()}   
                              text[i] = (number_text.getDate()-1) +" "+_('Days')+" " + hour+":"+minutes+" H ";

                            }else{
                              //Hours
                              if(sum_date >= hours){

                                number_text = sum_date / hours;
                                number_text = Math.round(number_text);
                                if(number_text == 0){ number_text = 1;}

                                duration[i]= (number_text*0.3)+4;
                                number_text = new Date(sum_date);  
                                var hour = (number_text.getHours()-1);      
                                if (hour < 10){ hour = "0"+(number_text.getHours()-1)} 
                                var minutes = number_text.getMinutes();
                                if (minutes < 10){ minutes = "0"+number_text.getMinutes()}     
                                text[i] = hour+":"+minutes+" H ";

                              //Minutes
                              }else{

                                number_text = sum_date / min;
                                number_text = Math.round(number_text);
                                if(number_text == 0){ number_text = 1;}

                                duration[i] = 3;
                                number_text = new Date(sum_date);    
                                var minutes = number_text.getMinutes();
                                if (minutes < 10){ minutes = "0"+number_text.getMinutes()}
                                var seconds = number_text.getSeconds();      
                                if (seconds < 10){ seconds = "0"+number_text.getSeconds()}                
                                text[i] = minutes+":"+ seconds +" Min ";

                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                sum_duration = sum_duration + duration[i];
                object_node.push({ "group" : res.data[i].status, "start":start[i], "duration":duration[i], "key": -(i+res.data.length), "text": text});
              }
              i++;

            }

            //Modify the duration in the nodes.
            duration.push(1);
            duration.splice(duration.indexOf(duration[0]),1);
            text.push("");
            text.splice(text.indexOf(text[0]),1);
            var i=0;
            var j=0;
            while (i < object_node.length){
              if(object_node[i].duration=="change"){
                object_node[i].duration = sum_duration;

              }else{
                if(j==0){
                  start[j]= 1;
                  object_node[i].duration = duration[j];
                  object_node[i].text = text[j];
                  object_node[i].start = start[j];
                }else{
                  start[j]= start[j-1]+duration[j-1];
                  object_node[i].duration = duration[j];
                  object_node[i].text = text[j];             
                  object_node[i].start = start[j];
                }
                j++;
              }  
            i++;

            }

            //create links
            var i=0;
            var object_link = [];
            var source;
            while (i < res.data.length){
              source = "/user/avatar/"+res.data[i].username+"/image.png";
              object_link.push({"from":res.data[i].old_status, "to":res.data[i].status, "source": source ,"text": "user: "+res.data[i].username+ "\n date: "+Cla.user_date(res.data[i].when), "time":start[i], selected_text: ""+"\nUser: "+res.data[i].username+"\nFrom: "+res.data[i].old_status+" To: "+res.data[i].status+"\nTime: "+Cla.user_date(res.data[i].when)+"\n Name: "+"\n"  });
              i++;

            }

        diagram.model  = new go.GraphLinksModel(object_node,object_link);

    });            
    };   
    
    var container = new Ext.Panel({
        width: 800,
        height: 600,
        layout: 'absolute', 
        items:[pn_diagram,pn_overview]
    }
    );
    return container;    
}
);

