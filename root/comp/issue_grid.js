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
			{  name: 'numcomment' },
			{  name: 'category' }
		],
		listeners: {
			'beforeload': function( obj, opt ) {
				obj.baseParams.filter = 'O';
				}
			}			
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
			{  name: 'created_by' },
			{  name: 'numcomment' },
			{  name: 'category' }
		],
		listeners: {
			'beforeload': function( obj, opt ) {
				obj.baseParams.filter = 'C';
				}
			}			

	});
	
	var store_category = new Ext.data.JsonStore({
		root: 'data' , 
		remoteSort: true,
		totalProperty:"totalCount", 
		id: 'id', 
		url: '/issue/list_category',
		fields: [ 
			{  name: 'id' },
			{  name: 'name' },
			{  name: 'description' }
		]
	});
	
	var query_id = '<% $c->stash->{query_id} %>';
	store_opened.load({params:{start:0 , limit: ps, filter:'O', query_id: '<% $c->stash->{query_id} %>'}});
	store_closed.load({params:{start:0 , limit: ps, filter:'C'}});
	store_category.load();
	
	var init_buttons = function(action) {
		eval('btn_edit.' + action + '()');
		eval('btn_delete.' + action + '()');
		//eval('btn_comment.' + action + '()');
		eval('btn_close.' + action + '()');
	}
	
	var init_buttons_category = function(action) {
		eval('btn_edit_category.' + action + '()');
		eval('btn_delete_category.' + action + '()');
	}	
	
	var btn_add = new Ext.Toolbar.Button({
			id: 'btn_add',
			text: _('New'),
			icon:'/static/images/icons/add.gif',
			cls: 'x-btn-text-icon',
			handler: function() {
						add_edit()
			}
	});
	
	var btn_edit = new Ext.Toolbar.Button({
		id: 'btn_edit',
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
		id: 'btn_delete',
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
		id: 'btn_comment',
		text: _('Comment'),
		icon:'/static/images/icons/comment_new.gif',
		cls: 'x-btn-text-icon',
		disabled: true,
		handler: function() {
			add_comment()
		}
	});

	var btn_close = new Ext.Toolbar.Button({
		id: 'btn_close',
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
		
		var combo_category = new Ext.form.ComboBox({
			mode: 'local',
			forceSelection: true,
			triggerAction: 'all',
			fieldLabel: _('Category'),
			name: 'category',
			hiddenName: 'category',
			displayField: 'name',
			valueField: 'id',
			store: store_category
		});		
		
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
				combo_category,
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

	var add_comment = function() {
		var win;
		
		var blank_image = new Ext.BoxComponent({autoEl: {tag: 'img', src: Ext.BLANK_IMAGE_URL}, widht:10});
		
		var title = 'Create comment';
		
		var form_issue_comment = new Ext.FormPanel({
			frame: true,
			url:'/issue/viewdetail',
			labelAlign: 'top',
			bodyStyle:'padding:10px 10px 0',
			buttons: [
				{
				text: _('Accept'),
				type: 'submit',
				handler: function() {
					var form = form_issue_comment.getForm();
					var obj_tab = Ext.getCmp('tabs_issues');
					var obj_tab_active = obj_tab.getActiveTab();
					var title = obj_tab_active.title;
					cad = title.split('#');
					var action = cad[1]; 
					if (form.isValid()) {
					       form.submit({
						   params: {action: action},
						   success: function(f,a){
						       Baseliner.message(_('Success'), a.result.msg );
						       store_issue_comments.load({ params: {id_rel: cad[1]} });
						       win.close();
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
				{
				xtype:'htmleditor',
				name:'text',
				fieldLabel: _('Text'),
				height:350
				}
			]
		});

		win = new Ext.Window({
			title: _(title),
			width: 700,
			autoHeight: true,
			items: form_issue_comment
		});
		win.show();		
	};


	var render_id = function(value,metadata,rec,rowIndex,colIndex,store) {
		return "<div style='font-weight:bold; font-size: 14px; color: #808080'> #" + value + "</div>" ;
	};

	var render_title = function(value,metadata,rec,rowIndex,colIndex,store) {
		//return "<div style='font-weight:bold; font-size: 14px;'> " + value + "</div>" ;
		var tag_comment_html;
		tag_comment_html='';
		if(rec.data.numcomment){
			tag_comment_html = "<span style='color: #808080'><img border=0 src='/static/images/icons/comment_blue.gif' /> " + rec.data.numcomment + " comments</span>";
		}		
		return "<div width='500px'><div style='font-weight:bold; font-size: 14px;' >" + value + "</div><br><div><font color='808080'>by </font><b>" + rec.data.created_by + "</b> <font color='808080'>" + rec.data.created_on + "</font ></div></div>";
	};
	
	var render_comment = function(value,metadata,rec,rowIndex,colIndex,store) {
		var tag_comment_html;
		tag_comment_html='';
		if(rec.data.numcomment){
			tag_comment_html = "<span style='color: #808080'><img border=0 src='/static/images/icons/comment_blue.gif' /> " + rec.data.numcomment + " comments</span>";
		}		
		return tag_comment_html;
	};	

	var grid_opened = new Ext.grid.GridPanel({
		title: _('Issues'),
		header: false,
		stripeRows: true,
		autoScroll: true,
		height: 400,
		enableHdMenu: false,
		store: store_opened,
		viewConfig: {	forceFit: true/*,
				enableRowBody: true,
				getRowClass: function(record, rowIndex, p, store){
					tag_comment_html='';
					if(record.data.numcomment){
						tag_comment_html = "<span style='color: #808080'><img border=0 src='/static/images/icons/comment_blue.gif' /> " + record.data.numcomment + " comments</span>";
					}
					p.body = "<div style='margin-left: 6em'><table><tr><td></td><td width='600px'><font color='808080'>by </font><b>" + record.data.created_by + "</b> <font color='808080'>" + record.data.created_on + "</font ></td><td>" + tag_comment_html + "</td></tr></table></div>";
					return 'x-grid3-row-expanded';
				}*/
		},
		selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		loadMask:'true',
		columns: [
			{ header: _('Issue'), dataIndex: 'id', width: 39, sortable: false, renderer: render_id },	
			{ header: _('Title'), dataIndex: 'title', width: 250, sortable: true, renderer: render_title },
			{ header: _('Comments'), dataIndex: 'numcomment', width: 60, sortable: true, renderer: render_comment },
			{ header: _('Category'), dataIndex: 'category', width: 50, sortable: true },
			{ header: _('Description'), hidden: true, dataIndex: 'description' }
		],
		autoSizeColumns: true,
		deferredRender:true,
		bbar: new Ext.PagingToolbar({
			store: store_opened,
			pageSize: ps,
			displayInfo: true,
			displayMsg: _('Rows {0} - {1} of {2}'),
			emptyMsg: _('There are no rows available')
		})
	});
	
	grid_opened.on('rowclick', function(grid, rowIndex, columnIndex, e) {
		init_buttons('enable');
	});

	grid_opened.on("rowdblclick", function(grid, rowIndex, e ) {
	    var r = grid.getStore().getAt(rowIndex);
	    //if(r.get('numcomment')>0){
		Baseliner.addNewTab('/issue/view?id_rel=' + r.get('id') , 'Issue #' + r.get('id'),{},config_tabs );
	    //}
	    //btn_comment.enable();
	});	
	
	var grid_closed = new Ext.grid.GridPanel({
		title: _('Issues'),
		header: false,
		stripeRows: true,
		autoScroll: true,
		height: 400,
		store: store_closed,
		viewConfig: {	forceFit: true/*,
				enableRowBody: true,
				getRowClass: function(record, rowIndex, p, store){
					tag_comment_html='';
					if(record.data.numcomment){

						tag_comment_html = "<span style='color: #808080'><img border=0 src='/static/images/icons/comment_blue.gif' /> " + record.data.numcomment + " comments</span>";
					}
					p.body = "<div style='margin-left: 6em'><table><tr><td></td><td width='600px'><font color='808080'>by </font><b>" + record.data.created_by + "</b> <font color='808080'>" + record.data.created_on + "</font ></td><td>" + tag_comment_html + "</td></tr></table></div>";
					return 'x-grid3-row-expanded';
				}*/
		},
		selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		loadMask:'true',
		columns: [
			{ header: _('Issue'), dataIndex: 'id', width: 39, sortable: false, renderer: render_id },	
			{ header: _('Title'), dataIndex: 'title', width: 250, sortable: true, renderer: render_title },
			{ header: _('Comments'), dataIndex: 'numcomment', width: 60, sortable: true, renderer: render_comment },
			{ header: _('Category'), dataIndex: 'category', width: 50, sortable: true },
			{ header: _('Description'), hidden: true, dataIndex: 'description' }
		],
		autoSizeColumns: true,
		deferredRender:true,	
		bbar: new Ext.PagingToolbar({
			store: store_closed,
			pageSize: ps,
			displayInfo: true,
			displayMsg: _('Rows {0} - {1} of {2}'),
			emptyMsg: _('There are no rows available')
		})
	});
	
	grid_closed.on("rowdblclick", function(grid, rowIndex, e ) {
	    var r = grid.getStore().getAt(rowIndex);
	    //if(r.get('numcomment')>0){
		Baseliner.addNewTab('/issue/view?id_rel=' + r.get('id') , 'Issue #' + r.get('id'),{},config_tabs );
	    //}
	    //btn_comment.enable();
	});
	
	
	var search_field = new Ext.app.SearchField({
				store: store_opened,
				params: {start: 0, limit: ps},
				emptyText: _('<Enter your search string>')
			});
	
	var config_tabs = new Ext.TabPanel({
		id: 'tabs_issues',
		region: 'center',
		layoutOnTabChange:true,
		deferredRender: false,
		defaults: {layout:'fit'},
		tbar: [ _('Search') + ' ', ' ',
			search_field,
			btn_add,
			btn_edit,
			btn_delete,
			'->',
			btn_comment,
			btn_close
		], 
		items : [
			{
			  id: 'open_tab',
			  xtype : 'panel',
			  title : _('Open'),
			  items: [ grid_opened ]
			},
			{
			  id: 'closed_tab',
			  xtype : 'panel',
			  title : _('Closed'),
			  items: [ grid_closed ]
			},		 
		],
		activeTab : 0,
		listeners: {
		    'tabchange': function(tabPanel, tab){
				if(tab.id == 'open_tab'){
					search_field.store = store_opened;
					var sm = grid_opened.getSelectionModel();
					var sel = sm.getSelected();
					if(sel){
						btn_add.enable();
						init_buttons('enable');
					}else{
						init_buttons('disable');
						btn_add.enable();
					}
					btn_comment.disable();
				}
				else{
					if(tab.id == 'closed_tab'){
						search_field.store = store_closed;
						init_buttons('disable');
						btn_add.disable();
						btn_comment.disable();
					}
					else{
						init_buttons('disable');
						btn_add.disable();				
						btn_comment.enable();
					}
				}
		    }
		}		
	});
	
	
	var add_edit_category = function(rec) {
		var win;
		
		var blank_image = new Ext.BoxComponent({autoEl: {tag: 'img', src: Ext.BLANK_IMAGE_URL}, widht:10});
		
		var title = 'Create category';
		
		
        var ta = new Ext.form.TextArea({
            name: 'description',
            height: 130,
            enableKeyEvents: true,
            fieldLabel: _('Description'),
            emptyText: _('A brief description of the category')
        });		
		
		var form_category = new Ext.FormPanel({
			frame: true,
			url:'/issue/update_category',
			labelAlign: 'top',
			bodyStyle:'padding:10px 10px 0',
			buttons: [
				{
				text: _('Accept'),
				type: 'submit',
				handler: function() {
					var form = form_category.getForm();
					var action = form.getValues()['id'] >= 0 ? 'update' : 'add';
					
					if (form.isValid()) {
					       form.submit({
						   params: {action: action},
						   success: function(f,a){
						       Baseliner.message(_('Success'), a.result.msg );
						       form.findField("id").setValue(a.result.category_id);
						       store_category.load();
						       win.setTitle(_('Edit category'));
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
			defaults: { anchor:'100%'},
			items: [
				{ xtype: 'hidden', name: 'id', value: -1 },
				{ xtype:'textfield', name:'name', fieldLabel:_('Category'), allowBlank:false, emptyText:_('Name of category') },
				ta
			]
		});

		if(rec){
			var ff = form_category.getForm();
			ff.loadRecord( rec );
			title = 'Edit category';
		}
		
		win = new Ext.Window({
			title: _(title),
			width: 400,
			autoHeight: true,
			items: form_category
		});
		win.show();		
	};
	
	var btn_add_category = new Ext.Toolbar.Button({
			id: 'btn_add_category',
			text: _('New'),
			icon:'/static/images/icons/add.gif',
			cls: 'x-btn-text-icon',
			handler: function() {
						add_edit_category()
			}
	});
	
	var btn_edit_category = new Ext.Toolbar.Button({
		id: 'btn_edit_category',
		text: _('Edit'),
		icon:'/static/images/icons/edit.gif',
		cls: 'x-btn-text-icon',
		disabled: true,
		handler: function() {
		var sm = grid_categories.getSelectionModel();
			if (sm.hasSelection()) {
				var sel = sm.getSelected();
				add_edit_category(sel);
			} else {
				Baseliner.message( _('ERROR'), _('Select at least one row'));    
			};
		}
	});

	var btn_delete_category = new Ext.Toolbar.Button({
		id: 'btn_delete_category',
		text: _('Delete'),
		icon:'/static/images/icons/delete.gif',
		cls: 'x-btn-text-icon',
		disabled: true,
		handler: function() {
			var sm = grid_categories.getSelectionModel();
			var sel = sm.getSelected();
			Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the category') + ' <b>' + sel.data.name + '</b>?', 
			function(btn){ 
				if(btn=='yes') {
					Baseliner.ajaxEval( '/issue/update_category?action=delete',{ id: sel.data.id },
						function(response) {
							if ( response.success ) {
								grid_categories.getStore().remove(sel);
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

	var grid_categories = new Ext.grid.GridPanel({
		title: _('Categories'),
		header: false,
		stripeRows: true,
		autoScroll: true,
		autoHeight: true,
		store: store_category,
		viewConfig: {forceFit: true},
		selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		loadMask:'true',
		columns: [
			{ header: _('Category'), dataIndex: 'name', width:50, sortable: false },
			{ header: _('Description'), dataIndex: 'description', sortable: false },	
		],
		autoSizeColumns: true,
		deferredRender:true,	
		//bbar: new Ext.PagingToolbar({
		//	store: store_category,
		//	pageSize: ps,
		//	displayInfo: true,
		//	displayMsg: _('Rows {0} - {1} of {2}'),
		//	emptyMsg: _('There are no rows available')
		//}),        
		tbar: [ 
				btn_add_category,
				btn_edit_category,
				btn_delete_category,
				'->'
		]		
	});
	
	grid_categories.on('rowclick', function(grid, rowIndex, columnIndex, e) {
		init_buttons_category('enable');
	});


	var panel = new Ext.Panel({
		layout : "border",
		items : [ config_tabs,   
				{
				region : 'east',
				title : _('Categories'),
				width : 350,
				autoScroll: true,
				split : true,
				collapsible : true,
				items : [ grid_categories ]
				}
		]
	});
	return panel;
})();




