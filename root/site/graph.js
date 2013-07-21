Baseliner.JitTree = function(c){
    var self = this;
    Baseliner.JitTree.superclass.constructor.call( this, Ext.apply( {
        layout: 'fit' ,
        bodyCfg: { style:{ 'background-color':'#111' } }
    }, c ) );

    self.on( 'afterrender', function(cont){
        setTimeout( function(){
            do_tree( self.body );
        }, 500);
    });
    
    var do_tree = function( el ) {
        var json = {id:"node02", name:"0.2", data:{},
                children:[{id:"node13", name:"1.3", data:{},
                children:[{id:"node24", name:"2.4", data:{}, children:[]}]}]};
        json = [
            { "id": "1", "name": "1", "adjacencies": [
                    { "nodeTo": "2", "data": { "$direction": ["1", "2"] } },
                    { "nodeTo": "3", "data": { "$direction": ["1", "3"] } }
                ]
            },
            { "id": "2", "name": "2", "adjacencies": [
                    { "nodeTo": "4", "data": { "$direction": ["2", "4"] } }
                ]
            },
            { "id": "3", "name": "3", "adjacencies": [
                    { "nodeTo": "4", "data": { "$direction": ["3", "4"] } }
                ]
            },
            { "id": "4", "name": "4", "adjacencies": [
                    { "nodeTo": "2", "data": { "$direction": ["2", "4"] } },
                    { "nodeTo": "3", "data": { "$direction": ["3", "4"] } }
                ]
            }
        ];
        //A client-side tree generator
        var getTree = (function() {
            var i = 0;
            return function(nodeId, level) {
                var json_str = Ext.util.JSON.encode( json );
                var subtree = eval('(' + json_str.replace(/id:\"([a-zA-Z0-9]+)\"/g, 
                            function(all, match) {
                                return "id:\"" + match + "_" + i + "\""  
                            }) + ')');
                $jit.json.prune(subtree, level); i++;
                return {
                    'id': nodeId,
                    'children': subtree.children
                };
            };
        })();
    

        //Implement a node rendering function called 'nodeline' that plots a straight line
        //when contracting or expanding a subtree.
        $jit.ST.Plot.NodeTypes.implement({
            'nodeline': {
              'render': function(node, canvas, animating) {
                    if(animating === 'expand' || animating === 'contract') {
                      var pos = node.pos.getc(true), nconfig = this.node, data = node.data;
                      var width  = nconfig.width, height = nconfig.height;
                      var algnPos = this.getAlignedPos(pos, width, height);
                      var ctx = canvas.getCtx();
                      var ort = 'top';
                      ctx.beginPath();
                      if(ort == 'left' || ort == 'right') {
                          ctx.moveTo(algnPos.x, algnPos.y + height / 2);
                          ctx.lineTo(algnPos.x + width, algnPos.y + height / 2);
                      } else {
                          ctx.moveTo(algnPos.x + width / 2, algnPos.y);
                          ctx.lineTo(algnPos.x + width / 2, algnPos.y + height);
                      }
                      ctx.stroke();
                  } 
              }
            }
              
        });

        //init Spacetree
        //Create a new ST instance
        //alert( self.body.getHeight() );
        //console.log( self.body );

        var st = new $jit.ST({
            'injectInto': el.id,
            height: el.getHeight(),
            //set duration for the animation
            duration: 500,
            //set animation transition type
            transition: $jit.Trans.Quart.easeInOut,
            //set distance between node and its children
            levelDistance: 50,
            //set max levels to show. Useful when used with
            //the request method for requesting trees of specific depth
            levelsToShow: 2,
            //set node and edge styles
            //set overridable=true for styling individual
            //nodes or edges
            Node: {
                height: 20,
                width: 40,
                //use a custom
                //node rendering function
                type: 'nodeline',
                color:'#23A4FF',
                lineWidth: 2,
                align:"center",
                overridable: true
            },
            
            Edge: {
                type: 'bezier',
                lineWidth: 2,
                color:'#23A4FF',
                overridable: true
            },
            
            //Add a request method for requesting on-demand json trees. 
            //This method gets called when a node
            //is clicked and its subtree has a smaller depth
            //than the one specified by the levelsToShow parameter.
            //In that case a subtree is requested and is added to the dataset.
            //This method is asynchronous, so you can make an Ajax request for that
            //subtree and then handle it to the onComplete callback.
            //Here we just use a client-side tree generator (the getTree function).
            request: function(nodeId, level, onComplete) {
              var ans = getTree(nodeId, level);
              onComplete.onComplete(nodeId, ans);  
            },
            
            onBeforeCompute: function(node){
               // Log.write("loading " + node.name);
            },
            
            onAfterCompute: function(){
                //Log.write("done");
            },
            
            //This method is called on DOM label creation.
            //Use this method to add event handlers and styles to
            //your node.
            onCreateLabel: function(label, node){
                label.id = node.id;            
                label.innerHTML = node.name;
                label.onclick = function(){
                    st.onClick(node.id);
                };
                //set label styles
                var style = label.style;
                style.width = 40 + 'px';
                style.height = 17 + 'px';            
                style.cursor = 'pointer';
                style.color = '#fff';
                //style.backgroundColor = '#1a1a1a';
                style.fontSize = '0.8em';
                style.textAlign= 'center';
                style.textDecoration = 'underline';
                style.paddingTop = '3px';
            },
            
            //This method is called right before plotting
            //a node. It's useful for changing an individual node
            //style properties before plotting it.
            //The data properties prefixed with a dollar
            //sign will override the global node style properties.
            onBeforePlotNode: function(node){
                //add some color to the nodes in the path between the
                //root node and the selected node.
                if (node.selected) {
                    node.data.$color = "#ff7";
                }
                else {
                    delete node.data.$color;
                }
            },
            
            //This method is called right before plotting
            //an edge. It's useful for changing an individual edge
            //style properties before plotting it.
            //Edge data proprties prefixed with a dollar sign will
            //override the Edge global style properties.
            onBeforePlotLine: function(adj){
                if (adj.nodeFrom.selected && adj.nodeTo.selected) {
                    adj.data.$color = "#eed";
                    adj.data.$lineWidth = 3;
                }
                else {
                    delete adj.data.$color;
                    delete adj.data.$lineWidth;
                }
            }
        });
        //load json data
        st.loadJSON( json );
        //compute node positions and layout
        st.compute();
        //emulate a click on the root node.
        st.onClick(st.root);
        //st.switchPosition('top', "animate", { });
    };
};
Ext.extend( Baseliner.JitTree, Ext.Panel ); 


