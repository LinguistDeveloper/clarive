(function(params){
    var ps = 30;
	
	var fields = ['id', 'id_event', 'action','dest_to', 'dest_cc',
				  'dest_bcc', 'event_scope', 'is_active', 'username',
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
		
		cb_events.on('additem', function(combo, value, record) {
			col1.removeAll();
			col2.removeAll();			
			Baseliner.ajaxEval( '/notification/get_scope?key=' + value, {}, function(res) {
				if(res.success){
					var scopes = new Array();
					scopes = res.data;
					if(scopes){
						for (var i = 0; i < scopes.length; i++){
							switch (scopes[i]){
								case 'project':
									var store_projects = new Baseliner.store.UserProjects({ id: 'id', baseParams: { include_root: true } });
		
									var cb_projects = new Baseliner.model.Projects({
										store: store_projects
									});
									
									var chk_projects = new Ext.form.Checkbox({
										name:'projects',
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
									
									col1.add(cb_projects);
									col2.add(chk_projects);
									break;
								case 'category':
									var store_categories = new Baseliner.Topic.StoreCategory({
										fields: ['id', 'name', 'color' ] 	
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
										name: 'category',
										hiddenName: 'category',
										displayField : 'name',
										valueField: 'id',
										store: store_categories,
										tpl: tpl_list
										//displayFieldTpl: tpl_field
									});

									var chk_categories = new Ext.form.Checkbox({
										name:'categories',
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
									
									col1.add(cb_categories);
									col2.add(chk_categories);
									form_notification.doLayout();
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
		
		
		var col1 = new Ext.FormPanel();
		var col2 = new Ext.FormPanel({
			defaults: {height: 30}
		});
		
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
				tpl: '<tpl for="."><div class="x-combo-list-item"><span id="boot" style="background: transparent"><strong>{type_recipient}</strong> {description}</span></div></tpl>'
			});
			
			cb_type_recipient.on('additem', function(combo, value, record) {
				Ext.getCmp("pnl_recipient").hide();
				col1_recipient.removeAll();
				col2_recipient.removeAll();					
	
				Baseliner.ajaxEval( '/notification/get_recipients/' + value, {}, function(res) {
					if(res.success){
						if(res.data.length > 0){
							
							switch (res.obj){
								case 'combo':
									var store_recipients1 = new Ext.data.JsonStore({
										fields: ['id', 'name', 'description'],
										data: res.data
									});
									
									cb_recipient = new Ext.ux.form.SuperBoxSelect({
										mode: 'local',
										triggerAction: 'all',
										forceSelection: true,
										editable: false,
										name: 'recipients',
										hiddenName: 'recipients',
										displayField : 'name',
										valueField: 'id',
										store: store_recipients1,
										tpl: '<tpl for="."><div class="x-combo-list-item"><span id="boot" style="background: transparent"><div style="font-size:16px;"><strong>{name}</strong></div>{description}</span></div></tpl>'
									});
									
									var chk_recipient = new Ext.form.Checkbox({
										name:'chk_recipients',
										boxLabel:_('All'),
										listeners: {
											check: function(obj, checked){
												if(checked){
													cb_recipient.setValue('');
													cb_recipient.disable();
												}else{
													cb_recipient.enable();	
												}
											}
										}
									});
									
									col1_recipient.add(cb_recipient);
									col2_recipient.add(chk_recipient);
									
									Ext.getCmp("pnl_recipient").show();
									break;
								case 'textfield':
									form_recipients.add(
										{ 	name: res.data[0].name,
											xtype: 'textfield',
											emptyText: 'test1@clarive.com, test2@clarive.com, ...'
										}
									)
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
		
			var col1_recipient = new Ext.FormPanel();
			var col2_recipient = new Ext.FormPanel({
				defaults: {height: 30}
			});
		
			var form_recipients = new Ext.FormPanel({
				frame: true,
				padding: 15,
				defaults: {height: 30, anchor: '100%'},
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
						},
						items:[
							{
								columnWidth: 0.85,
								items: col1_recipient
							},
							{
								columnWidth: 0.15,
								labelWidth: 5,
								items: col2_recipient
							}
						]
					}					
				],
				buttons: [
					{  text: _('Cancel') , handler: function(){  win_recipients.close(); } },
					{  text: _('Accept') , handler: function(){  win_recipients.close(); } }
				]
			});
			
			title = _('Create Recipients');
			
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
		
		var store_recipients = new Baseliner.JsonStore();

		var btn_add_recipients = new Baseliner.Grid.Buttons.Add({
			handler: function() {
				add_edit_recipients();
			}
		});

		var btn_edit_recipients = new Baseliner.Grid.Buttons.Edit({
			handler: function() {
				
			}
		});
		
		var btn_delete_recipients = new Baseliner.Grid.Buttons.Delete({
			handler: function() {
				
			}
		});		
		
		var grid_recipients = new Ext.grid.GridPanel({
			style: 'border: solid #ccc 1px',
			store: store_recipients,
			layout: 'form',
			height: 300,
			hideHeaders: true,
			viewConfig: {
				headersDisabled: true,
				//enableRowBody: true,
				forceFit: true
			},
			tbar: [
				btn_add_recipients,
				btn_edit_recipients,
				btn_delete_recipients
			],			
			columns: [
				//{ header: '', width: 20, dataIndex: 'id_field', renderer: function(v,meta,rec,rowIndex){ return '<img style="float:right" src="' + rec.data.img + '" />'} },
				{ header: _('Name'), width: 240, dataIndex: 'name'},
				{ width: 40, dataIndex: 'id',
						renderer: function(v,meta,rec,rowIndex){
							return '<a href="javascript:Baseliner.delete_field_row(\''+grid_recipients.id+'\', '+v+')"><img style="float:middle" height=16 src="/static/images/icons/clear.png" /></a>'
						}			  
				}
			]
		});
		
		
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
									items: actions
								}
						}
					]
				},				
				{
					layout:'column',
					defaults:{
						layout:'form'
					},
					items:[
						{
							columnWidth: 0.85,
							items: col1
						},
						{
							columnWidth: 0.15,
							labelWidth: 5,
							items: col2
						}
					]
				},
				{
					xtype: 'panel',
					fieldLabel: _('Recipients'),
					items: grid_recipients
				}				
			]
		});	
        
        if(rec){
            var ff = form_notification.getForm();
            ff.loadRecord( rec );
            //username = rec.get('username');
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
	
	
    var btn_add = new Baseliner.Grid.Buttons.Add({
        handler: function() {
			add_edit();
        }       
    });
	
    var btn_edit = new Baseliner.Grid.Buttons.Edit({
        handler: function() {

        }       
    });
	
    var btn_delete = new Baseliner.Grid.Buttons.Delete({
        handler: function() {

        }       
    });  	
	
	var check_notifications_sm = new Ext.grid.CheckboxSelectionModel({
		singleSelect: false,
		sortable: false,
		checkOnly: true
	});	
    
    var grid = new Ext.grid.GridPanel({
		sm: check_notifications_sm,
        store: store_notifications,
        stripeRows: true,
        viewConfig: {
            forceFit: true
        },
        columns:[
			check_notifications_sm,
            { header: _('Event'), width: 160, dataIndex: 'id_event' },
            { header: _('Recipients'), width: 100, dataIndex: 'recipients' },
			{ header: _('Scope'), width: 100, dataIndex: 'event_scope' },
			{ header: _('Action'), width: 60, dataIndex: 'action' },
			{ header: _('Digest time'), width: 60, dataIndex: 'digest_time' },
			{ header: _('Digest date'), width: 60, dataIndex: 'digest_date' },
			{ header: _('Digest frequency'), width: 60, dataIndex: 'digest_freq' },
			{ header: _('Active'), width: 20, dataIndex: 'is_active' }
        ],
        tbar: [ 
            search_field,
			btn_add,
			btn_edit,
			btn_delete
        ],
		bbar: ptool
    });
    return grid;
})
