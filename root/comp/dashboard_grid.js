<%perl>
    use Baseliner::Utils;
    my $id = _nowstamp;
</%perl>
(function(){
    var store = new Baseliner.JsonStore({
	    root: 'data' , 
	    remoteSort: true,
	    totalProperty:"totalCount", 
	    id: 'id', 
	    url: '/dashboard/list_dashboard',
	    fields: [
		    {  name: 'id' },
		    {  name: 'name' },
		    {  name: 'description' },
		    {  name: 'dashlets' },
		    {  name: 'roles' },
		    {  name: 'is_main' },
		    {  name: 'type' },
		    {  name: 'is_system' }
	    ]
    });
    
    var store_config = new Baseliner.JsonStore({
	    root: 'data' , 
	    remoteSort: true,
	    totalProperty:"totalCount", 
	    id: 'id', 
	    url: '/dashboard/get_config',
	    fields: [
		    {  name: 'id' },
		    {  name: 'name' },
		    {  name: 'description' },
		    {  name: 'value' },
		    {  name: 'dashlet' }
	    ]
    });	
    
    var ps = 100; //page_size
    store.load({params:{start:0 , limit: ps}});
    
    <& /comp/search_field.mas &>
    
    var init_buttons = function(action) {
	    eval('btn_edit.' + action + '()');
	    eval('btn_delete.' + action + '()');
    }
    
    Baseliner.store.Dashlets = function(c) {
	     Baseliner.store.Dashlets.superclass.constructor.call(this, Ext.apply({
		    root: 'data' , 
		    remoteSort: true,
		    autoLoad: true,
		    totalProperty:"totalCount", 
		    baseParams: {},
		    id: 'id', 
		    url: '/dashboard/list_dashlets',
		    fields: ['id','name','description', 'config'] 
	     }, c));
    };
    Ext.extend( Baseliner.store.Dashlets, Baseliner.JsonStore );
    
    Baseliner.store.Roles = function(c) {
	     Baseliner.store.Roles.superclass.constructor.call(this, Ext.apply({
		    url: '/role/json',
		    fields: ['id','role','description'] 
	     }, c));
    };	

    Ext.extend( Baseliner.store.Roles, Baseliner.store.Dashlets );

    Baseliner.model.Dashlets = function(c) {
        var tpl_list = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item">',
            '<span id="boot" style="width:200px"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: #800080">{[_(values.name)]} - {[_(values.description)]}</span></span>',
            '</div></tpl>' );
        var tpl_field = new Ext.XTemplate( '<tpl for=".">',
            '<span id="boot"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: #800080">{[_(values.name)]}</span></span>',
            '</tpl>' );
	    
	    Baseliner.model.Dashlets.superclass.constructor.call(this, Ext.apply({
		    allowBlank: false,
		    msgTarget: 'under',
		    allowAddNewData: true,
		    addNewDataOnBlur: false, 
		    //emptyText: _('Enter or select topics'),
		    triggerAction: 'all',
		    resizable: true,
		    mode: 'local',
		    fieldLabel: _('Dashlets'),
		    typeAhead: true,
		    name: 'dashlets',
		    displayField: 'name',
		    hiddenName: 'dashlets',
		    valueField: 'id',
		    tpl: tpl_list,
		    displayFieldTpl: tpl_field,
		    value: '/',
		    extraItemCls: 'x-tag'
	    }, c));
    };
    Ext.extend( Baseliner.model.Dashlets, Ext.ux.form.SuperBoxSelect );
    
    Baseliner.model.Roles = function(c) {
	    var color = 'FFFF00';
        var tpl_list = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item">',
            '<span id="boot" style="width:200px"><span class="badge" style="float:left;padding:2px 8px 2px 8px;color: #FFFFFF;background: #0000ff">{role}{[values.description ? " - " + values.description:"" ]} </span> </span>',
            '&nbsp;&nbsp;<b>{title}</b></div></tpl>' );
        var tpl_field = new Ext.XTemplate( '<tpl for=".">',
            '<span id="boot"><span class="badge" style="float:left;padding:2px 8px 2px 8px;color: #FFFFFF;background: #0000ff">{role}</span></span>',
            '</tpl>' );
	    
	    Baseliner.model.Roles.superclass.constructor.call(this, Ext.apply({
		    fieldLabel: _('Roles'),
		    name: 'roles',
		    displayField: 'role',
		    hiddenName: 'roles',
		    valueField: 'id',
		    tpl: tpl_list,
		    displayFieldTpl: tpl_field
	    }, c));
    };
    Ext.extend( Baseliner.model.Roles, Baseliner.model.Dashlets );

    var dashlets_box_store = new Baseliner.store.Dashlets();
    var roles_box_store = new Baseliner.store.Roles();



    var add_edit = function(rec) {
	    var win;
	    var config = new Array();
		var show = rec ? rec.data.is_system : false;
	    
		    var dashlets_box = new Baseliner.model.Dashlets({
			    store: dashlets_box_store,
			    hidden: show //********************************************************************************* 
		    });
		    
		    dashlets_box_store.on('load',function(){
			    dashlets_box.setValue( rec.data.dashlets ) ;            
		    });
		    
		    dashlets_box.on('additem',function( obj, value, row){
			    if(row.data.config){
				    config.push({"text": _(row.data.name) + ' (' + _(row.data.description) + ')', "leaf": true, "config": row.data.config, "id": row.data.id, "dashboard_id": rec.data.id });	
			    }
		    });		
		    
		    var roles_box = new Baseliner.model.Roles({
			    store: roles_box_store,
			    hidden: show  //*******************************************************************
		    });
		    
		    roles_box_store.on('load',function(){
			    roles_box.setValue( rec.data.roles ) ;            
		    });  		
    
		    var btn_cerrar = new Ext.Toolbar.Button({
			    text: _('Close'),
			    width: 50,
			    handler: function() {
				    win.close();
				    store.load();
				    grid.getSelectionModel().clearSelections();
			    }
		    })
		    
		    var btn_grabar_dashboard = 	new Ext.Toolbar.Button({
			    text: _('Save'),
			    width: 50,
			    hidden: show, //**************************************************************
			    handler: function(){
				    var form = form_dashboard.getForm();

				    if(form.getValues()['id'] == -1){
				    	action = 'add';
				    }else{
				    	action = 'update';
				    }
				    if (form.isValid()) {
					    form.submit({
						    params: { action: action },
						    success: function(f,a){
							    Baseliner.message(_('Success'), a.result.msg );
							    form.findField("id").setValue(a.result.dashboard_id);
							    win.setTitle(_('Edit dashboard'));							
							    
							    
						    },
						    failure: function(f,a){
						    Ext.Msg.show({  
							    title: _('Information'), 
							    msg: a.result.msg , 
							    buttons: Ext.Msg.OK, 
							    icon: Ext.Msg.INFO
						    }); 						
						    }
					    });
				    }
			    }
		    })
		    
		    var dashboard_main_check = new Ext.form.Checkbox({
			    name: 'dashboard_main_check',
			    boxLabel: _('Main dashboard')
		    });		
    
		    var ta = new Ext.form.TextArea({
			    name: 'description',
			    height: 130,
			    enableKeyEvents: true,
			    fieldLabel: _('Description'),
			    emptyText: _('A brief description of the dashboard')
		    });
		    
		    var btn_config_dashlets = new Ext.Toolbar.Button({
			    text: _('Parameters'),
			    icon:'/static/images/icons/cog_edit.png',
			    cls: 'x-btn-text-icon',
			    handler: function() {
				    store_config.removeAll();
				    
				    var treeRoot = new Ext.tree.AsyncTreeNode({
					    text: _('Configuration'),
					    expanded: true,
					    draggable: false,
					    children: config
				    });
				    
		    
				    var tree_dashlets = new Ext.tree.TreePanel({
					    title: _('Configuration Dashlets'),
					    split: true,
					    colapsible: true,
					    useArrows: true,
					    animate: true,
					    containerScroll: true,
					    autoScroll: true,
					    height:300,		    
					    rootVisible: true,
					    root: treeRoot
				    });
				    
				    tree_dashlets.on('click', function(node, checked) {
					    store_config.load({params: {config: node.attributes.config, id: node.attributes.id, dashboard_id: node.attributes.dashboard_id, system: rec.data.is_system }});
				    });				
			    
				    var blank_image = new Ext.BoxComponent({autoEl: {tag: 'img', src: Ext.BLANK_IMAGE_URL}, height:10});
				    
				    var edit_config = function(rec) {
					    var win_config;
    
					    var btn_cerrar_config = new Ext.Toolbar.Button({
						    text: _('Close'),
						    width: 50,
						    handler: function() {
							    win_config.close();
						    }
					    })
					    
					    var btn_grabar_config = new Ext.Toolbar.Button({
						    text: _('Save'),
						    width: 50,
						    handler: function(){
							    var form = form_config.getForm();
							    
							    var ff_dashboard = form_dashboard.getForm();
							    var dashboard_id = ff_dashboard.findField("id").getValue();
							    
							    if (form.isValid()) {
								    form.submit({
									    params: { id_dashboard: dashboard_id, id: rec.data.id, dashlet: rec.data.dashlet },
									    success: function(f,a){
										    Baseliner.message(_('Success'), a.result.msg );
										    store_config.reload();
									    },
									    failure: function(f,a){
									    Ext.Msg.show({  
										    title: _('Information'), 
										    msg: a.result.msg , 
										    buttons: Ext.Msg.OK, 
										    icon: Ext.Msg.INFO
									    }); 						
									    }
								    });
							    }
						    }
					    })					
					    
					    var form_config = new Ext.FormPanel({
						    name: form_dashlets,
						    url: '/dashboard/set_config',
						    frame: true,
						    buttons: [btn_grabar_config, btn_cerrar_config],
						    defaults:{anchor:'100%'},
						    items   : [
									    { fieldLabel: _(rec.data.id), name: 'value', xtype: 'textfield', allowBlank:false}
								    ]
					    });
    
					    if(rec){
						    var ff = form_config.getForm();
						    ff.loadRecord( rec );
						    title = 'Edit configuration';
					    }
    
					    win_config = new Ext.Window({
						    title: _(title),
						    autoHeight: true,
						    width: 400,
						    closeAction: 'close',
						    modal: true,
						    items: [
							    form_config
						    ]
					    });
					    win_config.show();
					    
				    }
				    
				    var grid_config = new Ext.grid.GridPanel({
					    title: _('Configuration'),
					    store: store_config,
					    stripeRows: true,
					    autoScroll: true,
					    autoWidth: true,
					    viewConfig: {
						    forceFit: true
					    },		    
					    height:300,
					    columns: [
						    { header: _('Description'), dataIndex: 'description', width: 100},
						    { header: _('Value'), dataIndex: 'value', width: 80}
					    ],
					    autoSizeColumns: true
				    });
				    
				    grid_config.on("rowdblclick", function(grid, rowIndex, e ) {
					    var sel = grid.getStore().getAt(rowIndex);
					    edit_config(sel);
				    });				
		    
				    var form_dashlets = new Ext.FormPanel({
					    name: form_dashlets,
					    frame: true,
					    items   : [
							       {
								    xtype: 'panel',
								    layout: 'column',
								    items:  [
									    {  
									    columnWidth: .49,
									    items:  tree_dashlets
									    },
									    {
									    columnWidth: .02,
									    items: blank_image
									    },
									    {  
									    columnWidth: .49,
									    items: grid_config
								    }]  
								    }
							    ]
				    });
				    
				    var winYaml = new Ext.Window({
					    modal: true,
					    width: 800,
					    title: _('Parameters'),
					    tbar: [
							    {   xtype:'button',
								    text: _('Close'),
								    iconCls:'x-btn-text-icon',
								    icon:'/static/images/icons/leave.png',
								    handler: function(){
									    winYaml.close();
								    }
							    }           
					    ],
					    items: form_dashlets
				    });
				    winYaml.show();
			    }
		    });

		    var form_dashboard = new Ext.FormPanel({
			    name: form_dashboard,
			    url: '/dashboard/update',
			    frame: true,
			    buttons: [btn_config_dashlets, btn_grabar_dashboard, btn_cerrar],
			    defaults:{anchor:'100%'},
			    items   : [
						    { xtype: 'hidden', name: 'id', value: -1 },
						    {fieldLabel: _('Name'), name: 'name', emptyText: 'name', xtype: 'textfield', allowBlank:false},
						    ta,
						    {
						    // column layout with 2 columns
						    layout:'column',
						    hidden: show  //*******************************************************
						    ,defaults:{
							    columnWidth:0.5
							    ,layout:'form'
							    ,border:false
							    ,xtype:'panel'
						    }
						    ,items:[{
							    // left column
							    defaults:{anchor:'100%'}
							    ,items: [ dashboard_main_check ]
							    },
							    {
							    // right column
							    defaults:{anchor:'100%'}
							    ,items:[
									    {
										    xtype: 'radiogroup',
										    id: 'columnsgroup',
										    defaults: {xtype: "radio",name: "type"},
										    items: [
											    {boxLabel: _('One column'), inputValue: 'O'},
											    {boxLabel: _('Two columns'), inputValue: 'T', checked: true}
										    ]
									    }
								    ]
							    }
						    ]
						    },						
						    roles_box,
						    dashlets_box
					    ]
		    });
		    
		    var title = 'Create dashboard';
		    
		    if(rec){
			    var ff = form_dashboard.getForm();
			    ff.loadRecord( rec );
			    dashboard_main_check.setValue( rec.data.is_main );
			    //alert(rec.data.is_main);
			    title = 'Edit dashboard';
		    }
	    
		    win = new Ext.Window({
			    title: _(title),
			    autoHeight: true,
			    width: 730,
			    closeAction: 'close',
			    modal: true,
			    items: [
				    form_dashboard
			    ]
		    });
		    win.show();
    };
    
 
