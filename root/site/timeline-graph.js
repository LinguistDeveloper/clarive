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
    //mdb->activity->find({ mid => '26777', event_key => 'event.topic.change_status'})->all

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
        bodyStyle:{"z-index":10}
        ,
        floating: true,
        height: 250,
        width: 250,        
        animCollapse: true,
        collapsible: true,
    }
    );
    
    pn_overview.on('afterrender', function() {
        init_overview();
        var left = pn_diagram.container.getWidth() - 250;
        pn_overview.setPosition(left,0);
    }
    );
    

    var init_overview = function(){   

        //if (window.goSamples) goSamples();
        // init for these samples -- you don't need to call this
        var go_api = go.GraphObject.make;

        // a custom routed Link
        function MessageLink() {
            go.Link.call(this);
            this.time = 0;
            // use this "time" value when this is the temporaryLink
        }
            
        go.Diagram.inherit(MessageLink, go.Link);
        
        function ensureLifelineHeights(e) {
            // iterate over all Activities (ignore Groups)
            var arr = diagram.model.nodeDataArray;
            var max = -1;
            for (var i = 0; i < arr.length; i++) {
                var act = arr[i];
                if (act.isGroup) continue;
                max = Math.max(max, act.start + act.duration);
            }
            if (max > 0) {
                // now iterate over only Groups
                for (var i = 0; i < arr.length; i++) {
                    var gr = arr[i];
                    if (!gr.isGroup) continue;
                    if (max > gr.duration) {
                        // this only extends, never shrinks
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
        var MessageSpacing = 20;
        // vertical distance between Messages at different steps
        var ActivityWidth = 10;
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
            // get location of Lifeline's starting point
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
        
        // time is just an abstract small non-negative integer
        // here we map between an abstract time and a vertical position
        function convertTimeToY(t) {
            return t * MessageSpacing + LinePrefix;
        }
        function convertYToTime(y) {
            return (y - LinePrefix) / MessageSpacing;
        }
        
        
        
        /** @override */
        MessageLink.prototype.getLinkPoint = function(node, port, spot, from, ortho, othernode, otherport) {
            var p = port.getDocumentPoint(go.Spot.Center);
            var r = new go.Rect(port.getDocumentPoint(go.Spot.TopLeft),
                                port.getDocumentPoint(go.Spot.BottomRight));
            var op = otherport.getDocumentPoint(go.Spot.Center);
            
            var data = this.data;
            var time = data !== null ? data.time : this.time;
            // if not bound, assume this has its own "time" property
            
            var aw = this.findActivityWidth(node, time);
            var x = (op.x > p.x ? p.x + aw / 2 : p.x - aw / 2);
            var y = convertTimeToY(time);
            return new go.Point(x, y);
        };
        
        MessageLink.prototype.findActivityWidth = function(node, time) {
            var aw = ActivityWidth;
            if (node instanceof go.Group) {
                // see if there is an Activity Node at this point -- if not, connect the link directly with the Group's lifeline
                if (!node.memberParts.any(function(mem) {
                    var act = mem.data;
                    return (act !== null && act.start <= time && time <= act.start + act.duration);
                }
                                         )) {
                    aw = 0;
                }
            }
            return aw;
        };
        
        /** @override */
        MessageLink.prototype.getLinkDirection = function(node, port, linkpoint, spot, from, ortho, othernode, otherport) {
            var p = port.getDocumentPoint(go.Spot.Center);
            var op = otherport.getDocumentPoint(go.Spot.Center);
            var right = op.x > p.x;
            return right ? 0 : 180;
        };
        
        /** @override */
        MessageLink.prototype.computePoints = function() {
            if (this.fromNode === this.toNode) {
                // also handle a reflexive link as a simple orthogonal loop
                var data = this.data;
                var time = data !== null ? data.time : this.time;
                // if not bound, assume this has its own "time" property
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
                return go.Link.prototype.computePoints.call(this);
            }
        }
        
        // end MessageLink        
        
        // a custom LinkingTool that fixes the "time" (i.e. the Y coordinate)
        // for both the temporaryLink and the actual newly created Link
        function MessagingTool() {
            go.LinkingTool.call(this);
            var go_api = go.GraphObject.make;
            this.temporaryLink =
                go_api(MessageLink,
                       go_api(go.Shape, "Rectangle",
                              {
                                  stroke: "magenta", strokeWidth: 2 }
                             ),
                       go_api(go.Shape,
                              {
                                  toArrow: "OpenTriangle", stroke: "magenta" }
                             ));
        };
        go.Diagram.inherit(MessagingTool, go.LinkingTool);
        
        /** @override */
        MessagingTool.prototype.doActivate = function() {
            go.LinkingTool.prototype.doActivate.call(this);
            var time = convertYToTime(this.diagram.firstInput.documentPoint.y);
            this.temporaryLink.time = Math.ceil(time);
            // round up to an integer value
        };
        
        /** @override */
        MessagingTool.prototype.insertLink = function(fromnode, fromport, tonode, toport) {
            var newlink = go.LinkingTool.prototype.insertLink.call(this, fromnode, fromport, tonode, toport);
            if (newlink !== null) {
                var model = this.diagram.model;
                // specify the time of the message
                var start = this.temporaryLink.time;
                var duration = 1;
                newlink.data.time = start;
                model.setDataProperty(newlink.data, "text", "msg");
                // and create a new Activity node data in the "to" group data
                var newact = {
                    group: newlink.data.to,
                    start: start,
                    duration: duration
                };
                model.addNodeData(newact);
                // now make sure all Lifelines are long enough
                ensureLifelineHeights();
            }
            return newlink;
        };
        // end MessagingTool
 
        diagram =
            go_api(go.Diagram, pn_diagram.body.id, // must be the ID or reference to an HTML DIV
                   {
                       initialContentAlignment: go.Spot.Center,
                       allowCopy: false,
                       allowDelete: false,
                       linkingTool: go_api(MessagingTool),  // defined below
                       "resizingTool.isGridSnapEnabled": true,
                       "draggingTool.gridSnapCellSize": new go.Size(1, MessageSpacing/4),
                       "draggingTool.isGridSnapEnabled": false,
                       // automatically extend Lifelines as Activities are moved or resized
                       "SelectionMoved": ensureLifelineHeights,
                       "PartResized": ensureLifelineHeights,
                       "undoManager.isEnabled": false
                   }
                  );
        
        overview =
            go_api(go.Overview, pn_overview.body.id,  // the HTML DIV element for the Overview
                   {
                       
                       observed: diagram, contentAlignment: go.Spot.Center 
                   }
                  );
        // tell it which Diagram to show and pan
        
        // define the Lifeline Node template.
        diagram.groupTemplate =
            go_api(go.Group, "Vertical",
                   {
                       locationSpot: go.Spot.Bottom,
                       locationObjectName: "HEADER",
                       minLocation: new go.Point(0, 0),
                       maxLocation: new go.Point(9999, 0),
                       selectionObjectName: "HEADER"
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
                                     margin: 5, stroke: "white" }
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
                       //locationObjectName: "SHAPE",
                       minLocation: new go.Point(NaN, LinePrefix-ActivityStart),
                       maxLocation: new go.Point(NaN, 19999),
                       selectionObjectName: "SHAPE",
                       resizable: false,
                       //resizeObjectName: "SHAPE",
                       /*resizeAdornmentTemplate:
                       go_api(go.Adornment, "Spot",
                              go_api(go.Placeholder),
                              go_api(go.Shape,  // only a bottom resize handle
                                     {
                                         alignment: go.Spot.Bottom, cursor: "col-resize",
                                         desiredSize: new go.Size(6, 6), fill: "yellow" }
                                    )
                             )*/
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
                      go_api(go.TextBlock, { angle: 90, font: "bold 10px sans-serif", stroke: getLuxColor(color,0.2) }, 
                          new go.Binding("text", "text"),
                          new go.Binding("stroke","black")
                      )
                    )
                  );
        
        // define the Message Link template.
        diagram.linkTemplate =
            go_api(MessageLink,  // defined below
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
                              segmentOffset: new go.Point(110, NaN),
                              stroke: "black",
                              isMultiline: true,
                              editable: false
                          },
                          new go.Binding("text", "text").makeTwoWay()),
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
                   go_api(go.Picture, { width: 28, height: 28, segmentIndex: 0, segmentOffset: new go.Point(NaN, NaN) },
                          new go.Binding("source", "source"))
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
            //var date_ini = new Date(res.data[0].when);
            //var date_end = new Date(res.data[res.data.length-1].when);
            //var range =  date_end.getTime() - date_ini.getTime();

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
                
                /*var sum_dates = date-date2;
                var compose_date = ((date.getTime()-date2.getTime())*10/range)*100;
                duration[i] = compose_date; 
                */
                //var date = new Date('2014-11-03 17:30:46');
                //var date2 = new Date('2014-12-04 17:30:46');
                //var sum_date = date.getDate() - date2.getDate();


                // CALCULATE THE VALUE OF DURATION TO NODES.
                /////////////////////////////////////////////////////////////////////////

                // YEAR         DURATION 15.6 -        
                // MONTH        DURATION 14.4 - 15.6     
                // DAYS         DURATION 8.2 - 14.4      
                // HOURS        DURATION 1 - 8.2 

               var sum_date = date.getFullYear() - date2.getFullYear();
               var date_compare = (date.getMonth()+1) - (date2.getMonth()+1);

               var sum_date2 = date - date2;
               //console.log("esto es");
               //console.log(sum_date2);

                if (sum_date > 1){
                  duration[i]=sum_date+15.6;
                  text[i] = sum_date+" "+_('Year');
                }else{
                  sum_date = (date.getMonth()+1) - (date2.getMonth()+1); 
                  date_compare = date.getDate() - date2.getDate();
                  if(sum_date > 1){
                    duration[i]=(sum_date*0.1)+14.4;
                    text[i] = sum_date+" "+_('Month');
                  }else { 
                    sum_date = date.getDate() - date2.getDate();
                    date_compare = (date.getHours()+1) - (date2.getHours()+1);

                    if (sum_date > 1){
                      duration[i]=(sum_date*0.2)+8.2;
                      text[i] = sum_date+" "+_('Days');
                    }else{
                        sum_date = (date.getHours()+1) - (date2.getHours()+1);

                        if(sum_date > 0){
                          duration[i]= (sum_date*0.3)+1;
                          text[i] = sum_date+" H ";
                        }else{
                          duration[i] = 1;
                          text[i] = " Min ";
                        }
                    }
                  }        

                }
                /////////////////////////////////////////////////////////////////////////
                /*var sum_date = date.getFullYear() - date2.getFullYear();

                if (sum_date > 0){
                  duration[i]=10;
                }else{
                  sum_date = (date.getMonth()+1) - (date2.getMonth()+1); 

                  if(sum_date > 5){
                    duration[i]=9;
                    }else if (sum_date > 2){
                      duration[i]=8;
                      }else if (sum_date > 0){ 
                        duration[i]=7;
                        }else { 
                          sum_date = date.getDate() - date2.getDate();

                          if (sum_date > 14){
                          duration[i]=6;
                          }else if (sum_date > 6){
                            duration[i]=5;
                            }else if (sum_date > 2){
                              duration[i]=4;
                              }else if (sum_date > 1){
                                duration[i]=3;
                                }else{
                                  duration[i]=2;
                                }
                        }        

                }*/
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
        
        /*diagram.model  = new go.GraphLinksModel([ 
            {"key":res.data[0].username, "text":res.data[0].username, "isGroup":true, "loc":"0 0", "duration":res.data.length}
            ,
            {"key":"Bob", "text":"Bob: Waiter", "isGroup":true, "loc":"100 0", "duration":res.data.length}
            ,
            {"key":"Hank", "text":"Hank: Cook", "isGroup":true, "loc":"200 0", "duration":res.data.length}
            ,
            {"key":"Renee", "text":"Renee: Cashier", "isGroup":true, "loc":"300 0", "duration":res.data.length}
            ,
            {"group":"Bob", "start":1, "duration":2, "text": "status"}
            ,
            {"group":"Hank", "start":2, "duration":3}
            ,
            {"group":"Bob", "start":5, "duration":1}
            ,
            {"group":"Bob", "start":6, "duration":2, "key":-9}
            ,
            {"group":"Renee", "start":8, "duration":1, "key":-10}
        ],[ 
            {"from":"Username", "to":"Bob", "text":"name", "time":1}
            ,
            {"from":"Bob", "to":"Hank", "text":"order food", "time":2}
            ,
            {"from":"Bob", "to":"Bob", "text":"serve drinks", "time":3}
            ,
            {"from":"Hank", "to":"Bob", "text":"finish cooking", "time":5}
            ,
            {"from":"Bob", "to":"Username", "text":"serve food", "time":6}
            ,
            {"from":"Username", "to":"Renee", "text":"pay", "time":8}
        ]);*/
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
