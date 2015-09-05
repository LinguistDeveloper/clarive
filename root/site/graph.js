Baseliner.D3Graph = Ext.extend( Ext.Panel, {
    mid: -1,
    mode: 'tree', 
    depth: 3, 
    unique: true,
    direction: 'related',
    linkDistance: 190,
    charge: -500,
    initComponent : function(){
        var self = this;
        Baseliner.D3Graph.superclass.initComponent.call(this);
         
        self.on('resize', function(p,w,h){
            if( this.svg ) {
                //this.svg.trigger('resizeEnd');
                //this.svg.attr('width', w).attr('height', h);
                //self.redraw();
            }
        });
        self.on('afterrender', function(){
            self.redraw();
        });
    },
    redraw: function(){
        var self = this;
        Baseliner.ajaxEval('/ci/json_tree', { mid:self.mid, direction: self.direction, depth:self.depth, mode:self.mode, unique:self.unique }, function(res){
            self.links = [];
            
            var link = function(source){
                Ext.each( source.children, function(chi){
                    self.links.push({ source: source.name, target: chi.name, type:"child" });
                    link( chi );
                });
            }
            link( res.data );

            self.nodes = {};

            // Compute the distinct nodes from the links.
            self.links.forEach(function(link) {
              link.source = self.nodes[link.source] || (self.nodes[link.source] = {name: link.source});
              link.target = self.nodes[link.target] || (self.nodes[link.target] = {name: link.target});
            });
            
            self.draw();

        });
    },
    draw: function(){
        var self = this;
        self.body.update('');

        var id = self.body.id; 
        var height = self.body.getHeight();
        var width = self.body.getWidth();
        
        self.force = d3.layout.force()
            .nodes(d3.values(self.nodes))
            .links(self.links)
            .size([width, height])
            .linkDistance( self.linkDistance )
            .charge( self.charge )
            .gravity( 0.05 )
            .on("tick", function() { self.tick() })
            .start();

        self.svg = d3.select("#"+ id ).append("svg:svg").attr("width", '100%').attr("height", '100%')
            //.attr("viewBox", "0 0 "+height+" "+width )
            .attr("preserveAspectRatio", "xMinYMin meet");

        // Per-type markers, as they don't inherit styles.
        self.svg.append("svg:defs").selectAll("marker")
            .data(["suit", "child", "parent"])
            .enter().append("svg:marker")
            .attr("id", String)
            .attr("viewBox", "0 -5 10 10")
            .attr("refX", 15)
            .attr("refY", -1.5)
            .attr("markerWidth", 6)
            .attr("markerHeight", 6)
            .attr("orient", "auto")
            .append("svg:path")
            .attr("d", "M0,-5L10,0L0,5");

        self.path = self.svg.append("svg:g").selectAll("path")
            .data(self.force.links())
            .enter().append("svg:path")
            .attr("class", function(d) { return "link " + d.type; })
            .attr("marker-end", function(d) { return "url(#" + d.type + ")"; });

        self.circle = self.svg.append("svg:g").selectAll("circle")
            .data(self.force.nodes())
            .enter().append("svg:circle")
            .attr("r", 6)
            .call(self.force.drag);

        self.text = self.svg.append("svg:g").selectAll("g")
            .data(self.force.nodes())
          .enter().append("svg:g");

        // A copy of the text with a thick white stroke for legibility.
        self.text.append("svg:text")
            .attr("x", 8)
            .attr("y", ".31em")
            .attr("class", "shadow")
            .text(function(d) { return d.name; });

        self.text.append("svg:text")
            .attr("x", 8)
            .attr("y", ".31em")
            .text(function(d) { return d.name; });

    },
    tick : function(){
        var self = this;
        // Use elliptical arc path segments to doubly-encode directionality.
        self.path.attr("d", function(d) {
            var dx = d.target.x - d.source.x,
                dy = d.target.y - d.source.y,
                dr = Math.sqrt(dx * dx + dy * dy);
            return "M" + d.source.x + "," + d.source.y + "A" + dr + "," + dr + " 0 0,1 " + d.target.x + "," + d.target.y;
        });

        self.circle.attr("transform", function(d) {
            return "translate(" + d.x + "," + d.y + ")";
        });

        self.text.attr("transform", function(d) {
            return "translate(" + d.x + "," + d.y + ")";
        });
    }
});


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
        self.request(null, null, { onComplete:function(id, data){
            self.data = data;
            self.do_tree( self.body ); 
        }});
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
              lineWidth: 1.5
            },

            onBeforeCompute: function(node){
                self.request( node.id, null, { onComplete:function(id, data){
                    rgraph.op.sum( data, {  
                        type: 'replot', //'replot', // fade:seq
                        fps: 30,
                        duration: 200,
                        hideLabels: true,
                        onComplete: function(){  
                            //rgraph.refresh();
                            rgraph.compute('end');
                        }  
                    });
                }});
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
    },
    request : function( id, lev, onComplete) {
        if( this.data ) 
            onComplete.onComplete( id, this.data );
    }
});

