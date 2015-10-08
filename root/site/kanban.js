/*

  Kanban Panel 

  There are 3 usage modes:

  topic mids list:
      new Baseliner.Kanban({ topics: [ 1,2,3 ] }).fullscreen();


  topic store:
      new Baseliner.Kanban({ store: store }).fullscreen();

  topic store provided, but filtered:
      new Baseliner.Kanban({ store: store, topics: [ 1,2,3 ] }).fullscreen();

*/

Baseliner.Kanban = Ext.extend( Ext.ux.Portal, {
    //margins:'5 5 5 0',
    height: 400, 
    width: 800,
    is_fullscreen : false,
    is_tab : false,
    // background: "#555 url('/static/images/bg/cork.jpg')",
    background: "#535051",
    title: _('Kanban'),
    header: false,
    constructor : function(c) {
        Baseliner.Kanban.superclass.constructor.call(this, Ext.apply({
            mids: [],
            layoutCfg: {
                renderHidden: true
            }
        },c));
    },
    initComponent : function(){
        var self = this;
        self.addEvents( 'tab' );
        self.statuses_hash = {};
        self.column_by_status = {};
        self.status_btn = new Ext.Button({ text:_('Statuses'), menu:[] });
        self.tab_btn = new Ext.Button({ 
            icon:'/static/images/icons/tab.png', iconCls:'x-btn-icon',
            handler: function(){
                if( self.is_tab ) 
                    self.fullscreen();
                else 
                    self.goto_tab();
            }
        });
        self.btn_save = new Ext.Button({ 
            text:_('Save Layout'), icon:IC('save'), tooltip:_('Save Current Layout'), hidden: self.topic_mid==undefined, 
            handler: function(){
                self.save_statuses();
            }
        });
        self.bodyCfg = { 
            style: {
             'background': self.background,
             'background-repeat': 'repeat'
            }
        };
        self.tbar = [ 
            '<img src="/static/images/icons/kanban.png" />',
            'KANBAN',
            '-',
            { icon:'/static/images/icons/refresh.png',tooltip: _('Refresh Node'), iconCls:'x-btn-icon', handler: function(){ self.refresh() } },
            self.status_btn, self.btn_save,
            '->',
            self.tab_btn,
            { icon:'/static/images/icons/close.png', iconCls:'x-btn-icon', handler: function(){ 
                    if( self.fireEvent('beforeclose') === false ) {
                        return;
                    }
                    self.destroy();
                    if( ! self.is_tab ) {
                        //Baseliner.viewport.remove( kanban );
                        Baseliner.main.getEl().show();
                        Baseliner.viewport.getLayout().setActiveItem( 0 );
                    }
                    self.fireEvent('close');
                }
            }
        ];

        self.on('afterrender', function(cmp){
            // load data
            self.load_data();
        });

        self.on('dragstart', function(e) {
            var portlet = e.panel;
            var mid =  portlet.mid;
            var id_status_current = portlet.id_status;
            var dests = {};
            // reconfigure workflow
            var wk = self.workflow[ mid ];
            if( wk ) {
                for( var i=0; i<wk.length; i++ ) {
                    if( wk[i].id_status_from == id_status_current ) {
                        dests[ wk[i].id_status_to ] = true;
                    }
                }
            }
            // mask columns
            var cols = self.items.items;
            // find the highest column
            var max_height = 0;
            Ext.each( cols, function(c){
                var h = c.el.getHeight();
                if( h > max_height )
                    max_height = h;
            });
            if( self.body.getHeight() -10  > max_height ) {
                max_height = self.body.getHeight() - 10;
            }
            Ext.each( cols, function(c){
                var el = c.getEl();
                el.setHeight( max_height );  // so that the mask have the full length
                var id_status = c.id_status;
                if( dests[ id_status ] != true && id_status != id_status_current ) {
                    var m = el.mask();
                    c.drop_available = false;
                } else {
                    c.drop_available = true;
                }
            });
        });
        self.on('beforedragover', function(e){
            return e.column.drop_available; //==undefined ? false : e.column.drop_available;
        });
        self.on('beforedrop', function(e){
            var col = e.column;
            Ext.each( self.items.items, function(c) {
                var el = c.getEl();
                el.unmask();
                el.setHeight('auto');
                //c.doLayout();
            });
            // send data to server
            var portlet = e.panel;
            return portlet.change_status( col, function(res){
                if( !res.success ) {
                    Baseliner.warning( _('Kanban'), _(res.msg) );
                    // send portlet back to where it came from
                    var old_status = portlet.id_status;
                    var old_column_id = self.column_by_status[ old_status ]; 
                    var old_column = Ext.getCmp( old_column_id );
                    if( old_column ) {
                        old_column.add( portlet );
                        old_column.doLayout();
                    } else {
                        portlet.destroy();
                    }
                } else {
                    // update portlet data
                    var previous_id_status = portlet.id_status;
                    portlet.id_status = e.column.id_status;
                }
            });
            //return true;
        });
        /*
        self.on('drop', function(e){
        });
        */

        Baseliner.Kanban.superclass.initComponent.call(this);
    },
    print_hook : function(){
        return { title: this.title, id: this.body.id };
    },
    fullscreen : function(){
        var self = this;
        self.is_fullscreen = true;
        self.is_tab = false;
        Baseliner.viewport.add( self );
        Baseliner.viewport.getLayout().setActiveItem( self );
    },
    goto_tab : function(){
        var self = this;
        self.is_tab = true;
        var params = { tab_icon: '/static/images/icons/kanban.png' };  
        self.tab_info = { type: 'object', params: params }; // XXX this should be simplified
        var id = Baseliner.addNewTabItem( self, self.title, params );
        if( self.is_fullscreen ) {
            Baseliner.viewport.remove( self, false );
            Baseliner.main.getEl().show();
            Baseliner.viewport.getLayout().setActiveItem( 0 );
        }
        self.is_fullscreen = false;
        self.fireEvent( 'tab', id );
    },
    check_column : function(opt){
        var self = this;
        var id_status = opt.id_status;
        self.items.each( function(i){
            if( i.id_status == id_status ) {
                if( opt.checked && ! i.isVisible() ) { // show
                    i.show();
                } else if( i.isVisible() ) { // hide
                    i.hide();
                }
                self.reconfigure_columns();
            }
        });
    },
    refresh : function(){
        var self =this;
        self.removeAll();
        self.store = null;
        self.load_data();
    },
    load_data : function() {
        var self = this;
        self.el.mask( _('Loading...'), 'x-mask-loading');
        if( ! self.store ) {
            if( Ext.isArray( self.topics ) && self.topics.length > 0 ) {
                // create my own store
                self.store = new Baseliner.Topic.StoreList({
                    baseParams: { start: 0, topic_list: self.topics }   // query_id
                });
                self.store.on('load', function(){
                    self.load_workflow( self.topics );
                });
                self.store.load();
            } else {
                // no topics to show
                Baseliner.warning( _('Kanban'), _('No topics available') );
                self.el.unmask();
            }
        }
        else {
            var filtered_mids = {};
            var filtered_mode = Ext.isArray(self.topics) && self.topics.length > 0 ? true : false;
            Ext.each( self.topics, function(mid){ filtered_mids[mid] = true; });
            self.store.each( function(rec) {
                // if we have a list of mids, check if row is in list
                if( filtered_mode && !mids_hash[mid] ) return;
                self.topics.push( rec.data.topic_mid );
            });
            self.load_workflow( self.topics );
        }
    },
    load_workflow : function(topics) {
        var self = this;
        Baseliner.ajaxEval( '/topic/kanban_status', { mid: self.topic_mid, topics: topics }, function(res){
            if( res.success ) {
                //console.log( res.workflow );
                var statuses = res.statuses;
                var workflow = res.workflow;
                var visible_status = res.visible_status;
                var status_mids = res.status_mids;
                var col_num = statuses.length;
                //var col_width = 1 / col_num;
                var btns = [];
                self.workflow = workflow;
                var kvisible = 0;

                for( var i=0; i<col_num; i++ ) {
                    var cs = statuses[i];
                    var smids = status_mids[cs.id];
                    //cs.visible = col_num<10 || (smids && smids.length > 0); 
                    cs.visible = visible_status[ cs.id ];
                    if( cs.visible ) kvisible++;
                    self.statuses_hash[ cs.name ] = { colnum: i, hidden: !cs.visible };  // store colnum for status
                }
                var col_width = 1 / kvisible;
                var add_column = function( id_status, name, visible, bl ) {
                   var status_title = 
                       '<div id="boot" style="background:transparent;font-size:8px;font-family:Helvetica Neue,Helvetica,Arial,sans-serif; padding: 4px 4px 4px 4px">' 
                       + _(name) + ( !bl || bl=='*' ? '' : '&nbsp;<div class="label" style="font-size: 8px;background-color:#666;">'
                        + bl+'</div>' ) + '</div>';
                   // create columns
                   var col_obj = new Baseliner.KanbanColumn({
                       xtype: 'kanbancolumn',
                       title: status_title,
                       hidden: !visible,
                       columnWidth: col_width,
                       bl: bl,
                       status_name: name,
                       id_status: id_status
                   });
                   self.add( col_obj );
                   self.column_by_status[ id_status ] = col_obj.id;
                };
                Ext.each( statuses, function(cs){
                    add_column( cs.id, cs.name, cs.visible, cs.bl );
                });

                for( var k=0; k< statuses.length; k++ ) {
                    var cs = statuses[k];
                    self.status_btn.menu.addMenuItem({ 
                        id_status: cs.id, text: cs.name, 
                        checked: !!cs.visible, 
                        checkHandler: function(opt){ return self.check_column(opt) } 
                    });
                }

                self.render_me();
                self.fireEvent( 'ready', res );
            } else {
                Ext.Msg.alert( _('Error'), res.msg );
            }
        });
    },
    reload : function(){  // used by topics when refreshing _parent_grid
        var self = this;
        self.refresh(); 
    },
    create_portlets : function( id_status ){
        var self = this;
        self.store.each( function(rec) {
            var mid = rec.data.topic_mid;
            if( id_status != undefined && rec.data.category_status_id != id_status ) return;
            var t = String.format('{0} #{1}', rec.data.category_name, mid );
            var cat = '<div id="boot"><span class="label" style="float:left;width:95%;background: '+ rec.data.category_color + '">' + rec.data.category_name + ' #' + mid + '</span></div>';
            var txt = String.format('<span id="boot">{0}<br /><h5>{1}</h5></span>', cat, _( rec.data.title ) );
            //var txt = String.format('<span id="boot"><h5>{0}</h5></span>', rec.data.title);
            var sh = self.statuses_hash[ rec.data.category_status_name ];
            var col = sh ? sh.colnum : undefined;
            // portlet contents
            var contents = new Ext.Container({ html: txt, style:'padding: 2px 2px 2px 2px', autoHeight: true, mid: mid });
            contents.on('afterrender', function(){ 
                // double-click on portlet opens either window or tab
                this.ownerCt.body.on('dblclick',function(){ 
                    var title = rec.data.topic_name;
                    var params = { topic_mid: mid, title: _( title ), _parent_grid: self.id };
                    if( self.is_tab ) {
                        Baseliner.add_tabcomp( '/topic/view', _(title), params );
                    } else {
                        params.window_mode = true;
                        Baseliner.ajaxEval( '/topic/view', params, function(topic_panel) {
                            var win = new Baseliner.Window({
                                layout: 'fit', 
                                tabifiable : true,
                                //modal: true,
                                autoScroll: true,
                                style: { overflow: 'hide' },
                                border: false,
                                title: _(title),
                                height: 600, width: 1000, 
                                maximizable: true,
                                items: topic_panel
                            });
                            //topic_panel.on('afterrender', function(){ topic_panel.header.hide() } );
                            topic_panel.title = undefined;
                            topic_panel._parent_window = win.id;
                            win.show();
                        });
                    }
                });
            });
            self.add_portlet({ 
              title: _(t),
              comp: contents, 
              mid: mid,
              id_status: rec.data.category_status_id,
              portlet_type: 'comp',
              col: col,
              url_portlet: 'http://xxxx', url_max: 'http://xxxx'
            });
        });
    },
    // method to reconfigure all columnwidths
    reconfigure_columns :  function(){
        var self = this;
        var cols = self.items.items;
        var col_num = 0;
        for( var i = 0; i<cols.length; i++ ) {
            if( ! cols[i].hidden ) col_num++;
        }
        var col_width = 1/col_num;
        for( var i = 0; i<cols.length; i++ ) {
            cols[i].columnWidth = col_width;
        };
        self.doLayout();
    },
    // method to save current status visibility
    save_statuses :  function(){
        var self = this;
        var cols = self.items.items;
        var statuses = {};
        for( var i = 0; i<cols.length; i++ ) {
            statuses[ cols[i].id_status ] = !cols[i].hidden;
        }
        Cla.ajax_json('/topic/kanban_config', { mid: self.topic_mid, statuses: statuses }, function(){ });
    },
    render_me : function(){
        var self = this;
        self.create_portlets();
        self.doLayout();

        // show/hide tools for the column 
        var cols = self.findByType( 'kanbancolumn' );
        for( var i = 0; i<cols.length; i++ ) {
            cols[i].header.on( 'mouseover', function(ev,obj){
                var col_obj = Ext.getCmp( obj.id );
                if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.id );
                if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.parentNode.id );
                if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.parentNode.parentNode.id );
                if( col_obj != undefined ) {
                    var t = col_obj.getTool('close');
                    var w = col_obj.el.dom.offsetWidth;
                    t.setStyle('display','block');
                    t.setStyle('position','absolute');
                    t.setStyle('margin-left', w-30 );
                }
            });
            cols[i].header.on( 'mouseout', function(ev,obj){
                var col_obj = Ext.getCmp( obj.id );
                if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.id );
                if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.parentNode.id );
                if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.parentNode.parentNode.id );
                if( col_obj != undefined ) col_obj.getTool('close').hide();
            });
        };
        self.el.unmask();
    },
    add_portlet : function( params ) {
        var self = this;
        var col = params.col || 0;
        var comp = params.comp;
        comp.height = comp.height || 350;
        var title = comp.title || params.title || 'Portlet';
        //comp.collapsible = true;
        var cols = self.items.items;
        var column_obj = self.findById( cols[col].id );
        var portlet = {
            height: 50,
            autoHeight: true,
            header: false,
            footer: false,
            //collapsible: true,
            title: _( title ),
            mid: params.mid,
            id_status: params.id_status,
            //headerCfg: { style: 'background: #d44' },
            portlet_type: params.portlet_type,
            footerCfg: { hide: true },
            //url_portlet: params.url_portlet,
            url_max: params.url_max,
            //tools: Baseliner.portalTools,  // tools are visible when header: true
            //collapsed: true,
            items: comp
        };
        var portlet_obj = column_obj.add( portlet );
        portlet_obj.change_status = function(col, cb){
            var new_status = col.id_status;
            if ( new_status != portlet_obj.id_status ){                
                // check if we deploy
                if( col.bl && col.bl!='*' ) {
                    var fake_node = { attributes:{ data: {} } }; 
                    Baseliner.add_wincomp( '/job/create', _('New Job'), { node: {}, bl: col.bl, job_type: 'promote' } );
                    return false;
                } else {
                    Baseliner.ajaxEval( '/topic/change_status', { _handle_res: true, mid: portlet_obj.mid, old_status: portlet_obj.id_status, new_status: new_status }, function(res){
                        if( Ext.isFunction(cb) ) cb(res);
                    });
                    return true;
                }
            }
        };
        return portlet_obj;
        //column_obj.doLayout();
    }
});

