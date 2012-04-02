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
			{  name: 'category' },
			{  name: 'projects' },
			{  name: 'labels' }
		],
		listeners: {
			'beforeload': function( obj, opt ) {
				obj.baseParams.filter = 'O';
				var labels_checked = getLabels();
				obj.baseParams.labels = labels_checked;
				var categories_checked = getCategories();
				obj.baseParams.categories = categories_checked;					
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
			{  name: 'category' },
			{  name: 'labels' }
		],
		listeners: {
			'beforeload': function( obj, opt ) {
				obj.baseParams.filter = 'C';
				var labels_checked = getLabels();
				obj.baseParams.labels = labels_checked;
				var categories_checked = getCategories();
				obj.baseParams.categories = categories_checked;				
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
	
	
	var store_label = new Ext.data.JsonStore({
		root: 'data' , 
		remoteSort: true,
		totalProperty:"totalCount", 
		id: 'id', 
		url: '/issue/list_label',
		fields: [ 
			{  name: 'id' },
			{  name: 'name' },
			{  name: 'color' }
		]
	});
	
	var init_buttons = function(action) {
		eval('btn_edit.' + action + '()');
		eval('btn_delete.' + action + '()');
		eval('btn_labels.' + action + '()');
		eval('btn_close.' + action + '()');
	}
	
	var init_buttons_category = function(action) {
		eval('btn_edit_category.' + action + '()');
		eval('btn_delete_category.' + action + '()');
	}	
	
	var init_buttons_label = function(action) {
		eval('btn_delete_label.' + action + '()');
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
	
	var btn_labels = new Ext.Toolbar.Button({
		id: 'btn_labels',
		text: _('Labels'),
		icon:'/static/images/icons/color_swatch.png',
		cls: 'x-btn-text-icon',
		disabled: true,
		handler: function() {
			var sm = grid_opened.getSelectionModel();
			if (sm.hasSelection()) {
				var sel = sm.getSelected();
				add_labels(sel);
			}
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

	var add_labels = function(rec) {
		var win;
		var title = 'Labels';
		
        var btn_cerrar_labels = new Ext.Toolbar.Button({
            icon:'/static/images/icons/door_out.png',
            cls: 'x-btn-text-icon',
            text: _('Close'),
			handler: function() {
				win.close();
            }
        });
        
        var btn_grabar_labels = new Ext.Toolbar.Button({
            icon:'/static/images/icons/database_save.png',
            cls: 'x-btn-text-icon',
            text: _('Save'),
            handler: function(){
				var labels_checked = new Array();
				check_ast_labels_sm.each(function(rec){
					labels_checked.push(rec.get('id'));
				});
				Baseliner.ajaxEval( '/issue/update_issuelabels',{ idissue: rec.data.id, idslabel: labels_checked },
					function(response) {
						if ( response.success ) {
							Baseliner.message( _('Success'), response.msg );
							var labels_checked = getLabels();
							filtrar_issues(labels_checked);
							
						} else {
							Baseliner.message( _('ERROR'), response.msg );
						}
					}
				);
            }
        });

		var check_ast_labels_sm = new Ext.grid.CheckboxSelectionModel({
			singleSelect: false,
			sortable: false,
			checkOnly: true
		});
	
		
		var grid_ast_labels = new Ext.grid.GridPanel({
			title : _('Labels'),
			sm: check_ast_labels_sm,
			autoScroll: true,
			header: false,
			stripeRows: true,
			autoScroll: true,
			height: 300,
			enableHdMenu: false,
			store: store_label,
			viewConfig: {forceFit: true},
			selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
			loadMask:'true',
			columns: [
				{ hidden: true, dataIndex:'id' },
				check_ast_labels_sm,
				{ header: _('Color'), dataIndex: 'color', width:15, sortable: false, renderer: render_color },
				{ header: _('Label'), dataIndex: 'name', sortable: false }
			],
			autoSizeColumns: true,
			deferredRender:false,
            bbar: [
                btn_grabar_labels,
                btn_cerrar_labels
            ],
			listeners: {
				viewready: function() {
					var me = this;
					
					var datas = me.getStore();
					var recs = [];
					datas.each(function(row, index){
						if(rec.data.labels){
							for(i=0;i<rec.data.labels.length;i++){
								if(row.get('id') == rec.data.labels[i].label){
									recs.push(index);	
								}
							}
						}						
					});
					me.getSelectionModel().selectRows(recs);					
				
				}
			}		
		});
		
		//Ext.util.Observable.capture(grid_ast_labels, console.info);
	
		win = new Ext.Window({
			title: _(title),
			width: 400,
			modal: true,
			autoHeight: true,
			items: grid_ast_labels
		});
		
		win.show();
	};


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
		var tag_comment_html;
		var tag_color_html;
		tag_comment_html = '';
		tag_color_html = '';
		if(rec.data.labels){
			for(i=0;i<rec.data.labels.length;i++){
				tag_color_html = tag_color_html + "<span style='width:35;float:left;border:1px solid #cccccc;background-color:" + rec.data.labels[i].color + "'>&nbsp;</span>";
			}
		}
		if(rec.data.numcomment){
			tag_comment_html = "<span style='color: #808080'><img border=0 src='/static/images/icons/comment_blue.gif' /> " + rec.data.numcomment + " comments</span>";
		}		
		return "<div style='font-weight:bold; font-size: 14px;' >" + value + "</div><br><div><font color='808080'>by </font><b>" + rec.data.created_by + "</b> <font color='808080'>" + rec.data.created_on + "</font ></div>" + tag_color_html;
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
		enableDragDrop: true,
		viewConfig: {forceFit: true},
		selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		loadMask:'true',
		columns: [
			{ header: _('Issue'), dataIndex: 'id', width: 39, sortable: true, renderer: render_id },	
			{ header: _('Title'), dataIndex: 'title', width: 250, sortable: true, renderer: render_title },
			{ header: _('Comments'), dataIndex: 'numcomment', width: 60, sortable: true, renderer: render_comment },
			{ header: _('Projects'), dataIndex: 'projects', width: 60, sortable: true, renderer: Baseliner.render_tags },
			{ header: _('Category'), dataIndex: 'category', width: 50, sortable: true, renderer: Baseliner.render_tags },
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
		Baseliner.addNewTab('/issue/view?id_rel=' + r.get('id') , 'Issue #' + r.get('id'),{},config_tabs );
	});
	
    grid_opened.on( 'render', function(){
        var el = grid_opened.getView().el.dom.childNodes[0].childNodes[1];
        var grid_opened_dt = new Ext.dd.DropTarget(el, {
            ddGroup: 'lifecycle_dd',
            copy: true,
            notifyDrop: function(dd, e, id) {
                var n = dd.dragData.node;
                var s = grid_opened.store;
                var add_node = function(node) {
                    var data = node.attributes.data;
					// determine the row
					var t = Ext.lib.Event.getTarget(e);
					var rindex = grid_opened.getView().findRowIndex(t);
					if (rindex === false ) return false;
					var row = s.getAt( rindex );
					var projects = row.get('projects');
					if( typeof projects != 'object' ) projects = new Array();
					if( projects.indexOf( data.project ) == -1 ) {
						row.beginEdit();
						projects.push( data.project );
						row.set('projects', projects );
						row.endEdit();
						row.commit();
						Baseliner.message( _('Info'), _('Project %1 added', data.project) );
					} else {
						Baseliner.message( _('Warning'), _('Project %1 is already assigned', data.project));
					}
					
                };
                var attr = n.attributes;
                if( typeof attr.data.id_project == 'undefined' ) {  // is a project?
					Baseliner.message( _('Error'), _('Node is not a project'));
			    } else {
					add_node(n);
				}
                // multiple? Ext.each(dd.dragData.selections, add_node );
                return (true); 
             }
        });
    });	
	
	var grid_closed = new Ext.grid.GridPanel({
		title: _('Issues'),
		header: false,
		stripeRows: true,
		autoScroll: true,
		height: 400,
		enableHdMenu: false,		
		store: store_closed,
		viewConfig: {forceFit: true},
		selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		loadMask:'true',
		columns: [
			{ header: _('Issue'), dataIndex: 'id', width: 39, sortable: true, renderer: render_id },	
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
		Baseliner.addNewTab('/issue/view?id_rel=' + r.get('id') , 'Issue #' + r.get('id'),{},config_tabs );
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
			btn_labels,
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

	var check_categories_sm = new Ext.grid.CheckboxSelectionModel({
		singleSelect: false,
		sortable: false,
		checkOnly: true,
	});
	
	var grid_categories = new Ext.grid.GridPanel({
		region : 'north',
		title : _('Categories'),
		autoScroll: true,
		sm: check_categories_sm,
		split : true,
		collapsible : true,
		header: true,
		stripeRows: true,
		autoScroll: true,
		autoHeight: true,
		enableHdMenu: false,
		store: store_category,
		viewConfig: {forceFit: true},
		selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		loadMask:'true',
		columns: [
			{ hidden: true, dataIndex:'id' },
			check_categories_sm,
			{ header: _('Category'), dataIndex: 'name', width:50, sortable: false },
			{ header: _('Description'), dataIndex: 'description', sortable: false },	
		],
		autoSizeColumns: true,
		deferredRender:true,	
		tbar: [ 
				btn_add_category,
				btn_edit_category,
				btn_delete_category,
				'->'
		]		
	});	
	
	grid_categories.on('cellclick', function(grid, rowIndex, columnIndex, e) {
		if(columnIndex == 1){
			var categories_checked = getCategories();
			var labels_checked = getLabels();
			filtrar_issues(labels_checked, categories_checked);
			init_buttons_category('enable');
		}
	});
	
	grid_categories.on('headerclick', function(grid, columnIndex, e) {
		if(columnIndex == 1){
			var categories_checked = getCategories();
			var labels_checked = getLabels();
			filtrar_issues(labels_checked, categories_checked);
			init_buttons_category('enable');
		}
	});	

	var btn_add_label = new Ext.Toolbar.Button({
			id: 'btn_add_label',
			text: _('New'),
			icon:'/static/images/icons/add.gif',
			cls: 'x-btn-text-icon',
			handler: function() {
				if(label_box.getValue() != ''){
					Baseliner.ajaxEval( '/issue/update_label?action=add',{ label: label_box.getValue(), color: color_lbl},
						function(response) {
							if ( response.success ) {
								store_label.load();
								Baseliner.message( _('Success'), response.msg );
							} else {
								//Baseliner.message( _('ERROR'), response.msg );
								Ext.Msg.show({
									title: _('Information'), 
									msg: response.msg , 
									buttons: Ext.Msg.OK, 
									icon: Ext.Msg.INFO
								}); 	
							}
						}
					);
				}
			}
	});
	
	var btn_edit_label = new Ext.Toolbar.Button({
		id: 'btn_edit_label',
		text: _('Edit'),
		icon:'/static/images/icons/edit.gif',
		cls: 'x-btn-text-icon',
		disabled: true,
		handler: function() {
		var sm = grid_labels.getSelectionModel();
			if (sm.hasSelection()) {
				var sel = sm.getSelected();
				add_edit_label(sel);
			} else {
				Baseliner.message( _('ERROR'), _('Select at least one row'));    
			};
		}
	});

	var btn_delete_label = new Ext.Toolbar.Button({
		id: 'btn_delete_label',
		text: _('Delete'),
		icon:'/static/images/icons/delete.gif',
		cls: 'x-btn-text-icon',
		disabled: true,
		handler: function() {
			var labels_checked = getLabels();
			Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the labels selected?'), 
			function(btn){ 
				if(btn=='yes') {
					Baseliner.ajaxEval( '/issue/update_label?action=delete',{ idslabel: labels_checked },
						function(response) {
							if ( response.success ) {
								//grid_labels.getStore().remove(sel);
								Baseliner.message( _('Success'), response.msg );
								init_buttons_label('disable');
								store_label.load();
								var categories_checked = getCategories();
								filtrar_issues(null, categories_checked);
							} else {
								Baseliner.message( _('ERROR'), response.msg );
							}
						}
					
					);
				}
			} );
		}
	});

	var color_lbl = '#000000';
	var color_label = new Ext.form.TextField({
		id:'color_label',
		width: 25,
		readOnly: true,
		style:'background:#000000'
	});
	
	var colorMenu = new Ext.menu.ColorMenu({
		handler: function(cm, color) {
		  eval("Ext.get('color_label').setStyle('background','#" + color + "')");
		  color_lbl = '#' + color ;
		}
	});

	var blank_image = new Ext.BoxComponent({autoEl: {tag: 'img', src: Ext.BLANK_IMAGE_URL}});
	
	var label_box = new Ext.form.TextField({ width: '120', enableKeyEvents: true });
    label_box.on('specialkey', function(f, e){
        if(e.getKey() == e.ENTER){
			if(f.getValue() != ''){
				Baseliner.ajaxEval( '/issue/update_label?action=add',{ label: label_box.getValue(), color: color_lbl},
					function(response) {
						if ( response.success ) {
							store_label.load();
							Baseliner.message( _('Success'), response.msg );
							//init_buttons('disable');
						} else {
							//Baseliner.message( _('ERROR'), response.msg );
							Ext.Msg.show({
								title: _('Information'), 
								msg: response.msg , 
								buttons: Ext.Msg.OK, 
								icon: Ext.Msg.INFO
							});
						}
					}
				
				);
			}
        }
    });
	
	var tb = new Ext.Toolbar({
		items: [{
				text: 	_('Pick a Color'),
				menu: 	colorMenu
				},
				color_label,
				blank_image,
				label_box,
				btn_add_label,
				btn_delete_label
		]
	});

	
	var render_color = function(value,metadata,rec,rowIndex,colIndex,store) {
		return "<div width='15' style='border:1px solid #cccccc;background-color:" + value + "'>&nbsp;</div>" ;
	};	

	
	var check_labels_sm = new Ext.grid.CheckboxSelectionModel({
		singleSelect: false,
		sortable: false,
		checkOnly: true,
	});

	
	var grid_labels = new Ext.grid.GridPanel({
		region : 'center',
		title : _('Labels'),
		sm: check_labels_sm,
		autoScroll: true,
		split : true,
		collapsible : true,
		header: true,
		stripeRows: true,
		autoScroll: true,
		autoHeight: true,
		enableHdMenu: false,
		store: store_label,
		viewConfig: {forceFit: true},
		selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		loadMask:'true',
		columns: [
			{ hidden: true, dataIndex:'id' },
			check_labels_sm,
			{ header: _('Color'), dataIndex: 'color', width:15, sortable: false, renderer: render_color },
			{ header: _('Label'), dataIndex: 'name', sortable: false },
			{ hidden: true, dataIndex:'active' }
		],
		autoSizeColumns: true,
		deferredRender:true,
		tbar: tb
	});

	function getCategories(){
		var categories_checked = new Array();
		check_categories_sm.each(function(rec){
			categories_checked.push(rec.get('id'));
		});
		return categories_checked
	}
	
	function getLabels(){
		var labels_checked = new Array();
		check_labels_sm.each(function(rec){
			labels_checked.push(rec.get('id'));
		});
		return labels_checked
	}
	
	function filtrar_issues(labels_checked, categories_checked){
		var query_id = '<% $c->stash->{query_id} %>';
		store_opened.load({params:{start:0 , limit: ps, filter:'O', query_id: '<% $c->stash->{query_id} %>', labels: labels_checked, categories: categories_checked}});
		store_closed.load({params:{start:0 , limit: ps, filter:'C', labels: labels_checked, categories: categories_checked}});		
	};

	grid_labels.on('cellclick', function(grid, rowIndex, columnIndex, e) {
		if(columnIndex == 1){
			var labels_checked = getLabels();
			var categories_checked = getCategories();
			filtrar_issues(labels_checked, categories_checked);
			init_buttons_label('enable');
		}
	});
	
	grid_labels.on('headerclick', function(grid, columnIndex, e) {
		if(columnIndex == 1){
			var labels_checked = getLabels();
			var categories_checked = getCategories();
			filtrar_issues(labels_checked, categories_checked);
			init_buttons_label('enable');
		}
	});

	var panel = new Ext.Panel({
		layout : "border",
		items : [ config_tabs,   
				{
					region : 'east',
					split: true,
					width: 350,
					minSize: 100,
					maxSize: 350,				
					items: [
							grid_categories,
							grid_labels
					]
				}
		]
	});
	
	var query_id = '<% $c->stash->{query_id} %>';
	store_opened.load({params:{start:0 , limit: ps, filter:'O', query_id: '<% $c->stash->{query_id} %>'}});
	store_closed.load({params:{start:0 , limit: ps, filter:'C'}});
	store_category.load();
	store_label.load();
	
	return panel;
})();