Baseliner.ST = Ext.extend( Ext.Panel, {
    layout: 'fit',
    initComponent: function(){
        var self = this;
        self.bodyCfg = Ext.apply({ style:{ 'background-color':'#fff' } }, self.bodyCfg );

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
        self.jit.loadJSON(data);
        //trigger small animation (arrival of first node from off)
        self.jit.graph.eachNode(function(n) {
          var pos = n.getPos();
          pos.setc(-200, -200);
        });
        self.jit.compute('end');
        self.jit.onClick(self.jit.root);
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
            levelDistance: 100,
            //set max levels to show. Useful when used with
            //the request method for requesting trees of specific depth
            levelsToShow: 2,
            //set node and edge styles
            //set overridable=true for styling individual
            //nodes or edges
            //
            Node: {
                height: 20,
                width: 140,
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
                label.innerHTML = String.format('<table><tr><td style="vertical-align: top"><img src="{1}"></td><td style="vertical-align: top">{0}</td></tr></table>', node.name, node.data.icon );
                label.onclick = function(){
                    self.jit.onClick(node.id);
                };
                //set label styles
                var style = label.style;
                style.width = 140 + 'px';
                style.height = 21 + 'px';            
                style.cursor = 'pointer';
                style.color = '#000';
                //style.backgroundColor = '#1a1a1a';
                style.fontFamily = 'Tahoma, Consolas, Courier New, Arial, monotype';
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
                    node.data.$color = "#000";
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
    mid: -1,
    direction: 'related', 
    depth: 1,
    title: _('CI Graph'),
    header: false,
    limit: 50,
    which: 'st',
    constructor : function(c){
        var self = this;
        Baseliner.CIGraph.superclass.constructor.call(this, Ext.apply({
            items: []
        },c));
        
    },
    initComponent : function(){
        var self = this;
        var ii = Ext.id();
        var btn_redraw = new Ext.Button({
            tooltip: _('Redraw'),
            icon:'/static/images/icons/redraw.png', handler: function(){ self.redraw() } 
        });
        self.btn_to_img = new Ext.Button({
            tooltip: _('Generate Image'),
            icon:'/static/images/icons/printer.png', hidden: Ext.isIE9m, handler: function(){ self.to_img() } 
        });
        self.btn_st = new Ext.Button({
            allowDepress: false, enableToggle: true, toggleGroup:'cigraph_btns' + ii,
            icon: '/static/images/icons/spacetree.png',
            text: _('SpaceTree'), handler: function(){ self.load_st() }
        });
        self.btn_rg = new Ext.Button({
            allowDepress: false, enableToggle: true, toggleGroup:'cigraph_btns' + ii,
            icon: '/static/images/icons/rgraph.png',
            text: _('RGraph'), handler: function(){ self.load_rg() }
        });
        self.btn_d3g = new Ext.Button({
            allowDepress: false, enableToggle: true, toggleGroup:'cigraph_btns' + ii,
            icon: '/static/images/icons/d3graph.png', hidden: Ext.isIE9m, 
            text: _('d3G'), handler: function(){ self.load_d3g() }
        });
        // depth
        self.field_depth = new Ext.ux.form.SpinnerField({ hidden: true, value: self.depth, width: 60 });
        self.field_depth.on('spin', function(){
            self.depth = self.field_depth.getValue();
            self.reload_current();
        });
        // limit
        var field_limit = new Ext.ux.form.SpinnerField({ value: self.limit, width: 60 });
        field_limit.on('spin', function(){
            self.limit = field_limit.getValue();
            self.reload_current();
        });
        // direction
        self.field_direction = new Baseliner.ComboSingle({ data:['parents','children','related'], value: self.direction });
        self.field_direction.on('select', function(){
            self.direction = self.field_direction.getValue();
            self.reload_current();
        });
        // recenter on last mid
        self.btn_recenter = new Ext.Button({
            icon: '/static/images/icons/startlast.png',
            tooltip: _('Start on Last'), handler: function(){ self.mid = self.last_mid; self.reload_current(); }, hidden: true
        });
        self.lab_depth = new Ext.Container({ hidden: true, html:_('dph')+':' });
        self.tbar = [
            self.btn_st, self.btn_rg, self.btn_d3g,
            '-',
            btn_redraw, self.btn_recenter, 
            '-', 
            //{ xtype:'container', labelWidth: 20, layout:'form', items:[self.field_depth, field_limit] },
            self.lab_depth, self.field_depth, 
            _('lim')+':', field_limit,
            _('dir')+':', self.field_direction, '-',
            '->', 
            self.btn_to_img
        ];
        self.title = _('%1: %2', self.title, self.mid );
        Baseliner.CIGraph.superclass.initComponent.call(this);
        var first = true ;
        self.on( 'resize', function(){
            if( first ) {
                eval("self.load_"+self.which+"();");
                first = false;
            }
        });
    },
    reload_current : function(){
        var self = this;
        var ai = this.getLayout().activeItem;
        if( !ai ) return;
        var which = ai.which;
        self.remove( ai );
        if( which != undefined ) {
            self[ which ] = null; 
            eval("self.load_" + which + "();");
        }
    },
    redraw : function(){
        var ai = this.getLayout().activeItem;
        if( ai ) ai.redraw();
    },
    window_show : function() {
        var graph_win = new Baseliner.Window({ title: this.title, layout:'fit', width: 1000, height: 600, items: this });
        graph_win.show();
        return graph_win; 
    },
    load_st : function(){
        var self = this; 
        self.btn_st.toggle(true);
        self.field_depth.hide(); self.lab_depth.hide();
        self.btn_recenter.show();
        if( self.st ) {
            self.getLayout().setActiveItem( self.st );
            return;
        }
        self.st = new Baseliner.ST({ request: function(id,lev,onComplete){
            var mid = id || self.mid;
            self.last_mid = mid;
            Baseliner.ajaxEval( '/ci/json_tree', { mid: mid, node_data:'{ "$type":"nodeline" }', 
                direction: self.direction, 
                depth: 1, limit: self.limit }, function(res){
                    if( ! res.success ) { Baseliner.message( 'Error', res.msg ); return }
                    if( res.count < 1 ) { Baseliner.warning( _('No nodes available') ); onComplete.onComplete(id, {}); return }
                    onComplete.onComplete(id, res.data);    
                });
        }});
        self.st.which = 'st';
        self.add( self.st );
        self.getLayout().setActiveItem( self.st );
    },
    load_rg : function(){
        var self = this; 
        self.btn_rg.toggle(true);
        self.field_depth.show(); self.lab_depth.show();
        self.btn_recenter.hide();
        if( self.rg ) {
            self.getLayout().setActiveItem( self.rg );
            return;
        }
        self.rg = new Baseliner.JitRGraph({ request: function(id,lev,onComplete){
            var mid = id || self.mid;
            Baseliner.ajaxEval( '/ci/json_tree', { mid: mid, 
                add_prefix: 0,
                direction: self.direction,
                depth: self.depth, limit: self.limit }, function(res){
                    if( ! res.success ) { Baseliner.message( 'Error', res.msg ); return }
                    if( res.count > self.limit ) {
                        Baseliner.confirm( _('graph_high_load %1', res.count ), function(){
                            onComplete.onComplete(id, res.data);    
                        });
                    } else {
                        onComplete.onComplete(id, res.data);    
                    }
                });
        }});
        self.rg.which = 'rg';
        self.add( self.rg );
        self.getLayout().setActiveItem( self.rg );
    },
    load_d3g : function(){
        var self = this;
        self.btn_d3g.toggle(true);
        self.field_depth.show(); self.lab_depth.show();
        self.btn_recenter.hide();
        if( self.d3g ) {
            self.getLayout().setActiveItem( self.d3g );
            return;
        }
        var w = 960, h = 500;
        Baseliner.loadFile('/static/d3/d3.css', 'css' );
        self.d3g = new Baseliner.D3Graph({ mid: self.mid, depth: self.depth, direction: self.direction });
        self.add( self.d3g );
        self.d3g.which = 'd3g';
        self.getLayout().setActiveItem( self.d3g );
    },
    to_img : function(){
        var self = this;
        Cla.use('/static/html2canvas/html2canvas.js', function(){
            html2canvas(self.getLayout().activeItem.el.dom, {
              onrendered: function(canvas) {
                  var ww = window.open('about:blank', '_blank'); //, 'resizable=yes, scrollbars=yes' );
                  var dw = ww.document;
                  canvas.style['backgroundColor'] = '#000';
                  var image = dw.createElement('image');
                  image.src = canvas.toDataURL("image/png");
                  dw.body.appendChild( image );
              }
            });
        });
        // jquery version doesn't work: not everything is in the canvas, or d3 has no canvas apparently
        // $(self.getLayout().activeItem.el.dom).find('canvas').each(function(){ var canvas = this;
    } 
});