Baseliner.JitRGraph = Ext.extend( Ext.Panel, {
    layout:'fit',
    initComponent : function(){
        var self = this;
        self.data = self.data || self.json || {};
        self.bodyCfg = Ext.apply( { style:{ 'background-color':'#fff' } }, self.bodyCfg );

        Baseliner.JitRGraph.superclass.initComponent.call( this );
        
        self.on( 'resize', function(panel,w,h,rw,rh){
            //if( self._resize ) self._resize( args ); 
            self.redraw();
        });

        self.images = {}; // indexed by mid

        $jit.RGraph.Plot.NodeTypes.implement({
           'icon': {
               'render': function(node, canvas) { 
                   var ctx = canvas.getCtx(); 
                   var pos = node.getPos().getc(); 
                   var img = self.images[ node.id ];
                   if( !img ) { 
                       img = new Image(); 
                       img.src = node.data.icon;
                       self.images[ node.id ] = img;
                   }
                   //img.onload = function(){ 
                   ctx.drawImage(img, pos.x-8, pos.y-8 );
                   //} 
               },
               'contains': function(node, pos) { 
                    var npos = node.pos.getc(true), 
                        dim = node.getData('dim'); 
                        return this.nodeHelper.square.contains(npos, pos, dim); 
               } 
           } 
        });
        
    },
    redraw : function(){
        var self = this;
        self.body.update('');
        self.do_tree( self.body ); 
    },
    do_tree : function( el ) {
        var self = this;
        var rgraph = new $jit.RGraph({
            //Where to append the visualization
            injectInto: el.id,
            //Optional: create a background canvas that plots
            //concentric circles.
            background: {
              CanvasStyles: {
                strokeStyle: '#bbb'
              }
            },
            //Add navigation capabilities:
            //zooming by scrolling and panning.
            Navigation: {
              enable: true,
              panning: true,
              zooming: 20
            },
            //Set Node and Edge styles.
            Node: {
                type: 'icon',
                color: '#ddeeff'
            },
            
            Edge: {
              color: '#C17878',
              lineWidth:1.5
            },

            onBeforeCompute: function(node){
                //Log.write("centering " + node.name + "...");
                //Add the relation list in the right column.
                //This list is taken from the data property of each JSON node.
                //$jit.id('inner-details').innerHTML = node.data.relation;
            },
            
            //Add the name of the node in the correponding label
            //and a click handler to move the graph.
            //This method is called once, on label creation.
            onCreateLabel: function(domElement, node){
                domElement.innerHTML = node.name;
                domElement.onclick = function(){
                    rgraph.onClick(node.id, {
                        onComplete: function() {
                            //Log.write("done");
                        }
                    });
                };
            },
            //Change some label dom properties.
            //This method is called each time a label is plotted.
            onPlaceLabel: function(domElement, node){
                var style = domElement.style;
                style.display = '';
                style.cursor = 'pointer';
                var d = node.data;
                var icon = d.icon;

                if (node._depth <= 1) {
                    style.fontSize = "0.8em";
                    style.color = "#111";
                
                } else {
                    style.fontSize = "0.7em";
                    style.color = "#333";
                    //style['margin-top'] = '20px'; 
                } 
                //else {
                   // style.display = 'none';
                //}

                //console.log( node );
                //style.background = String.format("#fff url('{0}') no-repeat", icon );

                var left = parseInt(style.left);
                var w = domElement.offsetWidth;
                style.left = (left - w / 2) + 'px';

                var top = parseInt(style.top);
                var h = domElement.offsetHeight;
                style.top = (top - h / 2 + 15)  + 'px';
            }
        });
        //load JSON data
        rgraph.loadJSON(self.data);
        //trigger small animation
        /* rgraph.graph.eachNode(function(n) {
          var pos = n.getPos();
          pos.setc(-200, -200);
        }); */
        rgraph.compute('end');
        rgraph.fx.animate({
          modes:['polar'],
          duration: 500
        });
    }
});

