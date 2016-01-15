(function(params){
   var new_role_form = new Ext.FormPanel({
        url: '/role/update',
        region: 'north',
        frame: true,
        labelWidth: 100, 
        height: 110,
        layout:'column',
        defaults: { width: 250,  msgTarget: 'under' },
        items: [
            { columnWidth: .5,layout:'form', defaults:{ anchor:'100%' }, items:[
                {  xtype: 'hidden', name: 'id', value: -1 }, 
                {  xtype: 'textfield', name: 'name', fieldLabel: _('Role Name'), allowBlank: false }, 
                {  xtype: 'textarea', name: 'description', height: 60, fieldLabel: _('Description') }
              ]
            },
            { columnWidth: .5, layout:'form', defaults:{ anchor:'100%' }, bodyStyle:{ 'padding-left':'10px' }, items:[
                {  xtype: 'textfield', name: 'mailbox', fieldLabel: _('Mailbox') },
                new Baseliner.DashboardBox({ fieldLabel: _('Dashboards'), name:'dashboards', allowBlank: true })
              ]
            }
            // {  xtype: 'textfield', name: 'default_dashboard', fieldLabel: _('Default default_dashboard') }
        ]
    });

    var render_action = function(value,metadata,rec,rowIndex,colIndex,store) {
        var v = String.format('{0} (<code>{1}</code>)', _(value), rec.data.action );
        return v;
    }
    var cm = new Ext.grid.ColumnModel({
        defaults: {
            sortable: true // columns are not sortable by default           
        },
        columns: [
                { header: '', width: 20, dataIndex: 'action', sortable: false, renderer: function(){ return String.format('<img src="{0}"/>', IC('lock_small.png')) } },
                { header: _('Description'), width: 200, dataIndex: 'description', sortable: true, renderer: render_action },
                { header: _('Baseline'), width: 50, dataIndex: 'bl', sortable: true,
                          renderer: Baseliner.render_bl,
                          editor: new Baseliner.model.ComboBaseline()
                }
        ]
    });

    //////////////// Actions Tree
    var treeLoader = new Ext.tree.TreeLoader({
        dataUrl: '/role/action_tree',
        baseParams: { type: 'all' },
        preloadChildren:true
    });


    var tree_check_folder_enabled = function(root) { // checks if parent folder has children
            var flag= action_store.getCount()<1 ? false : true;
            root.eachChild( function(child) {
                if( ! child.disabled ) {
                    flag = false;
                }
            });
            if( flag )  root.disable();
            else        root.enable();
    };

    var tree_check_in_grid = function(node) {
            var ff = action_store.find('action', node.id );
            if( ff  >=0 ) { // check if its in the grid already
                node.disable();
            } else {
                node.enable();
            }
    };
    
    var tree_check = function(node) {
            if( node.isLeaf() ) {
                //TODO: activar cuando metamos metodo que compruebe todas las bl
                //tree_check_in_grid( node );
                tree_check_folder_enabled(node.parentNode);
            } else {
                node.eachChild( function(child) {
                    if( child.isLeaf() ) {
                        tree_check( child );
                    } else {
                        tree_check( child );
                        child.removeListener('expand', tree_check );
                        child.on({ 'expand': { fn: tree_check } });
                        if( child.hasChildNodes() )  {
                            // tree_check_folder_enabled(child);
                        }
                    }
                });
            }
    };
            
    var treeRoot = new Ext.tree.AsyncTreeNode({
            text: _('actions'),
            draggable: false,
            id:'action.root',
            listeners: {
                expand: tree_check
            }
    });
    
    var search_box = new Baseliner.SearchSimple({ 
        width: 220,
        handler: function(){
            var lo = action_tree.getLoader();
            lo.baseParams = { query: this.getValue() };
            Baseliner.showLoadingMask( action_tree.getEl() );
            lo.load( action_tree.root, function(){
                Baseliner.hideLoadingMask( action_tree.getEl() );
            });
        }
    });
    var action_tree = new Cla.Tree({
        title: _('Available Actions'),
        loader: treeLoader,
        loadMask: true,
        useArrows: true,
        ddGroup: 'secondGridDDGroup',
        animate: true,
        enableDrag: true,
        containerScroll: true,
        autoScroll: true,
        rootVisible: false,
        contextMenu: new Ext.menu.Menu({
            items: [
                {
                     type: 'expand',
                     text: 'Expand All'
                },
                {
                     type: 'collapse',
                     text: 'Collapse All'
                }
            ],
            listeners: {
                itemclick: function(item) {
                    switch (item.type) {
                        case 'expand' :
                            var n = item.parentMenu.contextNode;
                            n.expand(true);
                            break;
                        case 'collapse' :
                            var n = item.parentMenu.contextNode;
                            n.collapse(true);
                            break;
                    }
                }
            }
        }),
        root: treeRoot,
        tbar: [ search_box ],
        menu_click: function(node, e) {
            var c = node.getOwnerTree().contextMenu;
            c.contextNode = node;
            c.showAt(e.getXY());
        },
        listeners: {
            'render': function() {
                Baseliner.showLoadingMask( this.getEl() , _('Loading...') );
            },
            'load': function() {
                this.getEl().unmask();
            }
        }
    });

    var store_role_users=new Baseliner.JsonStore({ 
        root: 'data',
        remoteSort: true,
        totalProperty: 'totalCount',
        id: 'id',
        baseParams: { id_role: params.id_role },
        url: '/role/roleusers',
        fields: [ 'user','projects' ]
    });
    var role_users = new Ext.grid.GridPanel({
        title: _('Users'),
        store: store_role_users,
        defaults: { sortable: true },
        autoScroll: true,
        viewConfig: { forceFit: true },
        columns: [
            { header: _('User'), width: 100, dataIndex: 'user', sortable: true },	
            { header: _('Scopes'), width: 100, dataIndex: 'projects', sortable: true, renderer: Baseliner.render_wrap }
        ]
    });
    role_users.on('activate', function(){
        if( params.id_role && store_role_users.getCount() == 0 ) 
            store_role_users.load();
    });

    var store_role_projects=new Baseliner.JsonStore({ 
        root: 'data',
        remoteSort: true,
        totalProperty: 'totalCount',
        id: 'id',
        baseParams: { id_role: params.id_role },
        url: '/role/roleprojects',
        fields: [ 'project','users' ]
    });
    var role_projects = new Ext.grid.GridPanel({
        title: _('Scopes'),
        store: store_role_projects,
        defaults: { sortable: true },
        autoScroll: true,
        viewConfig: { forceFit: true },
        columns: [
            { header: _('Scopes'), width: 100, dataIndex: 'project', sortable: true },	
            { header: _('Users'), width: 100, dataIndex: 'users', sortable: true, renderer: Baseliner.render_wrap }
        ]
    });
    role_projects.on('activate', function(){
        if( params.id_role && store_role_projects.getCount() == 0 ) 
            store_role_projects.load();
    });

    var role_navigator = new Ext.TabPanel({
        region:'west',
        plugins: [new Ext.ux.panel.DraggableTabs()],
        split: true,
        width: '45%',
        colapsible: true,
        activeTab: 0,
        items: [ action_tree, role_users, role_projects ]
    });
    //////////////// Actions belonging to a role
    var action_store=new Ext.data.Store({ fields: [ {  name: 'action' }, {  name: 'description' }, { name: 'bl' } ] });
    
    var search_grid = new Baseliner.SearchSimple({ 
        width: 220,
        handler: function(){
            var v = this.getRawValue();
            if( !v || !v.length ) {
                this.el.dom.value = '';
                action_store.clearFilter();
                return;
            }
            var res = v.split(/\s+/).map(function(vv){ return new RegExp(vv,'i') });
            action_store.filterBy(function(rec) {
                var all = 0;
                for(var i=0; i<res.length; i++){
                    if( res[i].test(rec.data.description+';'+rec.data.action) ) {
                        all++;
                    }
                }
                return all == res.length;
            });
        }
    });

    var grid_role = new Ext.grid.EditorGridPanel({
        title: _('Role Actions'),
        region: 'center',
        autoScroll: true,
        store: action_store,
        split: true,
        viewConfig: { forceFit: true },
        clicksToEdit: 1,
        height: 300,
        width: 350,
        cm: cm,
        sm: new Baseliner.RowSelectionModel({ singleSelect: true }),
        tbar: [ 
            search_grid, '->',
            new Ext.Toolbar.Button({
                text: _('Remove Selection'),
                icon:'/static/images/icons/delete_red.png',
                cls: 'x-btn-text-icon',
                handler: function() {
                    var sm = grid_role.getSelectionModel();							
                    if (sm.hasSelection()) {
                        var sel = sm.getSelected();
                        grid_role.getStore().remove(sel);
                        tree_check( treeRoot );
                    }
                }
            }),
            new Ext.Toolbar.Button({
                text: _('Remove All'),
                icon:'/static/images/icons/del_all.png',
                cls: 'x-btn-text-icon',
                handler: function() {
                    grid_role.getStore().removeAll();
                    tree_check( treeRoot );
                }
            })
        ]
    });

    var action_grid_data = function() {
            // turn grid into JSON to post data
            var cnt = grid_role.getStore().getCount();
            var json = [];
            for( i=0; i<cnt; i++) {
                var rec = grid_role.getStore().getAt(i);
                json.push( Ext.util.JSON.encode( rec.data )) ;
            }
            var json_res = '[' + json.join(',') + ']';
            return json_res;
    };

    grid_role.on('afterrender', function(){
        Baseliner.showLoadingMask( grid_role.getEl() , _('Loading...') );
        ////////// Setup the Drop Target - now that the window is shown
        var secondGridDropTarget = new Baseliner.DropTarget(grid_role.getView().scroller.dom, {
                comp: grid_role,
                ddGroup    : 'secondGridDDGroup',
                notifyDrop : function(dd, e, data){
                        var n = dd.dragData.node;
                        var s = action_store;
                        var add_node = function(node ) {
                            //if( s.find('action', node.id ) < 0 ) {
                                var rec = new Ext.data.Record({ action: node.id, description: node.text, bl:'*' });
                                s.add(rec);
                                //s.sort('action', 'ASC');
                                var parent_node = node.parentNode;
                                // issue (GDF) fix ?
                                // node.disable();
                                tree_check_folder_enabled(parent_node);
                            //}
                        };

                        if( n.leaf ) {
                            add_node(n);
                        } else {
                            n.expand();
                            n.eachChild( function(child) {
                                if( ! child.disabled ) 
                                    add_node( child );
                            });
                        }
                        return true;
                }
        });
    });

    ////////var win_choose_bl = new Ext.Window({
    ////////    layout: 'border',
    ////////    height: 450, width: 600,
    ////////    closeAction: 'close',
    ////////    autoDestroy: true,
    ////////    title: _('Create Role'),
    ////////      items : [
    ////////         { xtype: 'form',
    ////////          items: new Baseliner.model.ComboBaseline()
    ////////         }
    ////////      ] 
    ////////});

    ////////// Role Single Row
    var role_data_store=new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'rownum', 
        url: '/role/role_detail_json',
        fields: [ 
            {  name: 'id' },
            {  name: 'name' },
            {  name: 'actions' },
            {  name: 'bl' },
            {  name: 'description' },
            {  name: 'mailbox' },
            {  name: 'dashboards' }
        ]
    });

    ///////// Single Role Data Load Event
    role_data_store.on('load', function() {
        try {
            var rec = role_data_store.getAt(0);
            //////// Load form and grid data
            action_store.removeAll();
            if( rec && rec.data.id ) {
                // Grid
                var gs = action_store;
                var rd = rec.data.actions;
                if( rd!=undefined ) {
                    for( var i=0; i < rd.length; i++ ) {
                        var rec_action = new Ext.data.Record( rd[i] );
                        gs.add( rec_action );
                    }
                }
                // Form
                var ff = new_role_form.getForm();
                ff.loadRecord( rec );
            }
            Baseliner.hideLoadingMask( grid_role.getEl() );
        } catch(e) {
            Cla.error(_('Error'), _('Could not load role form data') + ': ' + e.description );
        }
    });

    ////////// Single Role Data Load
    role_data_store.load({ params:{ id: params.id_role } }); 

    var panel_title = params.id_role ? _('Role: %1', params.role ) : _('New Role');
    var role_panel = new Ext.Panel({
        layout: 'border',
        tab_icon:IC('role'),
        tbar: [
            '->',
            {  text: _('Save'),
                cls: 'ui-comp-role-edit-save',
                icon: IC('save'),
                handler: function(){ 
                    var ff = new_role_form.getForm();
                    if( ! ff.isValid() ) return;
                    action_store.clearFilter();
                    var actions_json = action_grid_data();
                    ff.submit({
                        params: { role_actions: actions_json },
                        success: function(form, action) { 
                            ff.findField("id").setValue(action.result.id);
                            var grid = Ext.getCmp( params.id_grid ); 
                            if( grid ) {
                                grid.getStore().load();
                            }
                            Baseliner.message(_("Save role"), _("Role saved successfully"));
                        },
                        failure: function(form, action) { Baseliner.message( _("Save role")), _("Failure") + ":" + action.result.msg; }
                    });
                }
            },
            {  text: _('Close') , cls: 'ui-comp-role-edit-close', icon: IC('close'), handler: function(){  role_panel.destroy() } }
        ],
        title: panel_title,
          items : [
              new_role_form,
              grid_role,
              role_navigator
          ] 
    });
    
    return role_panel; 
})
