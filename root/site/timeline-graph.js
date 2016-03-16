(function(params) {

    var mid = params.mid;
    var self = params.self;

    var color = "#000000" ;
    var color_position = params.title.indexOf("background-color:");
    if (color_position > 0) {
        var color_substring = params.title.substring(color_position + 17, color_position + 17 + 7);

        var color_regex = /^(#[0-9a-f]{3,6})/i;
        var matches = color_regex.exec(color_substring);

        if (matches && matches.length == 2) {
            color = matches[1];
        }
    }

    var diagram;
    var overview;
    var event_details_text = false;
    var checked_event_details= false;

    var getLuxColor = function(hex,lum) {

        if ( !hex || hex === null || hex == 'null') return;
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

    //Create the checkitems to the option menu.
    var event_details = new Ext.menu.CheckItem({
      text: _('Event details'), checked: false, checkHandler: function(){
        if(!checked_event_details){
          event_details_text=this.checked;
          try {
            init_overview(pn_diagram.diagram, pn_overview.overview);
          }
          catch(err) {
            container.destroy();
            Baseliner.ajaxEval('/comp/topic/topic_lib.js',{self: pn_diagram.self}, function(){ pn_diagram.self.show_timeline();});
          }
        }
      }
      });

    // Option menu to General Button
    var options_menu = new Ext.Button({
        text: _('Options'), icon: IC('timeline'), menu:{
            items: [ event_details ]
        }
    });

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
        tbar:[ options_menu, '-', btn_decreaseZoom, btn_increaseZoom]

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

        start();
        var left = pn_diagram.container.getWidth() - 250;
        pn_overview.setPosition(left,0);

    });

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

      pn_diagram.diagram = diagram;
      pn_diagram.self = self;
      pn_overview.overview = overview;

      init_overview(diagram,overview);
    };

    init_overview = function(diagram,overview){

        this.diagram = diagram;
        this.overview = overview;
        var win = 0;
        var temp_nodes = [];
        var object_node = [];
        var object_link = [];
        var source;
        var timer_nodes = [];
        var start = [];
        var duration = [];
        var text = [];
        var sum_duration = 0;
        var go_api = go.GraphObject.make;
        // some parameters
        var LinePrefix = 20;
        // vertical starting point in document for all Messages and Activations
        var LineSuffix = 30;
        // vertical length beyond the last message time
        var MessageSpacing = 25;
        // vertical distance between Messages at different steps
        var ActivityWidth = 15;
        // width of each vertical activity bar
        var ActivityStart = 0;
        // height before start message time
        var ActivityEnd = 5;
        // height beyond end message time
        var ActivityStart2 = 1;
        var ActivityEnd2 = 1;
        //var MessegeSpacing2 = 1;

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
              for (i = 0; i < arr.length; i++) {
                  var gr = arr[i];
                  if (!gr.isGroup) continue;
                  if (max > gr.duration) {
                      diagram.model.setDataProperty(gr, "duration", max);
                  }
              }
          }
        }

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

        function computeActivityHeight2(duration) {
          return ActivityStart2 + duration + ActivityEnd2;
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

        function showMessage(e, obj) {

          if(win !== 0){
            win.destroy();
          }

            var text = "no datas";
            if(obj.Eh.data_type == "topic_modify"){
              text = _(obj.Eh.data_text,obj.Eh.data_username,obj.Eh.data_field,obj.Eh.data_old_value,obj.Eh.data_new_value);
            }else if(obj.Eh.data_type == "event_post"){
              text = _(obj.Eh.data_text,obj.Eh.data_username,'',obj.Eh.data_post);
            }else if(obj.Eh.data_type == "event_file"){
              text = _(obj.Eh.data_text,obj.Eh.data_username,'',obj.Eh.data_filename);
            }else{
              text = _('Data type is not defined');
            }
            if(obj.Eh.data_username !== undefined && obj.Eh.data_when !== undefined){
                win = new Ext.Window({
                title: obj.Eh.group,
                layout: 'fit',
                autoScroll: true,
                width: 400,
                height: 200,
                modal: false,
                closeAction: 'hide',
                items: [new Baseliner.MonoTextArea({ value:  '\n'+'\n'+_('Event type')+': ' + obj.Eh.data_type +'\n' +_('Username')+': ' + obj.Eh.data_username +'\n' +_('Date')+': ' + Cla.user_date(obj.Eh.data_when) +'\n'  +_('Details')+': '+'\n' +text+'\n' })]
              });
              win.show();
            }
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
        };

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
               },
               new go.Binding("location", "loc", go.Point.parse).makeTwoWay(go.Point.stringify),
               go_api(go.Panel, "Auto",
                      {
                          name: "HEADER"
                      },
                      go_api(go.Shape, "Rectangle",
                        {
                           fill: color, stroke: "white"
                        }
                      ),
                      go_api(go.TextBlock,
                        {
                          margin: 10, stroke: "white"
                        },
                       new go.Binding("text", "text")
                      )
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
                      },
                      new go.Binding("height", "duration", computeLifelineHeight)
                )
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
                   },
                   new go.Binding("location", "", computeActivityLocation).makeTwoWay(backComputeActivityLocation),
                   go_api(go.Panel, "Auto",
                      go_api(go.Shape, "Rectangle",
                            {
                                name: "SHAPE",
                                //fill: "transparent", stroke: "green",
                                width: ActivityWidth,
                                // allow Activities to be resized down to 1/4 of a time unit
                                minSize: new go.Size(ActivityWidth, computeActivityHeight(0))
                            },
                            new go.Binding("fill", "fill"),
                            new go.Binding("stroke", "stroke"),
                            new go.Binding("height", "duration", function(h) { if (h > 0) { h = computeActivityHeight(h); }else{ h = computeActivityHeight2(h); } return h; }).makeTwoWay(backComputeActivityHeight)
                      ),
                      go_api(go.TextBlock, { angle: 90, font: "bold 11px sans-serif", stroke: "black"  },
                          new go.Binding("text", "text"),
                          new go.Binding("stroke","black")
                      )
                    ),
                    {
                      cursor: "pointer",
                      click: showMessage
                    }
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
        Baseliner.ajaxEval( '/topic/timeline_list_status_changes', {mid: mid}, function(res) {

            var j = 0;
            //add status to nodes
            status_into_nodes(res);

            //Create group of nodes for status
            group_for_status(object_node,res);

            //create nodes timeline for user and status
            sum_duration = create_nodes_timeline(object_node, res, start, duration, text, sum_duration);

            //Modify the duration in the nodes.
            duration.push(1);
            duration.splice(duration.indexOf(duration[0]),1);
            text.push("");
            text.splice(text.indexOf(text[0]),1);
            modify_duration(object_node, start, duration, text, sum_duration);

            //This is the new part with the elements like comments, files updates and topics changes.
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            if(event_details_text === true){

              sum_duration = create_intermidial_nodes_activity(object_node, res, sum_duration, start);

            }
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            //create links
            for (var i = 0; i < res.data.length; i++){

              source = "/identicon/"+res.data[i].username+".png";

              if ((res.data[i].data_type == "create" || res.data[i].data_type == "change_status") && res.data[i].status ){

                object_link.push({"from":res.data[i].old_status, "to":res.data[i].status, "source": source ,"text": _('Username') + " : "+res.data[i].username+ "\n" + _('Date') + ": "+Cla.user_date(res.data[i].when), "time":start[j], selected_text: ""+"\n"+ _('Username') + ": "+res.data[i].username+"\n"+ _('from') + ": "+res.data[i].old_status+" "+ _('to') + ": "+res.data[i].status+"\n"+ _('Date') + ": "+Cla.user_date(res.data[i].when)+"\n"+ _('Name') + ": "+"\n"  });

                j++;

              }

            }

			if(object_link.length > 0 && object_node.length > 0){

				diagram.model = new go.GraphLinksModel(object_node,object_link);

			}

    });
    };

    function status_into_nodes(res) {

      var temp_status = [];
      var i;
      var j;

      for (i = 0; i < res.data.length; i++){

        if(res.data[i].data_type == "create" || res.data[i].data_type == "change_status"){

          temp_status.push({ "old_status" : res.data[i].old_status, "status"  : res.data[i].status, "when" : res.data[i].when});

        }
      }
      for (i = 0; i < res.data.length; i++){

        if(res.data[i].data_type == "topic_modify" || res.data[i].data_type == "event_post" || res.data[i].data_type == "event_file"){

          j = 0;

          while ( j < temp_status.length){

            if( new Date(res.data[i].when) <= new Date(temp_status[j].when)){

              res.data[i].status = temp_status[j].status;
              res.data[i].old_status = temp_status[j].old_status;
              j = temp_status.length;

            }

            j++;

          }
        }
      }
    }

    function group_for_status(object_node, res){
      var locx = 240;
      var equal;
      for(i = 0; i < res.data.length; i++){
        if(res.data[i].data_type == "create" || res.data[i].data_type == "change_status"){
          if (object_node.length === 0){
            object_node.push({ "group": "title", "key" : res.data[i].old_status, "text"  : res.data[i].old_status, "isGroup":true, "loc": "0 0", "duration":"change"});
            object_node.push({ "group": "title", "key" : res.data[i].status, "text"  : res.data[i].status, "isGroup":true, "loc": "240 0", "duration":"change"});
          }else{
            j=0;
            equal = 1;
            while(j < object_node.length){
              if(object_node[j].key == res.data[i].status){
                j= object_node.length;
                equal = 0;
              }
             j++;
            }
            if(equal !== 0){
              locx=locx+240;
              object_node.push({ "group": "title", "key" : res.data[i].status, "text"  : res.data[i].status, "isGroup":true, "loc": locx + " 0", "duration":"change"});
            }
          }
        }
      }
    }

    function create_nodes_timeline(object_node, res, start, duration, text, sum_duration){

      var LEAP_YEAR = 31622400000;
      var YEAR = 31536000000;
      var LEAP_MONTH = 2505600000;
      var FEBRUARY_MONTH = 2419200000;
      var THIRTY_MONTH = 2592000000;
      var MONTH = 2678400000;
      var DAY = 86400000;
      var HOURS = 3600000;
      var MIN = 60000;
      var j = 0;
      var i;
      var hour;
      var minutes;
      var seconds;
      var before_index = 0;
      var date;
      var date2;
      var sum_date;
      var leap_calculate;
      var number_text;
      var date_compare;

      for(i = 0; i < res.data.length; i++){

        if(res.data[i].data_type == "create" || res.data[i].data_type == "change_status"){

          if(j === 0){

            start[j] = 1;
            duration[j] = 1;
            text[j] = "start";
            sum_duration = sum_duration + duration[j];
            object_node.push({ "group" : res.data[i].status, "start":start[j], "duration":duration[j], "key": -(i+res.data.length), "when": res.data[i].when, "fill": "white", "stroke": "black"});
            before_index = i;
            j++;

          }else{

            start[j] = start[j-1] + duration[j-1];
            date = new Date(res.data[i].when);
            date2 = new Date(res.data[before_index].when);
            before_index = i;

            // CALCULATE THE VALUE OF DURATION TO NODES.
            //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // YEAR         DURATION 20.6 -
            // MONTH        DURATION 18.4 - 20.6
            // DAYS         DURATION 12.2 - 18.4
            // HOURS        DURATION 2 - 12.2
            sum_date = date.getTime() - date2.getTime();
            date_compare = date.getFullYear() - date2.getFullYear();
            leap_calculate = date_compare % 4;
            number_text = 0;
            hour = 0;
            minutes = 0;

            //leap-year
            if (leap_calculate === 0 && sum_date >= LEAP_YEAR){

              number_text = calculate_number_text(sum_date, LEAP_YEAR);
              duration[j] = number_text + 20.6;
              text[j] = number_text + " " + _('Year');

            }else{
              //year
              if(sum_date >= YEAR){

                number_text = calculate_number_text(sum_date, YEAR);
                duration[j] = number_text + 20.6;
                text[j] = number_text + " " + _('Year');

              }else{

                //Month with 31 days
                date_compare = (date.getMonth() + 1) - (date2.getMonth() + 1);
                if((date_compare == 1 || date_compare == 3 || date_compare == 5 || date_compare == 7 || date_compare == 8 || date_compare == 10 || date_compare == 12) && sum_date >= MONTH){

                  number_text = calculate_number_text(sum_date, MONTH);
                  duration[j] = (number_text * 0.1) + 18.4;

                  number_text = new Date(sum_date);
                  hour = calculate_hour(number_text);
                  minutes = calculate_minutes(number_text);
                  text[j] = number_text.getMonth() + " " + _('Month') + " " +  (number_text.getDate() - 1) +" " + _('Days') + " " + hour +":"+ minutes +" H ";

                }else {
                  //Month with 30 days
                  if((date_compare == 4 || date_compare == 6 || date_compare == 9 || date_compare == 11) && sum_date >= THIRTY_MONTH){

                    number_text = calculate_number_text(sum_date, THIRTY_MONTH);
                    duration[j] = (number_text * 0.1) + 18.4;

                    number_text = new Date(sum_date);
                    hour = calculate_hour(number_text);
                    minutes = calculate_minutes(number_text);
                    text[j] = number_text.getMonth() + " " + _('Month') + " " +  (number_text.getDate()-1) + " " + _('Days') + " " + hour + ":" + minutes + " H ";

                  }else{
                    //Leap-Month
                    if(leap_calculate === 0 && date_compare == 2 && sum_date >= LEAP_MONTH ){

                      number_text = calculate_number_text(sum_date, LEAP_MONTH);
                      duration[j]=(number_text*0.1)+18.4;
                      number_text = new Date(sum_date);
                      hour = calculate_hour(number_text);
                      minutes = calculate_minutes(number_text);
                      text[j] = number_text.getMonth() + " " + _('Month') + " " + (number_text.getDate()-1) + " " + _('Days') + " " + hour + ":" + minutes + " H ";

                    }else{
                      //February Month
                      if(date_compare == 2 && sum_date >= FEBRUARY_MONTH){

                        number_text = calculate_number_text(sum_date, FEBRUARY_MONTH);
                        duration[j] = (number_text * 0.1) + 18.4;
                        number_text = new Date(sum_date);
                        hour = calculate_hour(number_text);
                        minutes = calculate_minutes(number_text);
                        text[j] = number_text.getMonth() + " " + _('Month') + " " +  (number_text.getDate()-1) + " " + _('Days') + " " + hour + ":" + minutes + " H ";
                      }else{
                        //Days
                        if(sum_date >= DAY){

                          number_text = calculate_number_text(sum_date, DAY);
                          duration[j] = (number_text * 0.2) + 12.2;
                          number_text = new Date(sum_date);
                          hour = calculate_hour(number_text);
                          minutes = calculate_minutes(number_text);
                          text[j] = (number_text.getDate() - 1) + " " + _('Days') + " " + hour + ":" + minutes + " H ";

                        }else{
                          //Hours
                          if(sum_date >= HOURS){

                            number_text = calculate_number_text(sum_date, HOURS);
                            duration[j]= (number_text*0.3)+4;
                            number_text = new Date(sum_date);
                            hour = calculate_hour(number_text);
                            minutes = calculate_minutes(number_text);
                            text[j] = hour + ":" + minutes + " H ";

                          //Minutes
                          }else{

                            number_text = calculate_number_text(sum_date, MIN);
                            duration[j] = 3;
                            number_text = new Date(sum_date);
                            minutes = calculate_minutes(number_text);
                            seconds = calculate_seconds(number_text);
                            text[j] = minutes + ":" + seconds + " Min ";

                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            sum_duration = sum_duration + duration[j];
            object_node.push({ "group" : res.data[i].status, "start":start[j], "duration":duration[j], "key": -(i+res.data.length), "when": res.data[i].when, "text": text, "fill": "white", "stroke": "black"});
            j++;
          }
        }
      }
      return sum_duration;
    }

    function modify_duration(object_node, start, duration, text, sum_duration){

      var j = 0;
      var i;

      for(i = 0; i < object_node.length; i++){
        if(object_node[i].duration == "change"){
          if(event_details_text !== true){
            object_node[i].duration = sum_duration;
          }
        }else{
          if(j === 0){
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
      }
    }

    function calculate_number_text(sum_date, date){
      var number_text = 0;
      number_text = sum_date / date;
      number_text = Math.round(number_text);
      if(number_text === 0){
        number_text = 1;
      }
      return number_text;
    }

    function calculate_hour (number_text){

      var hour;
      hour = (number_text.getHours()-1);
      if (hour < 10){
        hour = "0" + (number_text.getHours() - 1);
      }
      return hour;

    }

    function calculate_minutes (number_text){

      var minutes;
      minutes = number_text.getMinutes();
      if (minutes < 10){
        minutes = "0" + number_text.getMinutes();
      }
      return minutes;

    }

    function calculate_seconds (number_text){

      var seconds;
      seconds = number_text.getSeconds();
      if (seconds < 10){
        seconds = "0" + number_text.getSeconds();
      }
      return seconds;

    }

    function calculate_duration_node(res, duration_node, aux_count_nodes){

      var CALCULATE_MIN = 600000;
      var CALCULATE_HOUR = 3600000;
      var CALCULATE_DAY = 86400000;
      var CALCULATE_MONTH = 2678400000;
      var CALCULATE_YEAR = 31536000000;

      if(duration_node < 4){
        aux_count_nodes = (new Date(res.data[j].when) - new Date(res.data[j-1].when))/CALCULATE_MIN;
      }else if(duration_node < 12){
        aux_count_nodes = (new Date(res.data[j].when) - new Date(res.data[j-1].when))/CALCULATE_HOUR;
      }else if(duration_node < 18){
        aux_count_nodes = (new Date(res.data[j].when) - new Date(res.data[j-1].when))/CALCULATE_DAY;
      }else if(duration_node < 21){
        aux_count_nodes = (new Date(res.data[j].when) - new Date(res.data[j-1].when))/CALCULATE_MONTH;//86400000
      }else{
        aux_count_nodes = (new Date(res.data[j].when) - new Date(res.data[j-1].when))/CALCULATE_YEAR;//86400000
      }
      return aux_count_nodes;
    }

    function create_intermidial_nodes_activity(object_node, res, sum_duration, start){

      var j = 0;
      var i;
      var change_stroke = "black";
      var color_green = "#008000";
      var color_red = "#ff0000";
      var color_blue = "#0066ff";
      var count_nodes = 0;
      var count_nodes_2 = 0;
      var last_node = object_node[object_node.length-1];
      var count_start = 0;
      var aux_count_nodes;
      var start_node;
      var duration_node;

      for(i = 0; i < res.data.length; i++){
        if(res.data[i].data_type == "change_status"){
          for(var k = 0; k < object_node.length; k++){
            if (res.data[i].status == object_node[k].group && res.data[i].when == object_node[k].when && object_node[k].fill == "white"){
              start_node = object_node[k-1].start;
              duration_node = object_node[k-1].duration;
            }
          }
          while ( j < res.data.length && res.data[i].when >= res.data[j].when ){
            if(res.data[j].data_type == "topic_modify"){
              change_stroke = color_green;
              aux_count_nodes = calculate_duration_node(res, duration_node,aux_count_nodes);
              object_node.push({ "group": res.data[i].old_status, "start": start_node + count_nodes + aux_count_nodes, "duration": 0, "key": -(j+i+res.data.length), "text": "", "fill": getLuxColor(change_stroke,0.3), "stroke": change_stroke, "data_username": res.data[j].username, "data_when": res.data[j].when, "data_type": res.data[j].data_type, "data_text": res.data[j].text, "data_field": res.data[j].field, "data_old_value":res.data[j].old_value, "data_new_value":res.data[j].new_value});
              count_nodes = count_nodes + aux_count_nodes + 0.3;
            }else if(res.data[j].data_type == "event_post"){
                change_stroke = color_red;
                aux_count_nodes = calculate_duration_node(res, duration_node,aux_count_nodes);
                object_node.push({ "group": res.data[i].old_status, "start": start_node + count_nodes + aux_count_nodes, "duration": 0, "key": -(j+i+res.data.length), "text": "", "fill": getLuxColor(change_stroke,0.3), "stroke": change_stroke, "data_username": res.data[j].username, "data_when": res.data[j].when, "data_type": res.data[j].data_type, "data_post": res.data[j].post, "data_text": res.data[j].text});
                count_nodes = count_nodes + aux_count_nodes + 0.3;
            }else if(res.data[j].data_type == "event_file"){
                change_stroke = color_blue;
                aux_count_nodes = calculate_duration_node(res, duration_node,aux_count_nodes);
                object_node.push({ "group": res.data[i].old_status, "start": start_node + count_nodes + aux_count_nodes, "duration": 0, "key": -(j+i+res.data.length), "text": "", "fill": getLuxColor(change_stroke,0.3), "stroke": change_stroke, "data_username": res.data[j].username, "data_when": res.data[j].when, "data_type": res.data[j].data_type, "data_filename": res.data[j].filename, "data_text": res.data[j].text});
                count_nodes = count_nodes + aux_count_nodes + 0.3;
            }else{
                change_stroke = "black";
            }
            j++;
          }
          for(var z = 0; z < object_node.length; z++){
            if (res.data[i].status == object_node[z].group && res.data[i].when == object_node[z].when && object_node[z].fill == "white"){
              if(count_nodes > object_node[z].duration){
                object_node[z-1].duration = count_nodes;
                object_node[z].start = object_node[z-1].start+object_node[z-1].duration;
                object_node[z-1].text = "";
                sum_duration = sum_duration + count_nodes;
                //timer_nodes[count_start] = object_node[z-1].when;
                start[count_start] = object_node[z-1].start;
                count_start++;
              }else{
                object_node[z].start = object_node[z-1].start+object_node[z-1].duration;
                object_node[z-1].text = "";
                sum_duration = sum_duration + count_nodes;
                //timer_nodes[count_start] = object_node[z-1].when;
                start[count_start] = object_node[z-1].start;
                count_start++;
              }
            }
          }
          count_nodes = 0;
        }else if (res.data[i].status === "" && res.data[i].old_status === ""){
          if(res.data[i].data_type == "topic_modify"){
                change_stroke = color_green;
                object_node.push({ "group" : last_node.group, "start":last_node.start+count_nodes_2, "duration":0, "key": -(i+i+res.data.length), "text": "", "fill": getLuxColor(change_stroke,0.3), "stroke": change_stroke, "data_username": res.data[i].username, "data_when": res.data[i].when, "data_type": res.data[i].data_type, "data_text": res.data[i].text, "data_field": res.data[i].field, "data_old_value":res.data[i].old_value, "data_new_value":res.data[i].new_value});
              }else if(res.data[i].data_type == "event_post"){
                  change_stroke = color_red;
                  object_node.push({ "group" : last_node.group, "start":last_node.start+count_nodes_2, "duration":0, "key": -(i+i+res.data.length), "text": "", "fill": getLuxColor(change_stroke,0.3), "stroke": change_stroke, "data_username": res.data[i].username, "data_when": res.data[i].when, "data_type": res.data[i].data_type, "data_post": res.data[i].post, "data_text": res.data[i].text});
              }else if(res.data[i].data_type == "event_file"){
                  change_stroke = color_blue;
                  object_node.push({ "group" : last_node.group, "start":last_node.start+count_nodes_2, "duration":0, "key": -(i+i+res.data.length), "text": "", "fill": getLuxColor(change_stroke,0.3), "stroke": change_stroke, "data_username": res.data[i].username, "data_when": res.data[i].when, "data_type": res.data[i].data_type, "data_filename": res.data[i].filename, "data_text": res.data[i].text});
              }else{
                  change_stroke = "black";
              }
          count_nodes_2++;
        }
      }
      //this part modify the duration of the last principal node.
      for(var r = object_node.length-1; r >= 0; r--){
        if (object_node[r].key == last_node.key){
            object_node[r].duration = count_nodes_2;
            sum_duration = sum_duration + count_nodes_2;
            start[start.length-1] = object_node[r].start;
        }
      }
      // duration
      for(var w = 0; w < object_node.length; w++){
        if(object_node[w].duration=="change"){
          object_node[w].duration = sum_duration;
        }
      }
      return sum_duration;
    }


    var container = new Ext.Panel({
        width: 800,
        height: 600,
        layout: 'absolute',
        items:[pn_diagram,pn_overview]
    }
    );
    return container;
});
