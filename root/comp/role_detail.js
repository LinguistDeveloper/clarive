(function(params){
   var new_role_form = new Ext.FormPanel({
        url: '/role/update',
        region: 'center',
        frame: true,
        labelWidth: 100, 
        defaults: { width: 250,  msgTarget: 'under' },
        buttons: [
            {  text: _('OK'),
                handler: function(){ 
                    var ff = new_role_form.getForm();
                    if( ! ff.isValid() ) return;
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
            {  text: _('Cancel') , handler: function(){  role_panel.destroy() } },
            {  text: _('Close') , handler: function(){  role_panel.destroy() } }
        ],
        items: [
            {  xtype: 'hidden', name: 'id', value: -1 }, 
            {  xtype: 'textfield', name: 'name', fieldLabel: _('Role Name'), allowBlank: false }, 
            {  xtype: 'textarea', name: 'description', height: 100, fieldLabel: _('Description') },
            {  xtype: 'textfield', name: 'mailbox', fieldLabel: _('Mailbox') },
            new Baseliner.DashboardBox({ fieldLabel: _('Dashboards'), name:'dashboards', allowBlank: true })
            // {  xtype: 'textfield', name: 'default_dashboard', fieldLabel: _('Default default_dashboard') }
        ]
    });


    var cm = new Ext.grid.ColumnModel({
        defaults: {
            sortable: true // columns are not sortable by default           
        },
        columns: [
                { header: _('Action'), width: 200, dataIndex: 'action', sortable: true },	
                { header: _('Description'), width: 200, dataIndex: 'description', sortable: true, renderer: Baseliner.render_loc },
                { header: _('Baseline'), width: 150, dataIndex: 'bl', sortable: true,
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
                            tree_check_folder_enabled(child);
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

    
    var new_role_tree = new Ext.tree.TreePanel({
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
        root: treeRoot,
        listeners: {
            'render': function() {
                this.getEl().mask(_("Loading"), 'x-mask-loading').setHeight( 99999 );
            },
            'load': function() {
                new_role_tree.getEl().unmask();
            }          
        }
    });
    
    // Baseliner.showLoadingMask( new_role_tree.getEl() , _('Loading...') );

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
        stripeRows: true,
        autoScroll: true,
        viewConfig: { forceFit: true },
        columns: [
            { header: _('User'), width: 100, dataIndex: 'user', sortable: true },	
            { header: _('Projects'), width: 100, dataIndex: 'projects', sortable: true, renderer: Baseliner.render_wrap }
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
        title: _('Projects'),
        store: store_role_projects,
        defaults: { sortable: true },
        stripeRows: true,
        autoScroll: true,
        viewConfig: { forceFit: true },
        columns: [
            { header: _('Project'), width: 100, dataIndex: 'project', sortable: true },	
            { header: _('Users'), width: 100, dataIndex: 'users', sortable: true, renderer: Baseliner.render_wrap }
        ]
    });
    role_projects.on('activate', function(){
        if( params.id_role && store_role_projects.getCount() == 0 ) 
            store_role_projects.load();
    });

    var role_navigator = new Ext.TabPanel({
        region:'west',
        split: true,
        width: '50%',
        colapsible: true,
        activeTab: 0,
        items: [ new_role_tree, role_users, role_projects ]
    });
    //////////////// Actions belonging to a role
    var action_store=new Ext.data.Store({ fields: [ {  name: 'action' }, {  name: 'description' }, { name: 'bl' } ] });
    
    //////var cm = new Ext.grid.ColumnModel({
    //////    defaults: {
    //////        sortable: true // columns are not sortable by default           
    //////    },
    //////    columns: [
    //////            { header: _('Action'), width: 200, dataIndex: 'action', sortable: true },	
    //////            { header: _('Description'), width: 200, dataIndex: 'description', sortable: true, renderer: Baseliner.render_loc },
    //////            { header: _('Baseline'), width: 150, dataIndex: 'bl', sortable: true,
    //////                      renderer: Baseliner.render_bl,
    //////                      editor: new Baseliner.model.ComboBaseline()
    //////            }
    //////    ]
    //////});
    
    var grid_role = new Ext.grid.EditorGridPanel({
        title: _('Role Actions'),
        region: 'south',
        stripeRows: true,
        autoScroll: true,
        store: action_store,
        split: true,
        viewConfig: { forceFit: true },
        clicksToEdit: 1,
        height: 300,
        width: 350,
        cm: cm,
        bbar: [ 
            new Ext.Toolbar.Button({
                text: _('Delete'),
                icon:'/static/images/del.gif',
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
                text: _('Delete All'),
                icon:'/static/images/del.gif',
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
            if( rec ) {
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
        } catch(e) {
            Ext.Msg.alert("<% _loc('Error') %>", "<% _loc('Could not load role form data') %>: " + e.description );
        }
    });

    ////////// Single Role Data Load
    if( params.id_role!=undefined ) {
       role_data_store.load({ params:{ id: params.id_role } }); 
    }

    var panel_title = params.id_role ? _('Role: %1', params.role ) : _('New Role');
    var role_panel = new Ext.Panel({
        layout: 'border',
        tab_icon:'/static/images/icons/users.gif',
        title: panel_title,
          items : [
              new_role_form,
              grid_role,
              role_navigator
          ] 
    });
    
    return role_panel; 
})
