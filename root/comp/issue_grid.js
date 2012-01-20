(function(){
	<& /comp/search_field.mas &>
	var ps = 100; //page_size
	
	var store_opened = new Ext.data.JsonStore({
		root: 'data' , 
		remoteSort: true,
		totalProperty:"totalCount", 
		id: 'id', 
		url: '/issue/list',
		fields: [ 
			{  name: 'id' },
			{  name: 'title' },
			{  name: 'description' },
			{  name: 'created_on' },
			{  name: 'created_by' },
			{  name: 'numcomment' }			
		]
	});

	var store_closed = new Ext.data.JsonStore({
		root: 'data' , 
		remoteSort: true,
		totalProperty:"totalCount", 
		id: 'id', 
		url: '/issue/list',
		fields: [ 
			{  name: 'id' },
			{  name: 'title' },
			{  name: 'description' },
			{  name: 'created_on' },		
			{  name: 'created_by' }			
		]
	});
	
	store_opened.load({params:{start:0 , limit: ps, filter:'O'}});
	store_closed.load({params:{start:0 , limit: ps, filter:'C'}});
	
	var init_buttons = function(action) {
		eval('btn_edit.' + action + '()');
		eval('btn_delete.' + action + '()');
		eval('btn_comment.' + action + '()');		
		eval('btn_close.' + action + '()');
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
			var sm = grid_opened.getSelectionModel();
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
				var sm = grid_opened.getSelectionModel();
				var sel = sm.getSelected();
				Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the issue') + ' <b>' + sel.data.id + '</b>?', 
				function(btn){ 
					if(btn=='yes') {
						Baseliner.ajaxEval( '/issue/update?action=delete',{ id: sel.data.id },
							function(response) {
								if ( response.success ) {
									grid_opened.getStore().remove(sel);
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
	
        var btn_comment = new Ext.Toolbar.Button({
			text: _('Comment'),
			icon:'/static/images/icons/comment_new.gif',
			cls: 'x-btn-text-icon',
			disabled: true,
			handler: function() {
				//var sm = grid.getSelectionModel();
				//var sel = sm.getSelected();
				//Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the daemon') + ' <b>' + sel.data.service + '</b>?', 
				//function(btn){ 
				//	if(btn=='yes') {
				//		Baseliner.ajaxEval( '/daemon/update?action=delete',{ id: sel.data.id },
				//			function(response) {
				//				if ( response.success ) {
				//					grid.getStore().remove(sel);
				//					Baseliner.message( _('Success'), response.msg );
				//					init_buttons('disable');
				//				} else {
				//					Baseliner.message( _('ERROR'), response.msg );
				//				}
				//			}
				//		
				//		);
				//	}
				//} );
			}
        });

        var btn_close = new Ext.Toolbar.Button({
			text: _('Close'),
			icon:'/static/images/icons/cerrar.png',
			cls: 'x-btn-text-icon',
			disabled: true,
			handler: function() {
				var sm = grid_opened.getSelectionModel();
				var sel = sm.getSelected();
				Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to close the issue') + ' <b># ' + sel.data.id + '</b>?', 
				function(btn){ 
					if(btn=='yes') {
						Baseliner.ajaxEval( '/issue/update?action=close',{ id: sel.data.id },
							function(response) {
								if ( response.success ) {
									grid_opened.getStore().remove(sel);
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
		
		var title = 'Create issue';
		
		var form_issue = new Ext.FormPanel({
			frame: true,
			url:'/issue/update',
			labelAlign: 'top',
			bodyStyle:'padding:10px 10px 0',
			buttons: [
				{
				text: _('Accept'),
				type: 'submit',
				handler: function() {
					var form = form_issue.getForm();
					var action = form.getValues()['id'] >= 0 ? 'update' : 'add';
					
					if (form.isValid()) {
					       form.submit({
						   params: {action: action},
						   success: function(f,a){
						       Baseliner.message(_('Success'), a.result.msg );
						       form.findField("id").setValue(a.result.issue_id);
						       store_opened.load();
						       win.setTitle(_('Edit issue'));
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
			defaults: { width: 650 },
			items: [
				{ xtype: 'hidden', name: 'id', value: -1 },
				{
				    xtype:'textfield',
				    fieldLabel: _('Title'),
				    name: 'title',
				    allowBlank: false
				},
				{
				xtype:'htmleditor',
				name:'description',
				fieldLabel: _('Description'),
				height:350
				}
			]
		});

		if(rec){
			var ff = form_issue.getForm();
			ff.loadRecord( rec );
			title = 'Edit issue';
		}
		
		win = new Ext.Window({
			title: _(title),
			width: 700,
			autoHeight: true,
			items: form_issue
		});
		win.show();		
	};

	var render_id = function(value,metadata,rec,rowIndex,colIndex,store) {
		return "<div style='font-weight:bold; font-size: 14px; color: #808080'> #" + value + "</div>" ;
	};

	var render_title = function(value,metadata,rec,rowIndex,colIndex,store) {
		return "<div style='font-weight:bold; font-size: 14px;'> " + value + "</div>" ;
	};

	var grid_opened = new Ext.grid.GridPanel({
		title: _('Issues'),
		header: false,
		stripeRows: true,
		autoScroll: true,
		height: 400,
		enableHdMenu: false,
		store: store_opened,
		viewConfig: {	forceFit: true,
				enableRowBody: true,
				getRowClass: function(record, rowIndex, p, store){
					tag_comment_html='';
					if(record.data.numcomment){
						tag_comment_html = "<span style='color: #808080'><img border=0 src='/static/images/icons/comment_blue.gif' /> " + record.data.numcomment + " comments</span>";
					}
					p.body = "<div style='margin-left: 6em'><table><tr><td></td><td width='600px'><font color='808080'>by </font><b>" + record.data.created_by + "</b> <font color='808080'>" + record.data.created_on + "</font ></td><td>" + tag_comment_html + "</td></tr></table></div>";
					return 'x-grid3-row-expanded';
				}
		},
		selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		loadMask:'true',
		columns: [
			{ header: _('Issue'), dataIndex: 'id', width: 39, sortable: false, renderer: render_id },	
			{ header: _('Title'), dataIndex: 'title', width: 400, sortable: true, renderer: render_title },
			{ header: _('Description'), hidden: true, dataIndex: 'description' },
		],
		autoSizeColumns: true,
		deferredRender:true,
		bbar: new Ext.PagingToolbar({
			store: store_opened,
			pageSize: ps,
			displayInfo: true,
			displayMsg: _('Rows {0} - {1} of {2}'),
			emptyMsg: "No hay registros disponibles"
		})
	});
	
	grid_opened.on('rowclick', function(grid, rowIndex, columnIndex, e) {
		init_buttons('enable');
	});

	grid_opened.on("rowdblclick", function(grid, rowIndex, e ) {
	    var r = grid.getStore().getAt(rowIndex);
	    Baseliner.addNewTab('/issue/view?id_rel=' + r.get('id') , 'Issue #' + r.get('id'),{},config_tabs );
                                    //config_tabs.add     // this function works incorrectly
                                    //({
                                    //title: 'why this tab whithout grid?',
                                    //items: grid_opened
                                    //}).show();	    
	});	
	

	var grid_closed = new Ext.grid.GridPanel({
		title: _('Issues'),
		header: false,
		stripeRows: true,
		autoScroll: true,
		height: 400,
		store: store_closed,
		viewConfig: {	forceFit: true,
				enableRowBody: true,
				getRowClass: function(record, rowIndex, p, store){
					tag_comment_html='';
					if(record.data.numcomment){
						tag_comment_html = "<span style='color: #808080'><img border=0 src='/static/images/icons/comment_blue.gif' /> " + record.data.numcomment + " comments</span>";
					}
					p.body = "<div style='margin-left: 6em'><table><tr><td></td><td width='600px'><font color='808080'>by </font><b>" + record.data.created_by + "</b> <font color='808080'>" + record.data.created_on + "</font ></td><td>" + tag_comment_html + "</td></tr></table></div>";
					return 'x-grid3-row-expanded';
				}
		},
		selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		loadMask:'true',
		columns: [
			{ header: _('Issue'), dataIndex: 'id', width: 39, sortable: false, renderer: render_id },	
			{ header: _('Title'), dataIndex: 'title', width: 400, sortable: true, renderer: render_title },
			{ header: _('Description'), hidden: true, dataIndex: 'description' },
		],
		autoSizeColumns: true,
		deferredRender:true,	
		bbar: new Ext.PagingToolbar({
			store: store_closed,
			pageSize: ps,
			displayInfo: true,
			displayMsg: _('Rows {0} - {1} of {2}'),
			emptyMsg: "No hay registros disponibles"
		})
	});
	
	grid_closed.on('rowclick', function(grid, rowIndex, columnIndex, e) {
		init_buttons('enable');
	});
	
	var config_tabs = new Ext.TabPanel({
		region: 'center',
		layoutOnTabChange:true,
		deferredRender: false,
		defaults: {layout:'fit'},
		tbar: [ _('Search') + ' ', ' ',
				new Ext.app.SearchField({
				store: store_opened,
				params: {start: 0, limit: ps},
				emptyText: _('<Enter your search string>')
			}),
			btn_add,
			btn_edit,
			btn_delete,
			'->',
			btn_comment,
			btn_close
		], 
		items : [
			{
			  xtype : 'panel',
			  title : _('Open'),
			  items: [ grid_opened ]
			},
			{
			  xtype : 'panel',
			  title : _('Closed'),
			  items: [ grid_closed ]
			},		 
		],
		activeTab : 0
	});

	var labels = new Ext.Panel({});

	var panel = new Ext.Panel({
		layout : "border",
		items : [ config_tabs,   
			{
			region : 'east',
			title : _('Labels'),
			width : 300,
			autoScroll: true,
			split : true,
			collapsible : true,
			items : [ labels ]
		        }
		]
	});
	return panel;
})()




