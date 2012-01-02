(function(){

	var ps = 100;
	
	<& /comp/search_field.mas &>
	
	var record = Ext.data.Record.create([
		{name: 'name'},
		{name: 'description'},
		{name: 'parent'},		
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
		),
		listeners: {
			'load': function(){
				init_buttons('disable');
			}
		}
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

	var init_buttons = function(action) {
		eval('btn_edit.' + action + '()');
		eval('btn_delete.' + action + '()');
	}
	

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
							{ _id: sel.data._id,
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

	
	var add_edit = function(rec) {
		var win;
		
		var blank_image = new Ext.BoxComponent({autoEl: {tag: 'img', src: Ext.BLANK_IMAGE_URL}, widht:10});
		
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
		    title: _("List of projects"),
		    dataUrl: "project/list",
		    split: true,
		    colapsible: true,
		    useArrows: true,
		    animate: true,
		    containerScroll: true,
		    autoScroll: true,
		    height:310,		    
		    rootVisible: false,
		    root: treeRoot
		});
		
		tree_projects.getLoader().on("beforeload", function(treeLoader, node) {
			var loader = tree_projects.getLoader();
			loader.baseParams = node.attributes.data;
		});
		
		tree_projects.on('click', function(node, event){
			var ff = form_proyecto.getForm();
			ff.findField('parent').setValue(node.attributes.data.project);
			ff.findField('id_parent').setValue(node.attributes.data.id_project);
		});

		var btn_cerrar = new Ext.Toolbar.Button({
			icon:'/static/images/icons/door_out.png',
			cls: 'x-btn-text-icon',
			text: _('Close'),
			handler: function() {
				win.close();
				store_proyectos.active_node = null;
				store_proyectos.reload({add:null , params:{add:null, query:null}});			
				grid_proyectos.getSelectionModel().clearSelections();
			}
		})
		
		var btn_grabar_proyecto = new Ext.Toolbar.Button({
			icon:'/static/images/icons/database_save.png',
			cls: 'x-btn-text-icon',
			text: _('Save'),
			handler: function(){
				var form = form_proyecto.getForm();
				alert(form.getValues()['_id']);
				var action = form.getValues()['_id'] >= 0 ? 'update' : 'add';

				if (form.isValid()) {
				       form.submit({
					   params: {action: action},
					   success: function(f,a){
					       Baseliner.message(_('Success'), a.result.msg );
					       form.findField("_id").setValue(a.result.project_id);
					       //btn_grabar_proyecto.disable();
					       win.setTitle(_('Edit proyecto'));
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


		var column1 = {
			xtype:'panel',
			flex: 2,
			layout:'form',
			defaults:{anchor:'100%'},
			items:[
				{ xtype: 'hidden', name: '_id', value: -1 },
				{ xtype:'textfield', name:'name', fieldLabel:_('Name'), allowBlank:false, emptyText:_('Project name') },
				{ xtype:'textfield', name:'parent', readOnly: true, fieldLabel:_('Parent'), allowBlank:false, emptyText:_('Select a parent from the list of projects')},
				{ xtype: 'hidden', name: 'id_parent', value: '' },
				{ xtype:'textfield', name:'nature', fieldLabel:_('Naturaleza'), emptyText:_('Nature of the project (Examples: J2EE, .NET)') },
				{ xtype:'textarea', name:'description', fieldLabel:_('Description'), emptyText:_('A brief description of the project'), height:230 }
			]
		};

		var column2 = {
			xtype:'panel',
			flex: 1,
			items: tree_projects
		};

		//Para cuando se envia el formulario no coja el atributo emptytext de los textfields
		Ext.form.Action.prototype.constructor = Ext.form.Action.prototype.constructor.createSequence(function() {
		    Ext.applyIf(this.options, {
			submitEmptyText:false
		    });
		});

		var form_proyecto = new Ext.FormPanel({
					url: '/project/update',
					frame: true,
					layout: {
						type: 'hbox',
						padding: '5'
					},
					bbar: [
						btn_grabar_proyecto,
						btn_cerrar
					]				    
					,
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
			var ff = form_proyecto.getForm();
			ff.loadRecord( rec );
			title = 'Edit project';
		}


		win = new Ext.Window({
			title: _(title),
			width: 750,
			autoHeight: true,
			items: form_proyecto,
			closeAction:'destroy'
		});
		win.show();		
	};

	
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
		  { id:'name',header: _('Project'), width: 150, sortable: true, dataIndex: 'name' },
		  { header: _('Id'), hidden: true, dataIndex: '_id' },
		  { header: _('Description'), width: 400, dataIndex: 'description' },
		  { header: _('Nature'), width: 75, dataIndex: 'nature' }
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

	grid_proyectos.on('rowclick', function(grid, rowIndex, columnIndex, e) {
		init_buttons('enable');
	});
		
	return grid_proyectos;
})
