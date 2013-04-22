(function(params){
    var ps = 30;
	
	var fields = ['id', 'event_key', 'action','data', 'is_active', 'username',
				  'template_path', 'digest_time', 'digest_date', 'digest_freq'];
	
	
	var store_notifications = new Baseliner.JsonStore({
		autoLoad : true,
		root: 'data', 
		remoteSort: true,
		totalProperty:"totalCount", 
		id: 'id', 
		url: '/notification/list_notifications',
		fields: fields 
	});	
	
    var search_field = new Baseliner.SearchField({
        store: store_notifications,
        width: 280,
        params: {start: 0, limit: ps }
    });
	
    var ptool = new Ext.PagingToolbar({
		store: store_notifications,
		pageSize: ps,
		plugins:[
			new Ext.ux.PageSizePlugin({
				editable: false,
				width: 90,
				data: [
					['5', 5], ['10', 10], ['15', 15], ['20', 20], ['25', 25], ['50', 50],
					['100', 100], ['200',200], ['500', 500], ['1000', 1000], [_('all rows'), -1 ]
				],
				beforeText: _('Show'),
				afterText: _('rows/page'),
				value: ps,
				listeners: {
					'select':function(c,rec) {
						ps = rec.data.value;
						if( rec.data.value < 0 ) {
							ptool.afterTextItem.hide();
						} else {
							ptool.afterTextItem.show();
						}
					}
				},
				forceSelection: true
			})
		],
		displayInfo: true,
		displayMsg: _('Rows {0} - {1} of {2}'),
		emptyMsg: _('There are no rows available')
    });
	
	var store_actions = new Baseliner.JsonStore({
		url: '/notification/list_actions',
		fields: ['action','checked']   
	});
	
	store_actions.load();
	
	var actions = new Array();
	
	store_actions.on('load', function(ds, records, o){
		Ext.each(records, function (record){
			actions.push({boxLabel: _(record.data.action), name: 'action', inputValue: record.data.action, checked: record.data.checked })
		})
	});
		
    var add_edit = function(rec) {
        var win;
        
        var title = 'Create notification';
		
		var store_events = new Baseliner.JsonStore({
			url: '/notification/list_events',
			fields: ['key']   
		});
		
		store_events.on('load', function(ds, records, o){
			if(rec && rec.data){
				cb_events.setValue( rec.data.event_key );            
			}
		});		
		
		store_events.load();
		
		var cb_events = new Ext.ux.form.SuperBoxSelect({
			mode: 'local',
			triggerAction: 'all',
			forceSelection: true,
			editable: false,
			fieldLabel: _('Event'),
			name: 'event',
			hiddenName: 'event',
			displayField : 'key',
			valueField: 'key',
			store: store_events,
			singleMode: true,
			tpl: '<tpl for="."><div class="x-combo-list-item"><span id="boot" style="background: transparent"><strong>{key}</strong> {description}</span></div></tpl>'
		});
		
		
		var names_projects = new Object();
		var names_categories = new Object();
		
		cb_events.on('additem', function(combo, value, record) {
			var panel = Ext.getCmp('pnl_projects');
			if(panel) panel.destroy();
			panel = Ext.getCmp('pnl_categories');
			if(panel) panel.destroy();
			
			Baseliner.ajaxEval( '/notification/get_scope?key=' + value, {}, function(res) {
				if(res.success){
					var scopes = new Array();
					scopes = res.data;
					if(scopes){
						var indice = 1;
						var columns;
						for (var i = 0; i < scopes.length; i++){
							switch (scopes[i]){
								case 'project':
									var store_projects = new Baseliner.store.UserProjects({ id: 'id', baseParams: { include_root: true } });
									
									store_projects.on('load', function(ds, records, o){
										if(rec && rec.data){
											var ids_project = new Array();
											
											if(rec.data.data.scopes.project.length == 1 && rec.data.data.scopes.project[0][0] == '*'){
												chk_projects.setValue(true);
											}else{
												for(i=0; i < rec.data.data.scopes.project.length;i++){
													ids_project.push(rec.data.data.scopes.project[i][0]);
												}
												cb_projects.setValue( ids_project );            
											}
										}
									});										
		
									var cb_projects = new Baseliner.model.Projects({
										id: 'project',
										name: 'project',
										hiddenName: 'project',
										store: store_projects
									});
									
									cb_projects.on('additem', function(combo, value, record) {
										names_projects[value] = record.data.name;
									});									
									
									var chk_projects = new Ext.form.Checkbox({
										name:'project',
										boxLabel:_('All'),
										listeners: {
											check: function(obj, checked){
												if(checked){
													cb_projects.setValue('');
													cb_projects.disable();
												}else{
													cb_projects.enable();	
												}
											}
										}
									});
									
									columns = {
										id: 'pnl_projects',
										layout:'column',
										defaults:{
											layout:'form'
										},
										items:[
											{
												columnWidth: 0.85,
												items: cb_projects
											},
											{
												columnWidth: 0.15,
												labelWidth: 5,
												items: chk_projects
											}
										]
									};
									form_notification.insert(indice++,columns);
									break;
								case 'category':
									var store_categories = new Baseliner.Topic.StoreCategory({
										fields: ['id', 'name', 'color' ] 	
									});
									
									store_categories.on('load', function(ds, records, o){
										if(rec && rec.data){
											var ids_category = new Array();
											
											if(rec.data.data.scopes.category.length == 1 && rec.data.data.scopes.category[0][0] == '*'){
												chk_categories.setValue(true);
											}else{
												for(i=0; i < rec.data.data.scopes.category.length;i++){
													ids_category.push(rec.data.data.scopes.category[i][0]);
												}
												cb_categories.setValue( ids_category );            
											}
										}
									});									
									
									var tpl_list = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item">',
										'<span id="boot" style="width:200px"><span class="badge" style="float:left;padding:2px 8px 2px 8px;color: #FFFFFF;background:{color}">{name}</span> </span>',
										'</div></tpl>' );
									
									//var tpl_field = new Ext.XTemplate( '<tpl for=".">',
									//	'<span id="boot"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: {color}">{name}</span></span>',
									//	'</tpl>' );		
									
									var cb_categories = new Ext.ux.form.SuperBoxSelect({
										mode: 'local',
										triggerAction: 'all',
										forceSelection: true,
										fieldLabel: _('Categories'),
										id: 'category',
										name: 'category',
										hiddenName: 'category',
										displayField : 'name',
										valueField: 'id',
										store: store_categories,
										tpl: tpl_list
										//displayFieldTpl: tpl_field
									});
									
									cb_categories.on('additem', function(combo, value, record) {
										names_categories[value] = record.data.name;
									});										
									
									var chk_categories = new Ext.form.Checkbox({
										name:'category',
										boxLabel:_('All'),
										listeners: {
											check: function(obj, checked){
												if(checked){
													cb_categories.setValue('');
													cb_categories.disable();
												}else{
													cb_categories.enable();	
												}
											}
										}
									});
									
									columns = {
										id: 'pnl_categories',
										layout:'column',
										defaults:{
											layout:'form'
										},
										items:[
											{
												columnWidth: 0.85,
												items: cb_categories
											},
											{
												columnWidth: 0.15,
												labelWidth: 5,
												items: chk_categories
											}
										]
									};
									form_notification.insert(indice++,columns);
									store_categories.load();
									break;											
							}
							
						}
						form_notification.doLayout();
					}
				}
				else {
					var div_msg = Ext.get("msg");
					div_msg.createChild('<div id="msg_text" class="alert"><a class="close" data-dismiss="alert">×</a><span><b>' +  res.msg + '</b></span></div>');
					div_msg.show();
				}				
			})
		});
		
		var store_templates = new Baseliner.JsonStore({
			url: '/notification/get_templates',
			root: 'data',
			fields: ['name','path']   
		});
		
		store_templates.on('load', function(ds, records, o){
			if(rec && rec.data){
				cb_templates.setValue( rec.data.template_path );            
			}
		});		
		
		store_templates.load();		
		
		var cb_templates = new Ext.ux.form.SuperBoxSelect({
			mode: 'local',
			triggerAction: 'all',
			forceSelection: true,
			editable: false,
			fieldLabel: _('Template'),
			name: 'template',
			hiddenName: 'template',
			displayField : 'name',
			valueField: 'path',
			store: store_templates,
			singleMode: true,
			tpl: '<tpl for="."><div class="x-combo-list-item"><span id="boot" style="background: transparent"><strong>{name}</strong> </span></div></tpl>'
		});		
		
        var names_recipients = new Object();
		
		var add_edit_recipients = function (){
			var store_carriers = new Baseliner.JsonStore({
				url: '/notification/list_carriers',
				fields: ['carrier']   
			});		
			
			var cb_carriers = new Ext.ux.form.SuperBoxSelect({
				fieldLabel: _('Recipients'),
				mode: 'local',
				triggerAction: 'all',
				forceSelection: true,
				editable: false,
				name: 'carrier',
				hiddenName: 'carrier',
				displayField : 'carrier',
				valueField: 'carrier',
				store: store_carriers,
				tpl: '<tpl for="."><div class="x-combo-list-item"><span id="boot" style="background: transparent"><strong>{carrier}</strong> {description}</span></div></tpl>'
			});
			
			store_carriers.load();

			var store_type_recipients = new Baseliner.JsonStore({
				url: '/notification/list_type_recipients',
				fields: ['type_recipient']   
			});		
			
			var cb_type_recipient = new Ext.ux.form.SuperBoxSelect({
				mode: 'local',
				triggerAction: 'all',
				forceSelection: true,
				editable: false,
				name: 'type_recipient',
				hiddenName: 'type_recipient',
				displayField : 'type_recipient',
				valueField: 'type_recipient',
				store: store_type_recipients,
				singleMode: true,
				tpl: '<tpl for="."><div class="x-combo-list-item"><span id="boot" style="background: transparent"><strong>{[_(values.type_recipient)]}</strong> {description}</span></div></tpl>'
			});
			
			cb_type_recipient.on('additem', function(combo, value, record) {
				//Ext.getCmp("pnl_recipient").hide();
				//col1_recipient.removeAll();
				//col2_recipient.removeAll();					
	
				Baseliner.ajaxEval( '/notification/get_recipients/' + value, {}, function(res) {
					if(res.success){
						if(res.data.length > 0){
							var obj_recipient;
							switch (res.obj){
								case 'combo':
									var store_recipients1 = new Ext.data.JsonStore({
										fields: ['id', 'name', 'description'],
										data: res.data
									});
									
									obj_recipient = new Ext.ux.form.SuperBoxSelect({
										id:'obj_recipient',
										mode: 'local',
										triggerAction: 'all',
										forceSelection: true,
										editable: false,
										displayField : 'name',
										valueField: 'id',
										store: store_recipients1,
										tpl: '<tpl for="."><div class="x-combo-list-item"><span id="boot" style="background: transparent"><div style="font-size:16px;"><strong>{name}</strong></div>{description}</span></div></tpl>'
									});
									
									obj_recipient.on('additem', function(combo, value, record) {
										names_recipients[value] = record.data.name;
									});
									
									var chk_recipient = new Ext.form.Checkbox({
										//id: 'chk_recipients',
										name:'chk_recipients',
										boxLabel:_('All'),
										listeners: {
											check: function(obj, checked){
												if(checked){
													obj_recipient.setValue('');
													obj_recipient.disable();
												}else{
													obj_recipient.enable();	
												}
											}
										}
									});
									
									//col1_recipient.add(obj_recipient);
									//col2_recipient.add(chk_recipient);
									
									Ext.getCmp("pnl_recipient").add(
										{
											columnWidth: 0.85,
											items: obj_recipient
										},
										{
											columnWidth: 0.15,
											labelWidth: 5,
											items: chk_recipient
									});
									Ext.getCmp("pnl_recipient").show();
									break;
								case 'textfield':
									Ext.getCmp("pnl_recipient").destroy();
									form_recipients.add(
										{ 	id:'obj_recipient',
											xtype: 'textfield',
											emptyText: 'test1@clarive.com, test2@clarive.com, ...'
										}
									)
									break;
								case 'none':
									Ext.getCmp("pnl_recipient").destroy();
									break;
							}
							
							form_recipients.doLayout();
						}
					}
					else {
						var div_msg = Ext.get("msg");
						div_msg.createChild('<div id="msg_text" class="alert"><a class="close" data-dismiss="alert">×</a><span><b>' +  res.msg + '</b></span></div>');
						div_msg.show();
					}				
				})
			});		
			
			store_type_recipients.load();		
		
			//var col1_recipient = new Ext.FormPanel();
			//var col2_recipient = new Ext.FormPanel({
			//	defaults: {height: 30}
			//});
			
			var add_recipients = function (){
				if (cb_carriers.getValue() != '' && cb_type_recipient.getValue() != ''){
					var id, d, r;
					var carriers = cb_carriers.getValue().split(',');
					
					var ids = [];
					var is_text = false;
					
					if(form_recipients.getForm().findField("obj_recipient")){
						ids = form_recipients.getForm().findField("obj_recipient").getValue().split(',');	
					}
					

					Ext.each(carriers, function(carrier){
						if(form_recipients.getForm().findField("obj_recipient") && form_recipients.getForm().findField("obj_recipient").xtype == 'textfield'){
							is_text = true;
						}
					
						if(ids.length == 0){
							id = store_recipients.getCount() + 1;
							d = { id: id, recipients: carrier, type: _(cb_type_recipient.getValue())};
							r = new store_recipients.recordType( d, id );
							store_recipients.add( r );								
						}
						
						Ext.each(ids, function (id_recipient){
							id_recipient = id_recipient.replace(/^\s+|\s+$/g, '');
							id = store_recipients.getCount() + 1;
							if(!id_recipient){
								var obj_chk_all = form_recipients.getForm().findField("chk_recipients");
								if(obj_chk_all && obj_chk_all.getValue()){
									id_recipient = '*';
									names_recipients[id_recipient] = _('All');
								}
							}
							d = { id: id, recipients: carrier, type: _(cb_type_recipient.getValue()), items_id: id_recipient, items_name: is_text ? id_recipient : names_recipients[id_recipient] };
							r = new store_recipients.recordType( d, id );
							store_recipients.add( r );						
							
							
						});
					});
					
					store_recipients.commitChanges();
					win_recipients.close();
				}
				delete names_recipients;
			};
		
			var form_recipients = new Ext.FormPanel({
				frame: true,
				padding: 15,
				defaults: {
					height: 40,
					anchor: '100%'
				},
				items: [
					{
						layout:'column',
						defaults:{
							layout:'form'
						},
						items:[
							{
								columnWidth: 0.7,
								items: cb_carriers
							},
							{
								labelWidth: 2,
								columnWidth: 0.3,
								items: cb_type_recipient
							}
						]
					},
					{
						layout:'column',
						id: 'pnl_recipient',
						hidden: true,
						defaults:{
							layout:'form'
						}
						//,
						//items:[
						//	{
						//		columnWidth: 0.85,
						//		items: col1_recipient
						//	},
						//	{
						//		columnWidth: 0.15,
						//		labelWidth: 5,
						//		items: col2_recipient
						//	}
						//]
					}					
				],
				buttons: [
					{  text: _('Cancel') , handler: function(){  win_recipients.close(); } },
					{  text: _('Accept') , handler: function(){  add_recipients(); } }
				]
			});
			
			title = _('Create recipient');
			
			win_recipients = new Ext.Window({
				title: _(title),
				autoHeight: true,
				width: 730,
				closeAction: 'close',
				modal: true,
				items: form_recipients
			});
			
			win_recipients.show();			
		}
		
		var store_recipients = new Baseliner.JsonStore({
			root: 'data' , 
			remoteSort: true,
			id: 'id', 
			fields: [
				{  	name: 'recipients',
					name: 'type',
					name: 'items_id',
					name: 'items_name'
				}
			]														   
		});

		var btn_add_recipients = new Baseliner.Grid.Buttons.Add({
			handler: function() {
				add_edit_recipients();
			}
		});

		var btn_delete_recipients = new Baseliner.Grid.Buttons.Delete({
			handler: function() {
				var sm = grid_recipients.getSelectionModel();
				if (sm.hasSelection()) {
					var sel = sm.getSelected();
					grid_recipients.getStore().remove(sel);
					btn_delete_recipients.disable();
				} else {
					Baseliner.message( _('ERROR'), _('Select at least one row'));    
				};				
			}
		});
		
		var delete_field_row = function( id_grid, id ) {
			var g = Ext.getCmp( id_grid );
			var s = g.getStore();
			s.each( function(row){
				if( row.data.id == id ) {
					s.remove( row );
				}
			});
		};		
		
		var grid_recipients = new Ext.grid.GridPanel({
			style: 'border: solid #ccc 1px',
			store: store_recipients,
			layout: 'form',
			height: 300,
			hideHeaders: true,
			viewConfig: {
				headersDisabled: true,
				forceFit: true
			},
			tbar: [
				btn_add_recipients,
				btn_delete_recipients
			],			
			columns: [
				{ width: 50, dataIndex: 'recipients'},
				{ width: 50, dataIndex: 'type'},
				{ width: 200, dataIndex: 'items_name'}
			]
		});
		
		grid_recipients.on('rowclick', function(grid, rowIndex, e) {
			btn_delete_recipients.enable();
		});		
		
		var save_notification = function (){
			var form = form_notification.getForm();
			form.url = '/notification/save_notification';
			
			if (form.isValid()) {
				var params = new Object();
				params = {};

				if(rec && rec.data){
					params.id = rec.data.id;
				};
								
				if(form.findField('project') && form.findField('project').getValue() != ''){
					var projects = form.findField('project').getValue().split(',');
					var projects_names = new Array();
					Ext.each(projects, function(project){
						projects_names.push([project, names_projects[project]]);
					});
					
					params.project_names = Ext.util.JSON.encode( projects_names );
				};
				
				delete names_projects;
				
				if(form.findField('category') && form.findField('category').getValue() != ''){
					var categories = form.findField('category').getValue().split(',');
					var categories_names = new Array();
					Ext.each(categories, function(category){
						categories_names.push([category, names_categories[category]]);
					});
					
					params.category_names = Ext.util.JSON.encode( categories_names );
				};
				
				delete names_categories;
				
				var recipients = new Object();
				store_recipients.each( function(row){
					if (!recipients[row.data.recipients]) recipients[row.data.recipients] = {};
					if (!recipients[row.data.recipients][row.data.type]) recipients[row.data.recipients][row.data.type] = new Array();
					recipients[row.data.recipients][row.data.type].push([row.data.items_id, row.data.items_name]);
				});
				params.recipients = Ext.util.JSON.encode( recipients );
						
				form.submit({
					//params: {	project_names: Ext.util.JSON.encode( projects_names ),
					//			recipients: Ext.util.JSON.encode( recipients )
					//		},
					params: params,					
					success: function(f,a){
						
						Baseliner.message(_('Success'), a.result.msg );
						store_notifications.reload();
					}
				});
			}
		}
		
		var form_notification = new Ext.FormPanel({
			frame: true,
			padding: 15,
			items: [
				{
					layout:'column',
					defaults:{
						layout:'form'
					},
					items:[
						{
							columnWidth: 0.70,
							items: cb_events
						},
						{
							columnWidth: 0.30,
							labelWidth: 5,
							items:
								{
									xtype: 'radiogroup',
									cls: 'x-check-group-alt',
									name: 'rd_actions',
									items: actions
								}
						}
					]
				},
				cb_templates,
				{
					xtype: 'panel',
					fieldLabel: _('Recipients'),
					items: grid_recipients
				}				
			],
			buttons: [
				{  text: _('Close') , handler: function(){  win.close(); } },
				{  text: _('Accept') , handler: function(){  save_notification(); } }
			]			
		});	
        
        if(rec){
            var ff = form_notification.getForm();
            ff.loadRecord( rec.data );
			ff.findField('rd_actions').setValue(rec.data.action);

			for (carrier in rec.data.data.recipients){
				for (type in rec.data.data.recipients[carrier]){
					
					if(rec.data.data.recipients[carrier][type].length > 0){
						for(i=0; i < rec.data.data.recipients[carrier][type].length;i++ ){
							id = store_recipients.getCount() + 1;
							d = { id: id, recipients: carrier, type: _(type), items_id: rec.data.data.recipients[carrier][type][i][0], items_name: rec.data.data.recipients[carrier][type][i][1]};
							r = new store_recipients.recordType( d, id );
							store_recipients.add( r );							
						}
						
					}else{
						id = store_recipients.getCount() + 1;
						d = { id: id, recipients: carrier, type: _(type)};
						r = new store_recipients.recordType( d, id );
						store_recipients.add( r );						
					}
				}
			}
			store_recipients.commitChanges();
			
            title = 'Edit notification';
        }
		
        win = new Ext.Window({
            title: _(title),
            autoHeight: true,
            width: 730,
            closeAction: 'close',
            modal: true,
            items: form_notification
        });
		
        win.show();
    };
	
    var btn_start = new Baseliner.Grid.Buttons.Start({
        handler: function() {
            var notifications_checked = getNotifications();
			Baseliner.ajaxEval( '/notification/change_active', { ids_notification: notifications_checked, action: 'active' },
				function(resp){
					Baseliner.message( resp.success ? _('Success') : _('ERROR'), _(resp.msg) );
					store_notifications.load();
				}
			);
        }
    });

    var btn_stop = new Baseliner.Grid.Buttons.Stop({
        handler: function() {
			var notifications_checked = getNotifications();
            Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to deactivate the notifications selected?'), 
                function(btn){ 
                    if(btn=='yes') {
                        Baseliner.ajaxEval( '/notification/change_active', { ids_notification: notifications_checked, action: 'deactive' },
                            function(resp){
                                Baseliner.message( resp.success ? _('Success') : _('ERROR'), _(resp.msg) );
                                store_notifications.load();
                            }
                        );
                    }
                }
            );
        }
    });    

    var btn_add = new Baseliner.Grid.Buttons.Add({
        handler: function() {
			add_edit();
        }       
    });
	
    var btn_edit = new Baseliner.Grid.Buttons.Edit({
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
	
    var btn_delete = new Baseliner.Grid.Buttons.Delete({
        handler: function() {
            var notifications_checked = getNotifications();
            Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the notifications selected?'), 
            function(btn){ 
                if(btn=='yes') {
                    Baseliner.ajaxEval( '/notification/remove_notifications',{ ids_notification: notifications_checked },
                        function(response) {
                            if ( response.success ) {
                                Baseliner.message( _('Success'), response.msg );
                                init_buttons('disable');
                                store_notifications.load();
                            } else {
                                Baseliner.message( _('ERROR'), response.msg );
                            }
                        }
                    
                    );
                }
            } );
        }       
    });  	
	
	var check_notifications_sm = new Ext.grid.CheckboxSelectionModel({
		singleSelect: false,
		sortable: false,
		checkOnly: true
	});	
    
    
	var show_recipients = function(value,metadata,rec,rowIndex,colIndex,store) {
		var items = new Array();
        var ret = '<table>';
		for(var carrier in value.recipients) {
			ret += '<th>' + carrier + '</th>';
			for(var type in value.recipients[carrier]) {
				ret += '<tr>';
				ret += '<td style="font-weight: bold;padding: 3px 3px 3px 3px;">' + _(type) + '</td>';
				for(var i=0;i < value.recipients[carrier][type].length;i++){
					if(value.recipients[carrier][type][i][1]){
						items.push(value.recipients[carrier][type][i][1]);	
					}
				}
				if(items.length > 0){
					ret += '<td width="80%" style=" background: #f5f5f5;padding: 3px 3px 3px 3px;"><code>' + items.join(',') + '</code></td>'
				}
				ret += '</tr>';
				items = [];
			}
		}
		ret += '</table>';
		return ret;
    };
	
	var show_scopes = function(value,metadata,rec,rowIndex,colIndex,store) {
		var items = new Array();
        var ret = '<table>';
		for(var scope in value.scopes) {
			ret += '<tr>';
			ret += '<td style="font-weight: bold;padding: 3px 3px 3px 3px;">' + _(scope) + '</td>';
			if(value.scopes[scope]){
				for(var i=0;i < value.scopes[scope].length;i++){
					items.push(value.scopes[scope][i][1]);
				}
			}
			ret += '<td width="80%" style=" background: #f5f5f5;padding: 3px 3px 3px 3px;"><code>' + items.join(',') + '</code></td>'
			ret += '</tr>';
			items = [];
		}
		ret += '</table>';
		return ret;
    };
	
    var show_active = function(value,metadata,rec,rowIndex,colIndex,store) {
    var img =
        value == '1' ? 'drop-yes.gif' : 'close-small.gif';
        return "<img alt='"+value+"' border=0 style='vertical-align: top; margin: 0 0 10 2;' src='/static/images/"+img+"' />" ;
    };
	
    var show_action = function(value,metadata,rec,rowIndex,colIndex,store) {
        return _(value);
    };	
	
    var show_event = function(value, metadata, rec, rowIndex, colIndex, store) {
        return "<div style='font-weight:bold; font-size: 14px;'>" + value + "</div>" ;
    };
	
    var init_buttons = function(action) {
        eval('btn_start.' + action + '()');       
        eval('btn_stop.' + action + '()');
		eval('btn_edit.' + action + '()');
		eval('btn_delete.' + action + '()');
    }
	
    function getNotifications(){
        var notifications_checked = new Array();
        check_notifications_sm.each(function(rec){
            notifications_checked.push(rec.get('id'));
        });
        return notifications_checked;
    }  	
	
	var grid = new Ext.grid.GridPanel({
		sm: check_notifications_sm,
        store: store_notifications,
        stripeRows: true,
        viewConfig: {
            forceFit: true
        },
        columns:[
			check_notifications_sm,
            { header: _('Event'), width: 150, dataIndex: 'event_key', renderer: show_event },
            { header: _('Recipients'), width: 200, dataIndex: 'data', renderer: show_recipients },
			{ header: _('Scopes'), width: 200, dataIndex: 'data', renderer: show_scopes },
			{ header: _('Action'), width: 50, dataIndex: 'action', renderer: show_action },
			//{ header: _('Digest time'), width: 60, dataIndex: 'digest_time' },
			//{ header: _('Digest date'), width: 60, dataIndex: 'digest_date' },
			//{ header: _('Digest frequency'), width: 60, dataIndex: 'digest_freq' },
			{ header: _('Active'), width: 40, dataIndex: 'is_active', renderer: show_active  }
        ],
        tbar: [ 
            search_field,
            btn_start,
            btn_stop,
			btn_add,
			btn_edit,
			btn_delete
        ],
		bbar: ptool
    });
	
    grid.on('cellclick', function(grid, rowIndex, columnIndex, e) {
        if(columnIndex == 0){
            var notifications_checked = getNotifications();
            if (notifications_checked.length == 1){
                init_buttons('enable');
            }else{
                if(notifications_checked.length == 0){
					init_buttons('disable');
                }else{
                    btn_start.enable();
					btn_stop.enable();
					btn_edit.disable();
					btn_delete.enable();
                }
            }           
        }
    });
    
    grid.on('headerclick', function(grid, columnIndex, e) {
        if(columnIndex == 0){
            var notifications_checked = getNotifications();
            if(notifications_checked.length == 0){
                init_buttons('disable');
            }else{
				btn_start.enable();
				btn_stop.enable();
				btn_edit.disable();
				btn_delete.enable();
            }
        }
    });
	
    return grid;
})
