(function(){
    var ps = 50; //page_size
    
    var store = new Ext.data.JsonStore({
        root: 'data' , 
	remoteSort: true,
        totalProperty: 'totalCount',
	id: 'rownum', 
	url: '/chain/list',
	fields: [
                { name: 'id' },
                { name: 'name' },
                { name: 'description' },
                { name: 'job_type' },
                { name: 'active' }
                //{ name: 'ns' },
                //{ name: 'action' },
                //{ name: 'bl'}
		],
		listeners: {
			'load': function(){
				init_buttons('disable');
				}
			}		
    });
    
    var store_services = new Ext.data.JsonStore({
        root: 'data' , 
	remoteSort: true,
        totalProperty: 'totalCount',
	id: 'rownum', 
	url: '/chain/list_services',
	fields: [
		{ name: 'id' },
                { name: 'key' },
                { name: 'description' },
                { name: 'step' },
                { name: 'active' },
		{ name: 'data' }		
		]
    });

    <& /comp/search_field.mas &>
    
    var render_name = function(value, metadata, rec, rowIndex, colIndex, store) {
        return "<div style='font-weight:bold; font-size: 16px;'>" + value + "</div>" ;
    };
    
    var render_plugin = function(value, metadata, rec, rowIndex, colIndex, store) {
	return "<img alt='" + value + "' border=0 style='vertical-align: top; margin: 0 0 10 2;' src='/static/images/icons/chain.jpg' />" ;
    };
    
    var render_active = function(value,metadata,rec,rowIndex,colIndex,store) {
	var img =
		value == '1' ? 'drop-yes.gif' : 'close-small.gif';
		return "<img alt='"+value+"' border=0 style='vertical-align: top; margin: 0 0 10 2;' src='/static/images/"+img+"' />" ;
    };
    
    store.load({ params: {start: 0, limit: ps}});

    var init_buttons = function(action) {
	eval('btn_start.' + action + '()');
	eval('btn_stop.' + action + '()');
	eval('btn_edit.' + action + '()');
	eval('btn_delete.' + action + '()');
    };

    var btn_start = new Ext.Toolbar.Button({
	text: _('Start'),
	icon:'/static/images/start.gif',
	disabled: true,
	cls: 'x-btn-text-icon',
	handler: function() {
		var sm = grid.getSelectionModel();
		if (sm.hasSelection()) {
			var rec = sm.getSelected();
			var id = rec.data.id;
			Baseliner.ajaxEval( '/chain/change_active', { id: id, action: 'start' },
				function(resp){
					Baseliner.message( _('Success'), resp.msg );
					store.load();
				}
			);
		} else {
			Baseliner.message( _('ERROR'), _('Select at least one row'));	
		};
	}
    });

    var btn_stop = new Ext.Toolbar.Button({
	text: _('Stop'),
	icon:'/static/images/stop.gif',
	disabled: true,
	cls: 'x-btn-text-icon',
	handler: function() {
		var sm = grid.getSelectionModel();
		var sel = sm.getSelected();
		Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to turn off the chain') + ' <b>' + sel.data.name  + '</b>?', 
			function(btn){ 
				if(btn=='yes') {
					Baseliner.ajaxEval( '/chain/change_active', { id: sel.data.id, action: 'stop' },
						function(resp){
							Baseliner.message( _('Success'), resp.msg );
							store.load();
						}
					);
				}
			}
		);
	}
    });    
    
    var btn_add = new Ext.Toolbar.Button({
	text: _('New'),
	icon:'/static/images/icons/add.gif',
	cls: 'x-btn-text-icon',
	handler: function() {
		add_edit()
	}
    });
    
    var add_edit = function(rec) {
	store_services.removeAll();
	var win;
	
	var combo_job_type = new Ext.form.ComboBox({
		mode: 'local',
		value: 'promote',
		triggerAction: 'all',
		forceSelection: true,
		editable: false,
		fieldLabel: _('Job Type'),
		name: 'job_type',
		hiddenName: 'job_type',
		displayField: 'name',
		valueField: 'value',
		//Tipos de pase
		store: new Ext.data.JsonStore({
			    fields : ['name', 'value'],
			    data   : [{name : 'promote',   value: 'promote'},
				      {name : 'demote',   value: 'demote'}]
			})
	});

	var title = 'Create chain';
	
	//Para cuando se envia el formulario no coja el atributo emptytext de los textfields
	Ext.form.Action.prototype.constructor = Ext.form.Action.prototype.constructor.createSequence(function() {
	    Ext.applyIf(this.options, {
		submitEmptyText:false
	    });
	});

	var form_chain = new Ext.FormPanel({
		frame: true,
		url:'/chain/update',
		buttons: [
			{
			text: _('Save'),
			type: 'submit',
			handler: function() {
				var form = form_chain.getForm();
				var action = form.getValues()['id'] >= 0 ? 'update' : 'add';
				if (form.isValid()) {
				       form.submit({
					   params: {action: action},
					   success: function(f,a){
					       Baseliner.message(_('Success'), a.result.msg );
					       form.findField("id").setValue(a.result.chain_id);
					       store.load();
					       win.setTitle(_('Edit chain'));
					       form_services.enable();
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
			},
			{
			text: _('Close'),
			handler: function(){ 
					win.close();
				}
			}
		],
		defaults: { width: 400 },
		items: [
			{ name: 'id', xtype: 'hidden', value: -1 },
			{ fieldLabel: _('Name'), name: 'name', xtype: 'field', allowBlank:false },
			{ fieldLabel: _('Description'), name: 'description', xtype: 'textarea' },
			{
			xtype: 'radiogroup',
			id: 'stategroup',
			fieldLabel: _('State'),
			defaults: {xtype: "radio",name: "state"},
			items: [
				{boxLabel: _('Active'), inputValue: 1},
				{boxLabel: _('Not Active'), inputValue: 0, checked: true}
			]
			},
			combo_job_type
		]
	});

	var treeRoot = new Ext.tree.AsyncTreeNode({
		text: _('All'),
		draggable: false,
		checked: false,
		data: {
			project: '',
			id_project: _('todos'),
			sw_crear_editar: true
		}
	});
	
	var tree_projects = new Ext.tree.TreePanel({  
	    //title: _("List of projects"),
	    dataUrl: "project/list",
	    split: true,
	    colapsible: true,
	    useArrows: true,
	    animate: true,
	    containerScroll: true,
	    autoScroll: true,
	    height:100,		    
	    rootVisible: false,
	    root: treeRoot
	});
	
	var txtconfig;
	
	var btn_config_service = new Ext.Toolbar.Button({
	    icon:'/static/images/icons/cog_edit.png',
	    cls: 'x-btn-text-icon',
	    disabled: true,
	    handler: function() {
    
		var ta = new Ext.form.TextArea({
		    height: 500,
		    width: 600,
		    style: { 'font-family': 'Consolas, Courier, monotype' },
		    value: txtconfig
		});
		var winYaml = new Ext.Window({
		    title: _("YAML"),
		    tbar: [ 
			{ xtype:'button', text: _('Save'), iconCls:'x-btn-text-icon', icon:'/static/images/icons/write.gif',
			    handler: function(){
				winYaml.hide();
			    }
			}
		    ],
		    items: ta
		});
		winYaml.show();
	    }
	});
    
	var schedule_service = Baseliner.combo_services({ hiddenName: 'service' });
	
	schedule_service.on('select', function(field, newValue, oldValue) {
	    Baseliner.ajaxEval( '/chain/getconfig', {id: newValue.data.id}, function(res) {
		if( !res.success ) {
		    //Baseliner.error( _('YAML'), res.msg );
		} else {
		    // saved ok
		    //Baseliner.message( _('YAML'), res.msg );
		    if(res.yaml){
			txtconfig = res.yaml;
			btn_config_service.enable();
		    }
		    else{
			btn_config_service.disable();
		    }
		    
		}
	    });
	});	
	
	var combo_steps = new Ext.form.ComboBox({
		mode: 'local',
		value: 'CHECK',
		triggerAction: 'all',
		forceSelection: true,
		editable: false,
		fieldLabel: _('Step'),
		name: 'step',
		hiddenName: 'step',
		displayField: 'name',
		valueField: 'value',
		//Tipos de pase
		store: new Ext.data.JsonStore({
			    fields : ['name', 'value'],
			    data   : [{name : 'CHECK',   value: 'CHECK'},
				      {name : 'INIT',   value: 'INIT'},
				      {name : 'PRE',   value: 'PRE'},
				      {name : 'RUN',   value: 'RUN'},
				      {name : 'POST',   value: 'POST'},
				      {name : 'END',   value: 'END'}]
			})
	});

	var menu_mode_change = function(item,checked) {
		if( checked ) {
		    menu_mode.setText(item.text);
		    if(item.value == 'crear'){
			grid_services.disable();
			var form = form_services.getForm();
			schedule_service.show();
			schedule_service.enable();
			btn_config_service.disable();
			form.reset();
		    }else{
			schedule_service.disable();
			grid_services.enable();
			grid_services.getSelectionModel().selectFirstRow();
			var sm = grid_services.getSelectionModel();
			var rec = sm.getSelected();			    
			var ff = form_services.getForm();
			if(rec){
			    ff.loadRecord( rec );
			    rec.data.data ? btn_config_service.enable(): btn_config_service.disable();
			    txtconfig = rec.data.data;
			    schedule_service.setValue(rec.data.key);
			    var rb_state = Ext.getCmp("stategroup_services");
			    rb_state.setValue(rec.data.active);
			}
		    }
		    
		}
	};
	
	var menu_mode = new Ext.Toolbar.Button({ text : _('Modo crear'), menu: { items: [{text: _('Modo crear'), value: 'crear', checked:true, group: 'mode', checkHandler: menu_mode_change }, {text: _('Modo edicion'), value: 'editar', group: 'mode', checked:true, checkHandler: menu_mode_change }] }});	    
	
	var column1 = {
		xtype:'panel',
		flex: 2,
		layout:'form',
		defaults:{anchor:'100%'},
		items:[
			{ name: 'id', xtype: 'hidden', value: -1 },
			{ name: 'id_chain', xtype: 'hidden' },
					{
					// column layout with 2 columns
					layout:'column'
					,defaults:{
						//columnWidth:0.5
						layout:'form'
						,border:false
						,xtype:'panel'
						,bodyStyle:'padding:0 18px 0 0'
					}
					,items:[{
						// left column
						columnWidth:0.94,
						defaults:{anchor:'100%'}
						,items:[
							schedule_service
							]
						},
						{
						columnWidth:0.06,
						// right column
						//defaults:{anchor:'100%'}
						items:[
							btn_config_service
							]
						}
					]
					},
			//schedule_service, 
			//{ fieldLabel: _('Service'), name: 'key', xtype: 'textfield', readOnly: 'true', hidden: 'true'},
			{ xtype:'textarea', name:'description', fieldLabel:_('Description'), emptyText:_('A brief description of the service') },
			combo_steps,
			{
			xtype: 'radiogroup',
			id: 'stategroup_services',
			fieldLabel: _('State'),
			defaults: {xtype: "radio",name: "state"},
			items: [
				{boxLabel: _('Active'), inputValue: 1},
				{boxLabel: _('Not Active'), inputValue: 0, checked: true}
			]
			}			    
		]
	};

	var column2 = {
		xtype:'panel',
		flex: 1,
		items: tree_projects
	};
	    
	var btn_grabar_service = new Ext.Toolbar.Button({
		icon:'/static/images/icons/database_save.png',
		cls: 'x-btn-text-icon',
		text: _('Save'),
		handler: function(){
			var form = form_chain.getForm();
			var id_chain = form.getValues()['id'];
			if(id_chain != -1){
			    form = form_services.getForm();
			    var action = form.getValues()['id'] >= 0 ? 'update' : 'add';
			    form.findField("id_chain").setValue(id_chain);
			    if (form.isValid() || action == 'update') {
				   form.submit({
				       params: {action: action},
				       success: function(f,a){
					   if(action == 'add'){
						form.reset();
					   }
					   Baseliner.message(_('Success'), a.result.msg );
					   form.findField("id").setValue(a.result.service_id);						
					   store_services.load({ params: {start: 0, limit: ps, id_chain: id_chain}});
					   //btn_grabar_proyecto.disable();
					   //win.setTitle(_('Edit chain'));
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
			else{
			    Ext.Msg.show({ 	title: _('Information'), 
					    msg: _('You must save a chain first') , 
					    buttons: Ext.Msg.OK, 
					    icon: Ext.Msg.INFO
					}); 
			}
		}
	});
	    
	var form_services = new Ext.FormPanel({
				url: '/chain/update_service',
				frame: true,
				disabled: true,
				layout: {
					type: 'hbox',
					padding: '5'
				},
				defaults:{
				    //margins: '0 5 0 0'
				},
				items:[
				    column1,
				    column2
				],
				tbar: [
					menu_mode,
					btn_grabar_service
				]				    
	});
	    
	var grid_services = new Ext.grid.GridPanel({
		title: _('Chains'),
		header: false,
		stripeRows: true,
		autoScroll: true,
		autoWidth: true,
		disabled: true,		    
		store: store_services,
		height: 200,
		viewConfig: {
			forceFit: true
		},
		selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		loadMask:'true',
		columns: [
			{ dataIndex: 'id', hidden: true },
			{ header: _('Servicio'), width: 280, dataIndex: 'key', sortable: true },
			{ header: _('Description'), width: 300, dataIndex: 'description', sortable: true },
			{ header: _('Step'), width: 100, dataIndex: 'step', sortable: true },
			{ header: _('Active'), width: 100, dataIndex: 'active', sortable: true, renderer: render_active }
		],
		autoSizeColumns: true,
		deferredRender:true,
		bbar: new Ext.PagingToolbar({
			store: store_services,
			pageSize: ps,
			displayInfo: true,
			displayMsg: _('Rows {0} - {1} of {2}'),
			emptyMsg: _('No hay registros disponibles')
		})
	});

	grid_services.on('rowclick', function(grid, rowIndex, columnIndex, e) {
	    //init_buttons('enable');
	    var row = grid.getStore().getAt(rowIndex);
	    var ff = form_services.getForm();
	    row.data.data ? btn_config_service.enable(): btn_config_service.disable();
	    txtconfig = row.data.data;
	    
	    ff.loadRecord( row );
	    var rb_state = Ext.getCmp("stategroup_services");
	    rb_state.setValue(row.data.active);
	    
	});	    

	win = new Ext.Window({
		title: _(title),
		width: 650,
		autoHeight: true,
		modal: true,
		items: [ form_chain,
			 form_services,
			 grid_services ]
	});
	
	if(rec){
		var ff = form_chain.getForm();
		ff.loadRecord( rec );
		var id_chain = rec.data.id;
		var rb_state = Ext.getCmp("stategroup");
		rb_state.setValue(rec.data.active);
		store_services.load({ params: {start: 0, limit: ps, id_chain: id_chain}});

		form_services.enable();
		schedule_service.enable();
		grid_services.disable();
		
		title = 'Edit chain';
	}
	
	win.show();		
    };
    
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
		Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the chain') + ' <b>' + sel.data.name + '</b>?', 
		function(btn){ 
			if(btn=='yes') {
				Baseliner.ajaxEval( '/chain/update?action=delete',{ id: sel.data.id },
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

    //create the grid
    var grid = new Ext.grid.GridPanel({
	title: _('Chains'),
	header: false,
	stripeRows: true,
	autoScroll: true,
	autoWidth: true,
	store: store,
	viewConfig: {
		forceFit: true
	},
	selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
	loadMask:'true',
	columns: [
		{ width: 40, sortable: false, renderer: render_plugin },
		{ header: _('Chain'), width: 280, dataIndex: 'name', sortable: true, renderer: render_name },
		{ header: _('Description'), width: 300, dataIndex: 'description', sortable: true },
		{ header: _('Active'), width: 100, dataIndex: 'active', sortable: true, renderer: render_active },                    
		{ header: _('Job Type'), width: 100, dataIndex: 'job_type', sortable: true },
		{ header: _('Action'), width: 200, dataIndex: 'action', sortable: true },
		//{ header: _('Namespace'), width: 100, dataIndex: 'ns', sortable: true },
		//{ header: _('Baseline'), width: 200, dataIndex: 'bl', sortable: true }
	],
	autoSizeColumns: true,
	deferredRender:true,
	bbar: new Ext.PagingToolbar({
		store: store,
		pageSize: ps,
		displayInfo: true,
		displayMsg: _('Rows {0} - {1} of {2}'),
		emptyMsg: _('No hay registros disponibles')
	}),
	tbar: [ '<% _loc('Search') %>: ', ' ',
			new Ext.app.SearchField({
			store: store,
			params: {start: 0, limit: ps},
			emptyText: '<% _loc('<Enter your search string>') %>'
		}),
		btn_start,
		btn_stop,
		btn_add,
		btn_edit,
		btn_delete,
		'->'
	]
    });
    
    grid.on('rowclick', function(grid, rowIndex, columnIndex, e) {
	init_buttons('enable');
    });
    
    return grid;
    
})()