Baseliner.KanbanPortlet = Ext.extend( Ext.util.Observable, {
    height: 50,
    autoHeight: true,
    header: false,
    footer: false
});

// Each column is a Panel (so that we have a title)
Baseliner.KanbanColumn = Ext.extend(Ext.Panel, {
    layout: 'anchor',
    autoEl: 'div',
    border: true,
    resizeable: true,
    tools: [{
        id:'close',
        hidden: true,
        handler: function(e, target, column_panel){
            var kanban = column_panel.ownerCt;
            column_panel.hide();
            //column_panel.ownerCt.remove(column_panel, true);
            kanban.reconfigure_columns();
            // remove check from menu
            var id_status = column_panel.initialConfig.id_status;
            kanban.status_btn.menu.items.each( function(i) {
                if( i.initialConfig.id_status == id_status  )
                    i.setChecked(  false );
            });
        }
    }],
    style: {
        margin: '2px 2px 2px 2px',
        //'border': '2px solid transparent',
        padding: '6px 2px 6px 2px'
    },
    headerCfg: {
        style: {
            'background-color': '#eee', color: '#555', height: '40px', 'text-transform': 'uppercase', 'font-weight':'bold',
            margin: '0px 0px 8px 0px',
            padding: '2px 2px 2px 2px',
            'font-size':'10px'
        }
    },
    bodyCfg: { 
        style: {
            margin: '0px 0px 0px 0px',
            padding: '2px 2px 2px 2px',
            'background': "transparent",
            'background-repeat': 'repeat'
        }
    },
    defaultType: 'portlet',
    cls:'x-portal-column'
});
Ext.reg('kanbancolumn', Baseliner.KanbanColumn);

