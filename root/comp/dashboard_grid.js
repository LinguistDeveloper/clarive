<%perl>
    use Baseliner::Utils;
    my $id = _nowstamp;
</%perl>
(function(){
	var store = new Ext.data.JsonStore({
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
			{  name: 'roles' }
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
			fields: ['id','name','description'] 
		 }, c));
	};
	Ext.extend( Baseliner.store.Dashlets, Ext.data.JsonStore );
	
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
			addNewDataOnBlur: true, 
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
		
        var dashlets_box = new Baseliner.model.Dashlets({
            store: dashlets_box_store
        });
        dashlets_box_store.on('load',function(){
            dashlets_box.setValue( rec.dashlets ) ;            
        });
		
        var roles_box = new Baseliner.model.Roles({
            store: roles_box_store
        });
        roles_box_store.on('load',function(){
            roles_box.setValue( rec.roles ) ;            
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
			handler: function(){
				var form = form_dashboard.getForm();
				var action = form.getValues()['id'] >= 0 ? 'update' : 'add';
				
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

		var ta = new Ext.form.TextArea({
			name: 'description',
			height: 130,
			enableKeyEvents: true,
			fieldLabel: _('Description'),
			emptyText: _('A brief description of the dashboard')
		});
		
		var form_dashboard = new Ext.FormPanel({
			name: form_dashboard,
			url: '/dashboard/update',
			frame: true,
			buttons: [btn_grabar_dashboard, btn_cerrar],
			defaults:{anchor:'100%'},
			items   : [
						{ xtype: 'hidden', name: 'id', value: -1 },
						{fieldLabel: _('Name'), name: 'name', emptyText: 'name', xtype: 'textfield', allowBlank:false},
						ta,
						roles_box,
						dashlets_box

					]
		});
		
		var title = 'Create dashboard';
		
		if(rec){
			var ff = form_dashboard.getForm();
			ff.loadRecord( rec );
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
	//	store_roles.load({params:{start:0 , limit: ps}});
	//	store_user_roles_projects.load({ params: {username: username} });		
		win.show();
	};
	
 
    var btn_add = new Ext.Toolbar.Button({
		text: _('New'),
		icon:'/static/images/icons/add.gif',
		cls: 'x-btn-text-icon',
        handler: function() {
			add_edit();
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
	

	// create the grid
	var grid = new Ext.grid.GridPanel({
			title: _('Dashboards'),
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
				{ header: _('Id'), hidden: true, dataIndex: 'id' },
				{ header: _('Dashboard'), width: 120, dataIndex: 'name', sortable: true},
				{ header: _('Description'), width: 350, dataIndex: 'description', sortable: true }
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
				new Ext.app.SearchField({
					store: store,
					params: {start: 0, limit: ps},
					emptyText: _('<Enter your search string>')
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