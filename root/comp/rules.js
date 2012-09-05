(function(params){
    var ps = 30;
    var rule_store = new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        url: '/rule/list',
        baseParams: Ext.apply({ start:0, limit: ps}, params),
        fields: [ 'mid','_id','_parent','_is_leaf','type', 'item','class','versionid','ts','tags','data','properties','icon','collection']
    });
    var search_field = new Baseliner.SearchField({
        store: rule_store,
        width: 140,
        params: {start: 0, limit: ps },
        emptyText: _('<search>')
    });

    var rule_del = function(){
        var sm = rules_grid.getSelectionModel();
        if( sm.hasSelection() ) {
            Baseliner.ajaxEval( '/rule/delete', { id_rule: sm.getSelected().data.id }, function(res){
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
                    rule_add( res.rec );
                } else {
                    Baseliner.error( _('Error'), res.msg );
                }
            });
        }
    };
    var rule_add = function(rec){
        Baseliner.ajaxEval( '/comp/rule_new.js', { rec: rec }, function(comp){
            if( comp ) {
                var win = new Ext.Window({
                    title: _('Edit Rule'),
                    width: 900,
                    items: [ comp ]
                });
                win.show();
                win.on('close', function(){
                    rule_store.reload();
                });
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

    var rules_store = new Baseliner.JsonStore({
        url: '/rule/grid', root: 'data',
        id: 'id', totalProperty: 'totalCount', 
        fields: [ 'rule_name', 'rule_type', 'id' ]
    });
    var render_rule = function( v,metadata,rec ) {
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
                p.body = String.format( '<div style="margin: 0 0 0 32;">{0}</div>', 'when an event of type "New Topic" fires' );
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
                rule_flow_show( rec.data.id, rec.data.rule_name );
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
                var show_win = function(items) {
                    var win = new Ext.Window({
                        title: _('Edit'),
                        items: items,
                        width: 500,
                        height: 400
                    });
                    win.show();
                };
                if( res.form ) {
                    Baseliner.ajaxEval( res.form, {}, function(comp){
                        show_win( comp );
                    });
                } else {
                    var comp = new Baseliner.DataViewer({ data: res.config });
                }
            } else {
                Baseliner.error( _('Error'), res.msg );
            }
        });
    };
    var rule_flow_show = function( id_rule, name ) {
        var drop_handler = function(e) {
            var n1 = e.source.dragData.node;
            var n2 = e.target;
            if( n1 == undefined || n2 == undefined ) return false;
            var attr1 = n1.attributes;
            var attr2 = n2.attributes;
            if( attr1.palette ) {
                var copy = new Ext.tree.TreeNode( Ext.apply({}, attr1) );
                if( attr1.holds_children ) {
                    copy.leaf = false;
                } 
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
        var rule_save = function(){
            var root = rule_tree.root;
            var stmts = encode_tree( root );
            var json = Ext.util.JSON.encode( stmts );
            Baseliner.ajaxEval( '/rule/stmts_save', { id_rule: id_rule, stmts: json }, function(res) {
                if( res.success ) {
                    Baseliner.message( _('Rule'), res.msg );
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
            loader: rule_tree_loader,
            listeners: {
                beforenodedrop: { fn: drop_handler },
                contextmenu: menu_click
            },
            rootVisible: true,
            tbar: [ 
                { xtype:'button', text: _('Save'), handler: rule_save }
            ],
            root: { nodeType: 'async', text: _('Start'), draggable: false, id: 'root', expanded: true },
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
            beforenodedrop: { fn: drop_handler },
        },
        rootVisible: true,
        useArrows: true,
        root: { nodeType: 'async', text: 'Reglas', draggable: false, id: 'root', expanded: true },
    });
    */
    var tabpanel = new Ext.TabPanel({
        region: 'center',
        items: []
    });
    var palette = new Ext.tree.TreePanel({
        region: 'east',
        width: 250,
        autoScroll: true,
        split: true,
        animate: true,
        lines: true,
        enableDrag: true,
        collapsible: true,
        resizable: true,
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