Baseliner.ST = Ext.extend( Ext.Panel, {
    layout: 'fit',
    initComponent: function(){
        var self = this;
        self.bodyCfg = Ext.apply({ style:{ 'background-color':'#111' } }, self.bodyCfg );

        Baseliner.ST.superclass.initComponent.call( this );
        
        self.on( 'resize', function(panel,w,h,rw,rh){
            //if( self._resize ) self._resize( args ); 
            self.redraw();
        });

        self.images = {}; // indexed by mid

        $jit.ST.Plot.NodeTypes.implement({
            'nodeline': {
              'render': function(node, canvas, animating) {
                    if(animating === 'expand' || animating === 'contract') {
                      var pos = node.pos.getc(true), nconfig = this.node, data = node.data;
                      var width  = nconfig.width, height = nconfig.height;
                      var algnPos = this.getAlignedPos(pos, width, height);
                      var ctx = canvas.getCtx(), ort = this.config.orientation;
                      ctx.beginPath();
                      if(ort == 'left' || ort == 'right') {
                          ctx.moveTo(algnPos.x, algnPos.y + height / 2);
                          ctx.lineTo(algnPos.x + width, algnPos.y + height / 2);
                      } else {
                          ctx.moveTo(algnPos.x + width / 2, algnPos.y);
                          ctx.lineTo(algnPos.x + width / 2, algnPos.y + height);
                      }
                      ctx.stroke();
                  } 
              }
            }
        });
    },
    redraw : function(){
        var self = this;
        self.body.update('');
        self.gen_tree( self.body ); 
        self.request(null, null, { onComplete:function(id, data){
            self.load_data( data );
        }});
    },
    request : function( id, lev, onComplete) {
        if( this.data ) 
            onComplete.onComplete( id, this.data );
    },
    load_data : function(data){
        var self = this;
        //load JSON data
        self.jit.loadJSON(data);
        //trigger small animation
        /* rgraph.graph.eachNode(function(n) {
          var pos = n.getPos();
          pos.setc(-200, -200);
        }); */
        self.jit.compute('end');
        self.jit.onClick(self.jit.root);
        /*
        rgraph.fx.animate({
          modes:['polar'],
          duration: 500
        });
        */
    },
    gen_tree : function( el ) {
        var self = this;
        var w = el.getWidth();
        var h = el.getHeight();
        self.jit = new $jit.ST({
            //Where to append the visualization
            injectInto: el.id,
            width: w,
            height: h,
            //set duration for the animation
            duration: 200,
            //set animation transition type
            transition: $jit.Trans.Quart.easeInOut,
            //set distance between node and its children
            levelDistance: 150,
            //set max levels to show. Useful when used with
            //the request method for requesting trees of specific depth
            levelsToShow: 2,
            //set node and edge styles
            //set overridable=true for styling individual
            //nodes or edges
            //
            Node: {
                height: 20,
                width: 120,
                //use a custom
                //node rendering function
                type: 'nodeline',
                color:'#23A4FF',
                lineWidth: 2,
                align:"center",
                overridable: true
            },
            
            Edge: {
                type: 'bezier',
                lineWidth: 2,
                color:'#23A4FF',
                overridable: true
            },
            //This method is called on DOM label creation.
            //Use this method to add event handlers and styles to
            //your node.
            onCreateLabel: function(label, node){
                label.id = node.id;            
                label.innerHTML = String.format('<table><tr><td style="align:top"><img src="{1}"></td><td>{0}</td></tr></table>', node.name, node.data.icon );
                label.onclick = function(){
                    self.jit.onClick(node.id);
                };
                //set label styles
                var style = label.style;
                style.width = 120 + 'px';
                style.height = 17 + 'px';            
                style.cursor = 'pointer';
                style.color = '#fff';
                //style.backgroundColor = '#1a1a1a';
                style.fontSize = '0.8em';
                style.textAlign= 'left';
                style.textWrap = 'none';
                //style.textDecoration = 'underline';
                style.paddingTop = '3px';
            },
            
            //This method is called right before plotting
            //a node. It's useful for changing an individual node
            //style properties before plotting it.
            //The data properties prefixed with a dollar
            //sign will override the global node style properties.
            onBeforePlotNode: function(node){
                //add some color to the nodes in the path between the
                //root node and the selected node.
                if (node.selected) {
                    node.data.$color = "#ff7";
                }
                else {
                    delete node.data.$color;
                }
            },
            
            //This method is called right before plotting
            //an edge. It's useful for changing an individual edge
            //style properties before plotting it.
            //Edge data proprties prefixed with a dollar sign will
            //override the Edge global style properties.
            onBeforePlotLine: function(adj){
                if (adj.nodeFrom.selected && adj.nodeTo.selected) {
                    adj.data.$color = "#eed";
                    adj.data.$lineWidth = 3;
                }
                else {
                    delete adj.data.$color;
                    delete adj.data.$lineWidth;
                }
            },
           
            //Add navigation capabilities:
            //zooming by scrolling and panning.
            Navigation: {
              enable: true,
              panning: true,
              zooming: 20
            },
            
            request: function(nodeId, level, onComplete) {  
                self.request( nodeId, level, onComplete );
            }  
        });
    }
});