//    var btn_add = new Ext.Toolbar.Button({
//	    text: _('New'),
//	    icon:'/static/images/icons/add.gif',
//	    cls: 'x-btn-text-icon',
//        handler: function() {
//		    add_edit();
//	    }
//    });
	
    var btn_add = new Baseliner.Grid.Buttons.Add({    
        handler: function() {
            add_edit()
        }
    });	

    var btn_edit = new Ext.Toolbar.Button({
        text: _('Edit'),
        icon:'/static/images/icons/edit.gif',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
        var sm = grid.getSelectionModel();
            if (sm.hasSelection()) {
                var sel = sm.getSelected();
                add_edit(sel);
            } else {
                Baseliner.message( _('ERROR'), _('Select at least one row'));    
            };
        }
    });
    
    var btn_delete = new Ext.Toolbar.Button({
        text: _('Delete'),
        icon:'/static/images/icons/delete.gif',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
            var sm = grid.getSelectionModel();
            var sel = sm.getSelected();
            Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the dashboard') + ' <b>' + sel.data.name + '</b>?', 
            function(btn){ 
                if(btn=='yes') {
                    Baseliner.ajaxEval( '/dashboard/update?action=delete',
                        { id: sel.data.id },
                        function(response) {
                            if ( response.success ) {
                                grid.getStore().remove(sel);
                                Baseliner.message( _('Success'), response.msg );
                                init_buttons('disable');
                            } else {
                                Baseliner.message( _('ERROR'), response.msg );
                            }
                        }
                    
                    );
                }
            } );
        }
    });
    
    var render_system = function(value,metadata,rec,rowIndex,colIndex,store) {
        if(rec.data.is_system){
		    str = '<span style="color: #808080">' + value + '</span>';
	    }else{
		    str = value;
	    }
	    return str;
    }
    
    // create the grid
    var grid = new Ext.grid.GridPanel({
		    title: _('Dashboards'),
		    header: false,
		    stripeRows: true,
		    autoScroll: true,
            tab_icon: '/static/images/icons/dashboard.png',
		    autoWidth: true,
		    store: store,
		    viewConfig: {
			    forceFit: true
		    },
		    selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		    loadMask:'true',
		    columns: [
			    { header: _('Id'), hidden: true, dataIndex: 'id' },
			    { header: _('Dashboard'), width: 120, dataIndex: 'name', sortable: true, renderer: render_system},
			    { header: _('Description'), width: 350, dataIndex: 'description', sortable: true, renderer: render_system }
		    ],
		    autoSizeColumns: true,
		    deferredRender:true,
		    bbar: new Ext.PagingToolbar({
				    store: store,
				    pageSize: ps,
				    displayInfo: true,
				    displayMsg: _('Rows {0} - {1} of {2}'),
				    emptyMsg: _('There are no rows available')
		    }),        
		    tbar: [ _('Search') + ': ', ' ',
			    new Baseliner.SearchField({
				    store: store,
				    params: {start: 0, limit: ps}
			    }),
			    btn_add,
			    btn_edit,
			    btn_delete
		    ]
    });

    grid.on('rowclick', function(grid, rowIndex, columnIndex, e) {
        init_buttons('enable');
    });
		    
    return grid;
})
