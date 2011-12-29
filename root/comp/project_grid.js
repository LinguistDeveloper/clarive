(function(){
	var add_edit = function(rec) {
		var win;
		
		var blank_image = new Ext.BoxComponent({autoEl: {tag: 'img', src: Ext.BLANK_IMAGE_URL}, widht:10});
		
		var treeRoot = new Ext.tree.AsyncTreeNode({
			text: _('All'),
			draggable: false,
			checked: false,
			id: 'All',
			data: {
				project: '',
				id_project: _('todos'),
				parent_checked: ''
			}
		});
		
		
		var tree_projects = new Ext.tree.TreePanel({  
		    title: _("Select a parent"),
		    dataUrl: "user/projects_list",
		    split: true,
		    colapsible: true,
		    useArrows: true,
		    animate: true,
		    containerScroll: true,
		    autoScroll: true,
		    height:300,		    
		    rootVisible: false,
		    preloadChildren: true,
		    root: treeRoot
		});
		
		tree_projects.getLoader().on("beforeload", function(treeLoader, node) {
			var loader = tree_projects.getLoader();
			loader.baseParams = node.attributes.data;
			//node.attributes.data.parent_checked = (node.attributes.checked)?1:0;
		});
		
		tree_projects.on('click', function(node, event){
			var ff = form_project.getForm();
			ff.findField('parent').setValue(node.attributes.data.project);
			ff.findField('id').setValue(node.attributes.data.id_project);
		});

		var column1 = {
			xtype:'panel',
			flex: 2,
			layout:'form',
			defaults:{anchor:'100%'},
			items:[
				{ xtype: 'hidden', name: 'id', value: -1 },
				{ xtype:'textfield', name:'name', fieldLabel:_('Name') },
				{ xtype:'textfield', name:'parent', readOnly: true, fieldLabel:_('Parent') },
				{ xtype:'textfield', name:'nature', fieldLabel:_('Naturaleza') },
				{ xtype:'textarea', name:'description', fieldLabel:_('Description'), height:230 }
			]
		};

		var column2 = {
			xtype:'panel',
			flex: 1,
			items: tree_projects
		};

		var form_project = new Ext.FormPanel({
				    frame: true,
                                    layout: {
                                        type: 'hbox',
                                        padding: '5'
                                    },
                                    defaults:{
                                        margins: '0 5 0 0'
                                    },
                                    items:[
					column1,
					column2
				    ]
		});		

		var title = 'Create new project';
		
		if(rec){
			var ff = form_project.getForm();
			ff.loadRecord( rec );
			title = 'Edit project';
		}


		win = new Ext.Window({
			title: _(title),
			width: 750,
			autoHeight: true,
			items: form_project,
			closeAction:'destroy',
			buttons: [
				{
				text: _('Submit'),
				handler: function(){ 
						form_project.getForm().submit({
						    success: function(f,a){
							Baseliner.message( _('New Project'), _(a.result.msg) );
							store.load();
							win.close();
						    },
						    failure: function(f,a){
							Ext.Msg.alert(_('Error'), a.result.msg );
						    }
						});
					}
				},
				{
				text: _('Close'),
				handler: function(){ win.close() }
				}
			]
		});
		win.show();		
	};
	

	//tree_projects1.on('checkchange', function(node, checked) {
	//	if(node != treeRoot1){
	//		if (node.attributes.checked == false){
	//			 treeRoot1.attributes.checked = false;
	//			 treeRoot1.getUI().checkbox.checked = false;
	//		}
	//	}
	//	node.eachChild(function(n) {
	//		n.getUI().toggleCheck(checked);
	//	});
	//	
	//	control_buttons();		
	//});
	

	<& /comp/search_field.mas &>

        var btn_add = new Ext.Toolbar.Button({
                text: _('New'),
                icon:'/static/images/icons/add.gif',
                cls: 'x-btn-text-icon',
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
			var sm = grid_proyectos.getSelectionModel();
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
				var sm = grid_proyectos.getSelectionModel();
				var sel = sm.getSelected();
				Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the project') + ' <b>' + sel.data.name + '</b>?', 
				function(btn){ 
					if(btn=='yes') {
						Baseliner.ajaxEval( '/project/update?action=delete',
							{ id: sel.data._id,
							  project: sel.data.name
							},
							function(response) {
								if ( response.success ) {
									grid_proyectos.getStore().remove(sel);
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

	var record = Ext.data.Record.create([
		{name: 'name'},
		{name: 'description'},
		{name: 'nature'},
		{name: '_id', type: 'int'},
		{name: '_level', type: 'int'},
		{name: '_num_fila', type: 'int'},
		{name: '_lft', type: 'int'},
		{name: '_rgt', type: 'int'},
		{name: '_is_leaf', type: 'bool'}
	]);	

	var store_proyectos = new Ext.ux.maximgb.tg.NestedSetStore({
		url: 'project/list',
		reader: new Ext.data.JsonReader(
			{
			id: '_id',
			root: 'data',
			totalProperty: 'total',
			successProperty: 'success'
			}, 
			record
		)
	});
	
	var ps = 100;
	
	// create the Grid
	var grid_proyectos = new Ext.ux.maximgb.tg.GridPanel({
		title: _('Projects'),
		header: false,
		stripeRows: true,
		autoScroll: true,
		autoWidth: true,
		store: store_proyectos,
		viewConfig: {
			forceFit: true
		},
		master_column_id : 'name',
		autoExpandColumn: 'name',
		columns: [
		  {id:'name',header: _('Project'), width: 150, sortable: true, dataIndex: 'name'},
		  {header: _('Description'), width: 400, dataIndex: 'description'},
		  {header: _('Nature'), width: 75, dataIndex: 'nature'}
		],
		bbar: new Ext.ux.maximgb.tg.PagingToolbar({
			store: store_proyectos,
			displayInfo: true,
			pageSize: ps
		}),        
		tbar: [ _('Search') + ': ', ' ',
			new Ext.app.SearchField({
				store: store_proyectos,
				params: {start: 0, limit: ps, treegrid:true},
				emptyText: _('<Enter your search string>')
			}),
			btn_add,
			btn_edit,
			btn_delete,
			'->'
		]
	});

	var init_buttons = function(action) {
		eval('btn_edit.' + action + '()');
		eval('btn_delete.' + action + '()');
	}
	
	grid_proyectos.on('rowclick', function(grid, rowIndex, columnIndex, e) {
		init_buttons('enable');
	});
		
	store_proyectos.on('beforeexpandnode', function(obj, record) {
		var row = store_proyectos.getAt(store_proyectos.indexOf(record));
		var hijos_node = row.get('_rgt') - 1;
		var lft_padre = row.get('_lft');
		var num_fila = row.get('_num_fila');
		store_proyectos.baseParams = {
			lft_padre: lft_padre,
			num_fila: num_fila,
			hijos_node: hijos_node
		};		
	});
	
	store_proyectos.load({params:{start:0 , limit: ps}});			
	return grid_proyectos;
})
