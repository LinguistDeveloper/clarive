(function(params){
    var ps = 30;
    var rules_store = new Baseliner.JsonStore({
        url: '/rule/grid', root: 'data',
        id: 'id', totalProperty: 'totalCount', 
        fields: [ 'rule_name', 'rule_type', 'rule_when', 'rule_event', 'rule_active', 'event_name', 'id' ]
    });
    var search_field = new Baseliner.SearchField({
        store: rules_store,
        width: 140,
        params: {start: 0, limit: ps },
        emptyText: _('<search>')
    });

    var rule_del = function(){
        var sm = rules_grid.getSelectionModel();
        if( sm.hasSelection() ) {
            Baseliner.confirm( _('Delete rule %1?', sm.getSelected().data.rule_name ), function(){
                var id_rule = sm.getSelected().data.id;
                Baseliner.ajaxEval( '/rule/delete', { id_rule: id_rule }, function(res){
                    if( res.success ) {
                        rules_store.reload();
                        Baseliner.message( _('Rule'), res.msg );
                        // remove tab if any
                        var tab_arr = tabpanel.find( 'id_rule', id_rule );
                        if( tab_arr.length > 0 ) {
                            tabpanel.remove( tab_arr[0] );
                        }
                    } else {
                        Baseliner.error( _('Error'), res.msg );
                    }
                });
            });
        }
    };
    var rule_activate = function(){
        var sm = rules_grid.getSelectionModel();
        if( sm.hasSelection() ) {
            var activate = sm.getSelected().data.rule_active > 0 ? 0 : 1;
            Baseliner.ajaxEval( '/rule/activate', { id_rule: sm.getSelected().data.id, activate: activate }, function(res){
                if( res.success ) {
                    rules_store.reload();
                    Baseliner.message( _('Rule'), res.msg );
                } else {
                    Baseliner.error( _('Error'), res.msg );
                }
            });
        }
    };
    var rule_edit = function(){
        var sm = rules_grid.getSelectionModel();
        if( sm.hasSelection() ) {
            Baseliner.ajaxEval( '/rule/get', { id_rule: sm.getSelected().data.id }, function(res){
                if( res.success ) {
                    rule_editor( res.rec );
                } else {
                    Baseliner.error( _('Error'), res.msg );
                }
            });
        }
    };
    var rule_add = function(){
        rule_editor({});
    };
    var rule_editor = function(rec){
        Baseliner.ajaxEval( '/comp/rule_new.js', { rec: rec }, function(comp){
            if( comp ) {
                var win = new Baseliner.Window({
                    title: _('Edit Rule'),
                    width: 900,
                    items: [ comp ]
                });
                comp.on('destroy', function(){
                    win.close()
                    rules_store.reload();
                });
                win.show();
            }
        });
    };

    var render_actions = function(value,row){
        return '';
    };
    var tree_load = function(){
        var loader = tree.getLoader();
        loader.load(tree.root);
        tree.root.expand();
    };

    var render_rule = function( v,metadata,rec ) {
        if( rec.data.rule_active == 0 ) 
            v = String.format('<span style="text-decoration: line-through">{0}</span>', v );
        return String.format(
            '<div style="float:left"><img src="{0}" /></div>&nbsp;'
            + '<b>{2}: {1}</b>',
            '/static/images/icons/rule.png',
            v, rec.data.id
        );
    };
    var rules_grid = new Ext.grid.GridPanel({
        region: 'west',
        width: 300,
        split: true,
        collapsible: true,
        viewConfig: {
            enableRowBody: true,
            forceFit: true,
            getRowClass : function(rec, index, p, store){
                //p.body = String.format( '<div style="margin: 0 0 0 32;"><table><tr>'
                p.body = String.format( '<div style="margin: 0 0 0 32;">{0}</div>', _('%1 for event "%2"', _(rec.data.rule_when), rec.data.rule_event ) );
                return ' x-grid3-row-expanded';
            }
        },
        header: false,
        store: rules_store,
        columns:[
            { header: _('Rule'), width: 160, dataIndex: 'rule_name', renderer: render_rule },
            { header: _('Type'), width: 40, dataIndex: 'rule_type' }
        ],
        tbar: [ 
            search_field,
            { xtype: 'button', handler: function(){ rules_store.reload() }, icon:'/static/images/icons/refresh.gif', cls:'x-btn-icon' },
            { xtype:'button', icon: '/static/images/icons/add.gif', cls: 'x-btn-icon', handler: rule_add },
            { xtype:'button', icon: '/static/images/icons/edit.gif', cls: 'x-btn-icon', handler: rule_edit },
            { xtype:'button', icon: '/static/images/icons/delete.gif', cls: 'x-btn-icon', handler: rule_del },
            { xtype:'button', icon: '/static/images/icons/activate.png', cls: 'x-btn-icon', handler: rule_activate },
            { xtype:'button', icon: '/static/images/icons/downloads_favicon.png', cls: 'x-btn-icon' }
        ]
    });
    rules_store.load();
    rules_grid.on('rowclick', function(grid, ix){
        var rec = rules_store.getAt( ix );
        if( rec ) {
            var tab_arr = tabpanel.find( 'id_rule', rec.data.id );
            if( tab_arr.length > 0 ) {
                tabpanel.setActiveTab( tab_arr[0] );
            } else {
                rule_flow_show( rec.data.id, rec.data.rule_name, rec.data.event_name, rec.data.rule_event );
            }
        }
    });
   
    var encode_tree = function( root ){
        var stmts = [];
        root.eachChild( function(n){
            stmts.push({ attributes: n.attributes, children: encode_tree( n ) });
        });
        return stmts;
    };

    var clipboard;
    var cut_node = function( node ) {
        clipboard = { node: node };
    };
    var clone_node = function(node){    
        var copy = new Ext.tree.TreeNode( Ext.apply({}, node.attributes) ) 
        node.eachChild( function( chi ){
            copy.appendChild( clone_node( chi ) );
        });
        return copy;
    };
    var copy_node = function( node ) {
        var copy = clone_node( node ); 
        clipboard = { node: copy };
    };
    var paste_node = function( node ) {
        if( clipboard ) {
            var p = clipboard.node;
            p.id = Ext.id();
            node.appendChild( p );
        }
        //clipboard = 
    };
    var edit_node = function( node ) {
        var key = node.attributes.key;
        if( ! key ) {
            Baseliner.error( _('Missing key'), 
                _("Service '%1' does not contain edit information", node.text) );
            return;
        }
        Baseliner.ajaxEval( '/rule/edit_key', { key: key }, function(res){
            if( res.success ) {
                var show_win = function(item, opts) {
                    var win = new Baseliner.Window(Ext.apply({
                        layout: 'fit',
                        title: _('Edit'),
                        items: item
                    }, opts));
                    item.on('destroy', function(){
                        //console.log( item.data );
                        if( item.data ) node.attributes.data = item.data; 
                        win.close();
                    });
                    win.show();
                };
                if( res.form ) {
                    Baseliner.ajaxEval( res.form, { data: node.attributes.data }, function(comp){
                        var params = {};
                        var save_form = function(){
                            form.data = form.getForm().getValues();
                            form.destroy();
                        };
                        var form = new Ext.FormPanel({ 
                            frame: false, forceFit: true, defaults: { msgTarget: 'under' },
                            width: 800,
                            height: 500,
                            bodyStyle: { padding: '4px', "background-color": '#eee' },
                            tbar: [
                                { xtype:'button', text:_('Save'), handler: save_form },
                                { xtype:'button', text:_('Cancel'), handler: function(){ form.destroy() } }
                            ],
                            items: comp
                        });
                        show_win( form );
                    });
                } else {
                    var node_data = Ext.apply( res.config, node.attributes.data );
                    var comp = new Baseliner.DataEditor({ data: node_data });
                    show_win( comp, { width: 800, height: 400 } );
                }
            } else {
                Baseliner.error( _('Error'), res.msg );
            }
        });
    };
    var rule_flow_show = function( id_rule, name, event_name, rule_event ) {
        var drop_handler = function(e) {
            var n1 = e.source.dragData.node;
            var n2 = e.target;
            if( n1 == undefined || n2 == undefined ) return false;
            var attr1 = n1.attributes;
            var attr2 = n2.attributes;
            if( attr1.palette ) {
                if( attr1.holds_children ) {
                    attr1.leaf = false;
                } 
                var copy = new Ext.tree.TreeNode( Ext.apply({}, attr1) );
                copy.attributes.palette = false;
                e.dropNode = copy;
            }
            return true;
        };
        var rule_tree_loader = new Ext.tree.TreeLoader({
            dataUrl: '/rule/stmts_load',
            baseParams: { id_rule: id_rule },
            //requestMethod:'GET',
            //uiProviders: { 'col': Ext.tree.ColumnNodeUI }
        });
        var rule_save = function(opt){
            var root = rule_tree.root;
            var stmts = encode_tree( root );
            var json = Ext.util.JSON.encode( stmts );
            Baseliner.ajaxEval( '/rule/stmts_save', { id_rule: id_rule, stmts: json }, function(res) {
                if( res.success ) {
                    Baseliner.message( _('Rule'), res.msg );
                    if( opt.callback ) {
                        opt.callback( res );
                    }
                } else {
                    Baseliner.error( _('Error saving rule'), res.msg );
                }
            });
        };
        var rule_load = function(){
            rule_tree_loader.load( rule_tree.root );
            rule_tree.root.expand();
        };
        var rule_dsl = function(){
            var root = rule_tree.root;
            //rule_save({ callback: function(res) { } });
            var stmts = encode_tree( root );
            var json = Ext.util.JSON.encode( stmts );
            Baseliner.ajaxEval( '/rule/dsl', { id_rule: id_rule, stmts: json, event_key: rule_event }, function(res) {
                if( res.success ) {
                    var editor;
                    var idtxt = Ext.id();
                    var data_txt = new Ext.form.TextArea({ region:'west', width: 140, value: res.event_data_yaml });
                    var dsl_txt = new Ext.form.TextArea({  value: res.dsl });
                    var dsl_cons = new Ext.form.TextArea({ style:'color: #191; background-color:#000;' });
                    var dsl_run = function(){
                        Baseliner.ajaxEval( '/rule/dsl_try', { data: data_txt.getValue(), dsl: editor.getValue(), event_key: rule_event }, function(res) {
                            dsl_cons.setValue( res.msg ); 
                        });
                    };
                    var win = new Baseliner.Window({
                       layout: 'border', width: 800, height: 600, maximizable: true,
                       tbar: [ { text:_('Run'), icon:'/static/images/icons/run.png', handler: dsl_run } ],
                       items: [
                           data_txt,
                           { region:'center', xtype:'panel', height: 400, items:dsl_txt  },
                           { xtype:'panel', items:dsl_cons, region:'south', split: true, height:200, layout:'fit' }
                       ]
                    });
                    dsl_txt.on('afterrender', function(){
                        editor = CodeMirror.fromTextArea( dsl_txt.getEl().dom , Ext.apply({
                               lineNumbers: true,
                               tabMode: "indent", smartIndent: true,
                               matchBrackets: true
                            }, Baseliner.editor_defaults )
                        );
                    });
                    win.show();
                } else {
                    Baseliner.error( _('Error saving rule'), res.msg );
                }
            });
        };
        var short_name = name.length > 10 ? name.substring(0,20) : name;
        var menu_click = function(node,event){
            node.select();
            var stmts_menu = new Ext.menu.Menu({
                items: [
                    { text: _('Edit'), handler: function(){ edit_node( node ) }, icon:'/static/images/icons/edit.gif' },
                    { text: _('Copy'), handler: function(item){ copy_node( node ) }, icon:'/static/images/icons/copy.gif' },
                    { text: _('Cut'), handler: function(item){ cut_node( node ) }, icon:'/static/images/icons/cut.gif' },
                    { text: _('Paste'), handler: function(item){ paste_node( node ) }, icon:'/static/images/icons/paste.png' },
                    { text: _('Delete'), handler: function(item){ node.remove() }, icon:'/static/images/icons/delete.gif' } 
                ]
            });
            stmts_menu.showAt(event.xy);
        };
        var rule_tree = new Ext.tree.TreePanel({
            region: 'center',
            id_rule: id_rule,
            closable: true,
            title: String.format('{0}: {1}', id_rule, short_name), 
            autoScroll: true,
            useArrows: true,
            animate: true,
            lines: true,
            //stripeRows: true,
            enableSort: true,
            enableDD: true,
            ddScroll: true,
            loader: rule_tree_loader,
            listeners: {
                beforenodedrop: { fn: drop_handler },
                contextmenu: menu_click
            },
            rootVisible: true,
            tbar: [ 
                { xtype:'button', text: _('Save'), icon:'/static/images/icons/save.png', handler: rule_save },
                { xtype:'button', text: _('Reload'), icon:'/static/images/icons/refresh.gif', handler: rule_load },
                { xtype:'button', text: _('DSL'), icon:'/static/images/icons/edit.png', handler: rule_dsl }
            ],
            root: { text: _('Start: %1', event_name), draggable: false, id: 'root', expanded: true }
        });
        var tab = tabpanel.add( rule_tree ); 
        tabpanel.setActiveTab( tab );
        tabpanel.changeTabIcon( tab, '/static/images/icons/rule.png' );
    };
    /* 
    var tree = new Ext.tree.TreePanel({
        region: 'center',
        autoScroll: true,
        animate: true,
        lines: true,
        stripeRows: true,
        enableSort: false,
        enableDD: true,
        dataUrl: '/rule/tree',
        listeners: {
            beforenodedrop: { fn: drop_handler }
        },
        rootVisible: true,
        useArrows: true,
        root: { nodeType: 'async', text: 'Reglas', draggable: false, id: 'root', expanded: true }
    });
    */
    var tabpanel = new Ext.TabPanel({
        region: 'center',
        items: []
    });
    var palette_fake_store = {  // the SearchField needs a store, but the tree doesnt have one
        baseParams: {},
        reload: function(config){
            var lo = palette.getLoader();
            lo.baseParams = palette_fake_store.baseParams;
            lo.load( palette.root );
        }
    };
    var search_palette = new Baseliner.SearchField({
        store: palette_fake_store,
        width: 220,
        params: {start: 0, limit: ps },
        emptyText: _('<search>')
    });
    var palette = new Ext.tree.TreePanel({
        region: 'east',
        title: _('Palette'),
        width: 250,
        autoScroll: true,
        split: true,
        animate: true,
        lines: true,
        enableDrag: true,
        collapsible: true,
        resizable: true,
        tbar: [search_palette],
        dataUrl: '/rule/palette',
        rootVisible: false,
        useArrows: true,
        root: { nodeType: 'async', text: 'Palette', draggable: false, id: 'root', expanded: true }
    });
    var panel = new Ext.Panel({
        layout: 'border',
        items: [ rules_grid, tabpanel, palette ]
    });

    return panel;
})