Baseliner.CIGraph = Ext.extend( Ext.Panel, {
    layout: 'card',
    activeItem : 0,
    mid: 124,
    depth: 1,
    limit: 50,
    constructor : function(c){
        var self = this;
        var ii = Ext.id();
        var btn_redraw = new Ext.Button({
            icon:'/static/images/icons/redraw.png', handler: function(){ self.redraw() } 
        });
        var btn_st = new Ext.Button({
            allowDepress: false, enableToggle: true, toggleGroup:'cigraph_btns' + ii,
            text: _('SpaceTree'), pressed: true, handler: function(){ self.load_st() }
        });
        var btn_rg = new Ext.Button({
            allowDepress: false, enableToggle: true, toggleGroup:'cigraph_btns' + ii,
            text: _('RGraph'), handler: function(){ self.load_rg() }
        });
        // depth
        var field_depth = new Ext.ux.form.SpinnerField({ fieldLabel:'dth',value: self.depth, width: 60 });
        field_depth.on('spin', function(){
            self.remove( self.getLayout().activeItem );
            self.depth = field_depth.getValue();
            self.rg = null;
            self.load_rg();
        });
        // limit
        var field_limit = new Ext.ux.form.SpinnerField({ fieldLabel:'lim',value: self.limit, width: 60 });
        field_limit.on('spin', function(){
            self.remove( self.getLayout().activeItem );
            self.limit = field_limit.getValue();
            self.rg = null;
            self.load_rg();
        });
        var tbar = [
            btn_redraw, '-', btn_st, btn_rg, '-',
            field_depth, field_limit
        ];
        Baseliner.CIGraph.superclass.constructor.call(this, Ext.apply({
            tbar : tbar,
            items: []
        },c));
        
        self.load_st();
    },
    redraw : function(){
        var ai = this.getLayout().activeItem;
        if( ai ) ai.redraw();
    },
    show : function() {
        var graph_win = new Baseliner.Window({ layout:'fit', width: 800, height: 600, items: this });
        graph_win.show();
        this.doLayout();
    },
    load_st : function(){
       var self = this; 
       if( self.st ) {
           self.getLayout().setActiveItem( self.st );
           return;
       }
       self.st = new Baseliner.ST({ request: function(id,lev,onComplete){
            var mid = id || self.mid;
            Baseliner.ajaxEval( '/ci/json_tree', { mid: mid, node_data:'{ "$type":"nodeline" }',
                         direction:'related', depth: self.depth, limit: self.limit }, function(res){
                if( ! res.success ) { Baseliner.message( 'Error', res.msg ); return }
                //console.log( res.data );        
                onComplete.onComplete(id, res.data);    
            });
       }});
       self.add( self.st );
    },
    load_rg : function(){
       var self = this; 
       console.log( self.rg );
       if( self.rg ) {
           self.getLayout().setActiveItem( self.rg );
           return;
       }
       Baseliner.ajaxEval( '/ci/json_tree', { mid: self.mid, direction:'related', depth: self.depth, limit: self.limit }, function(res){
           if( ! res.success ) { Baseliner.message( 'Error', res.msg ); return }
           self.rg = new Baseliner.JitRGraph({ json: res.data });
           self.add( self.rg );
           self.getLayout().setActiveItem( self.rg );
       });
    }
});
