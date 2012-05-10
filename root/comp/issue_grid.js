<%perl>
    my $id = _nowstamp;
</%perl>
(function(){
	<& /comp/search_field.mas &>
	var ps = 100; //page_size

	var store_opened = new Ext.data.JsonStore({
		root: 'data' , 
		remoteSort: true,
		totalProperty:"totalCount", 
		url: '/issue/list',
		fields: [ 
			{  name: 'id' },
			{  name: 'title' },
			{  name: 'description' },
			{  name: 'created_on' },
			{  name: 'created_by' },
			{  name: 'numcomment' },
			{  name: 'category' },
			{  name: 'namecategory' },
			{  name: 'projects' },
			{  name: 'labels' },
			{  name: 'status' },
			{  name: 'priority' },
			{  name: 'response_time_min' },
			{  name: 'expr_response_time' },
			{  name: 'deadline_min' },
			{  name: 'expr_deadline' }
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
		url: '/issue/list',
		fields: [ 
			{  name: 'id' },
			{  name: 'title' },
			{  name: 'description' },
			{  name: 'created_on' },		
			{  name: 'created_by' },
			{  name: 'numcomment' },
			{  name: 'category' },
			{  name: 'namecategory' },
			{  name: 'projects' },			
			{  name: 'labels' },
			{  name: 'status' },
			{  name: 'priority' },
			{  name: 'response_time_min' },
			{  name: 'expr_response_time' },
			{  name: 'deadline_min' },
			{  name: 'expr_deadline' }
			
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
		baseParams:{cmb:'category'},
		totalProperty:"totalCount", 
		url: '/issue/list_category',
		fields: [ 
			{  name: 'id' },
			{  name: 'name' },
			{  name: 'description' },
			{  name: 'statuses' }
		]
	});
	
	var store_category_status = new Ext.data.JsonStore({
		root: 'data' , 
		remoteSort: true,
		totalProperty:"totalCount", 
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
		url: '/issue/list_label',
		fields: [ 
			{  name: 'id' },
			{  name: 'name' },
			{  name: 'color' }
		]
	});
	
	var store_priority = new Ext.data.JsonStore({
		root: 'data' , 
		remoteSort: true,
		totalProperty:"totalCount", 
		url: '/issue/list_priority',
		fields: [ 
			{  name: 'id' },
			{  name: 'name' },
			{  name: 'response_time_min' },
			{  name: 'expr_response_time' },
			{  name: 'deadline_min' },
			{  name: 'expr_deadline' }			
		]
	});	
	
	var rt = Ext.data.Record.create([
		{name: 'id_project'},
		{name: 'project'}
	]);
	
	var store_project = new Ext.data.Store({
		// explicitly create reader
		reader: new Ext.data.ArrayReader(
			{
				idIndex: 0  // id for each record will be the first element
			},
			rt // recordType
		)
	});
	
	
	var store_status = new Ext.data.JsonStore({
		root: 'data' , 
		remoteSort: true,
		totalProperty:"totalCount", 
		url: '/issue/list_status',
		fields: [ 
			{  name: 'id' },
			{  name: 'name' },
			{  name: 'description' }
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

	var init_buttons_status = function(action) {
		eval('btn_edit_status.' + action + '()');		
		eval('btn_delete_status.' + action + '()');
	}
	
	var init_buttons_priority = function(action) {
		eval('btn_edit_priority.' + action + '()');		
		eval('btn_delete_priority.' + action + '()');
	}	

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
	
	var btn_labels = new Ext.Toolbar.Button({
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
		text: _('Comment'),
		icon:'/static/images/icons/comment_new.gif',
		cls: 'x-btn-text-icon',
		disabled: true,
		handler: function() {
			add_comment();
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
			emptyText: 'select a category',
			triggerAction: 'all',
			fieldLabel: _('Category'),
			name: 'category',
			hiddenName: 'category',
			displayField: 'name',
			valueField: 'id',
			store: store_category,
			allowBlank: false,
			listeners:{
				'select': function(cmd, rec, idx){
					statusCbx = Ext.getCmp('status-combo_<%$id%>');
					statusCbx.clearValue();
					statusCbx.store.load({
						params:{ 'categoryId': this.getValue() }
					});
					statusCbx.enable();
				}
			}
		});
		
		var combo_status = new Ext.form.ComboBox({
			mode: 'local',
			id: 'status-combo_<%$id%>',
			forceSelection: true,
			triggerAction: 'all',
			emptyText: 'select a status',
			fieldLabel: _('Issues: Status'),
			name: 'status',
			hiddenName: 'status',
			displayField: 'name',
			valueField: 'id',
			disabled: true,
			store: store_category_status
		});		
		
		var combo_priority = new Ext.form.ComboBox({
			mode: 'local',
			forceSelection: true,
			emptyText: 'select a priority',
			triggerAction: 'all',
			fieldLabel: _('Priority'),
			name: 'priority',
			hiddenName: 'priority',
			displayField: 'name',
			valueField: 'id',
			store: store_priority,
			listeners:{
				'select': function(cmd, rec, idx){
					var ff = form_issue.getForm();
					ff.findField("txt_rsptime_expr_min").setValue(rec.data.expr_response_time + '#' + rec.data.response_time_min);
					var expr = rec.data.expr_response_time.split(':');
					var str_expr = '';
					for(i=0; i < expr.length; i++)
					{
						if (expr[i].length == 2 && expr[i].substr(0,1) == '0'){
							continue;
						}else{
							str_expr += expr[i] + ' ';
						}
					}
					ff.findField("txtrpstime").setValue(str_expr);
					
					ff.findField("txt_deadline_expr_min").setValue(rec.data.expr_deadline + '#' + rec.data.deadline_min);
					expr = rec.data.expr_deadline.split(':');
					var str_expr = '';
					for(i=0; i < expr.length; i++)
					{
						if (expr[i].length == 2 && expr[i].substr(0,1) == '0'){
							continue;
						}else{
							str_expr += expr[i] + ' ';
						}
					}					
					ff.findField("txtdeadline").setValue(str_expr);

				}
			}			
		});
		
		var show_projects = function(rec) {
			var win_project;
			var title = 'Projects';

			function getProjects(names_checked){
				var projects_checked = new Array();
				check_ast_projects_sm.each(function(rec){
					projects_checked.push(rec.get('id_project'));
					names_checked.push(rec.get('project'));
				});
				return projects_checked
			}


			var btn_cerrar_projects = new Ext.Toolbar.Button({
				icon:'/static/images/icons/door_out.png',
				cls: 'x-btn-text-icon',
				text: _('Close'),
				handler: function() {
					win_project.close();
				}
			});
			
			var btn_grabar_projects = new Ext.Toolbar.Button({
				icon:'/static/images/icons/database_save.png',
				cls: 'x-btn-text-icon',
				text: _('Save'),
				handler: function(){
					var names_checked = new Array();
					var projects_checked = getProjects(names_checked);
					var form = form_issue.getForm();
					var projects = '';
					if(names_checked){
						for(i=0;i<names_checked.length;i++){
							projects = projects ? projects + ',' + names_checked[i]: names_checked[i];
						}
						ff.findField("txtprojects").setValue(projects);						
					}
					
					Baseliner.ajaxEval( '/issue/unassign_projects',{ idissue: rec.data.id, idsproject: projects_checked },
						function(response) {
							if ( response.success ) {
								Baseliner.message( _('Success'), response.msg );
								var categories_checked = getCategories();
								var labels_checked = getLabels();
								form.findField("id").setValue(rec.data.id);
								filtrar_issues(labels_checked, categories_checked);								
							} else {
								Baseliner.message( _('ERROR'), response.msg );
							}
						}
					);
				}
			});
	
			var check_ast_projects_sm = new Ext.grid.CheckboxSelectionModel({
				singleSelect: false,
				sortable: false,
				checkOnly: true
			});
		
			
			var grid_ast_projects = new Ext.grid.GridPanel({
				title : _('Projects'),
				sm: check_ast_projects_sm,
				autoScroll: true,
				header: false,
				stripeRows: true,
				autoScroll: true,
				height: 300,
				enableHdMenu: false,
				store: store_project,
				viewConfig: {forceFit: true},
				selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
				loadMask:'true',
				columns: [
					{ hidden: true, dataIndex:'id_project' },
					check_ast_projects_sm,
					{ header: _('Project'), dataIndex: 'project', sortable: false }
				],
				autoSizeColumns: true,
				deferredRender:false,
				bbar: [
					btn_grabar_projects,
					btn_cerrar_projects
				],
				listeners: {		
					viewready: function() {
						var me = this;
						var myDatas = [];
						var recs = [];
						if(rec.data.projects){
							for(i=0;i<rec.data.projects.length;i++){
								var myData = new Array();
								myData[0] = rec.data.projects[i].id_project;
								myData[1] = rec.data.projects[i].project;
								myDatas.push(myData);
								recs.push(i);
							}
						}
						store_project.loadData(myDatas);
						me.getSelectionModel().selectRows(recs);
					}
				}		
			});
			
			//Ext.util.Observable.capture(grid_ast_labels, console.info);
		
			win_project = new Ext.Window({
				title: _(title),
				width: 400,
				modal: true,
				autoHeight: true,
				items: grid_ast_projects
			});
			
			win_project.show();
		};
		
		var btn_unassign_project = new Ext.Toolbar.Button({
			text: _('Unassign projects'),
			handler: function() {
				show_projects(rec);
			}
		});		
		
		var form_issue = new Ext.FormPanel({
			frame: true,
			url:'/issue/update',
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
			defaults: { anchor:'100%'},
			items: [
				{ xtype: 'hidden', name: 'id', value: -1 },
				{
				    xtype:'textfield',
				    fieldLabel: _('Title'),
				    name: 'title',
				    allowBlank: false
				},
				combo_category,
				combo_status,
				{
				// column layout with 2 columns
				layout:'column'
				,defaults:{
					layout:'form'
					,border:false
					,xtype:'panel'
					,bodyStyle:'padding:0 10px 0 0'
				}
				,items:[{
					// left column
					columnWidth:0.33,
					defaults:{anchor:'100%'}
					,items:[
						combo_priority
					]
					},
					{
					columnWidth:0.33,
					// right column
					defaults:{anchor:'100%'},
					items:[
						{
							xtype:'textfield',
							fieldLabel: _('Response time'),
							name: 'txtrpstime',
							readOnly: true
						}
					]
					},
					{
					columnWidth:0.33,
					// right column
					defaults:{anchor:'100%'},
					items:[
						{
							xtype:'textfield',
							fieldLabel: _('Resolution time'),
							name: 'txtdeadline',
							readOnly: true
						}
					]
					}					
				]
				},
				{ xtype: 'hidden', name: 'txt_rsptime_expr_min', value: -1 },
				{ xtype: 'hidden', name: 'txt_deadline_expr_min', value: -1 },
				{
				// column layout with 2 columns
				layout:'column'
				,defaults:{
					layout:'form'
					,border:false
					,xtype:'panel'
					,bodyStyle:'padding:0 2px 0 0'
				}
				,items:[{
					// left column
					columnWidth:0.82,
					defaults:{anchor:'100%'}
					,items:[
						{
							xtype:'textfield',
							fieldLabel: _('Projects'),
							name: 'txtprojects',
							readOnly: true
						}
					]
					},
					{
					columnWidth:0.18,
					// right column
					defaults:{anchor:'100%'},
					items:[
						btn_unassign_project
					]
					}
				]
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
			
			//combo_category.setValue(rec.data.key);
			//combo_status.setValue(rec.data.key);
			alert(rec.data.status);
			
			
			var projects = '';
			if(rec.data.projects){
				for(i=0;i<rec.data.projects.length;i++){
					projects = projects ? projects + ',' + rec.data.projects[i].project: rec.data.projects[i].project;
				}
				ff.findField("txtprojects").setValue(projects);
			}			
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
						var text = form.findField("text").getValue();
						var obj_tab = Ext.getCmp('tabs_issues_<%$id%>');
						var obj_tab_active = obj_tab.getActiveTab();
						var title = obj_tab_active.title;
						cad = title.split('#');
						var action = cad[1];
						if (form.isValid()) {
							form.submit({
								params: {action: action},
								success: function(f,a){
									Baseliner.message(_('Success'), a.result.msg );
									win.close();
									myBR = new Ext.Element(document.createElement('br'));
									myH3 = new Ext.Element(document.createElement('h3'));
									myH3.dom.innerHTML = 'Creada por ' + a.result.data.created_by + ', ' + a.result.data.created_on
									myH3.addClass('separacion-comment');
									myDiv = new Ext.Element(document.createElement('div'));
									myP = new Ext.Element(document.createElement('p'));
									myP.dom.innerHTML = text;
									myP.addClass('triangle-border');
									myDiv.appendChild(myP);
									myDiv.appendChild(myH3);
									myDiv.addClass('comment');
									div = Ext.get('comments');
									div.insertFirst(myDiv);
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

	function returnOpposite(hexcolor) {
		var r = parseInt(hexcolor.substr(0,2),16);
		var g = parseInt(hexcolor.substr(2,2),16);
		var b = parseInt(hexcolor.substr(4,2),16);
		var yiq = ((r*299)+(g*587)+(b*114))/1000;
		return (yiq >= 128) ? '000000' : 'FFFFFF';
	}

	var render_title = function(value,metadata,rec,rowIndex,colIndex,store) {
		var tag_comment_html;
		var tag_color_html;
		tag_color_html = '';
		tag_project_html = '';
		if(rec.data.labels){
			for(i=0;i<rec.data.labels.length;i++){
				tag_color_html = tag_color_html + "<span style='float:left;border:1px solid #cccccc;padding:2px 8px 2px 8px;color:#" + returnOpposite(rec.data.labels[i].color) + ";background-color:#" + rec.data.labels[i].color + "'><b>" + rec.data.labels[i].name + "</b></span>";
			}
		}
		return "<div style='font-weight:bold; font-size: 14px;' >" + value + "</div><br><div><font color='808080'>by </font><b>" + rec.data.created_by + "</b> <font color='808080'>" + rec.data.created_on + "</font ></div>" + tag_color_html + tag_project_html;
	};
	
	var render_comment = function(value,metadata,rec,rowIndex,colIndex,store) {
		var tag_comment_html;
		tag_comment_html='';
		if(rec.data.numcomment){
			tag_comment_html = "<span style='color: #808080'><img border=0 src='/static/images/icons/comment_blue.gif' /> " + rec.data.numcomment + " comments</span>";
		}		
		return tag_comment_html;
	};
	
	var render_project = function(value,metadata,rec,rowIndex,colIndex,store){
		if(rec.data.projects){
			for(i=0;i<rec.data.projects.length;i++){
				tag_project_html = tag_project_html ? tag_project_html + ',' + rec.data.projects[i].project: rec.data.projects[i].project;
			}
		}
		return tag_project_html;
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
			{ header: _('Projects'), dataIndex: 'projects', width: 60, renderer: render_project },
			{ header: _('Category'), dataIndex: 'namecategory', width: 50, sortable: true },
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
		Baseliner.addNewTab('/issue/view?id_rel=' + r.get('id') , _('Issue') + ' #' + r.get('id'),{},config_tabs );
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
					var swSave = true;
					var projects = row.get('projects');
					if( typeof projects != 'object' ) projects = new Array();
					for (i=0;i<projects.length;i++) {
						if(projects[i].project == data.project){
							swSave = false;
							break;
						}
					}

					//if( projects.name.indexOf( data.project ) == -1 ) {
					if( swSave ) {
						row.beginEdit();
						projects.push( data );
						row.set('projects', projects );
						row.endEdit();
						row.commit();
						
						Baseliner.ajaxEval( '/issue/update_project',{ id_project: data.id_project, id_issue: row.get('id') },
							function(response) {
								if ( response.success ) {
									//store_label.load();
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
			{ header: _('Projects'), dataIndex: 'projects', width: 60, renderer: render_project },
			{ header: _('Category'), dataIndex: 'namecategory', width: 50, sortable: true },
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
		Baseliner.addNewTab('/issue/view?id_rel=' + r.get('id') , _('Issue') + (' #') + r.get('id'),{},config_tabs );
	});

	var search_field = new Ext.app.SearchField({
				store: store_opened,
				params: {start: 0, limit: ps},
				emptyText: _('<Enter your search string>')
	});

	var config_tabs = new Ext.TabPanel({
		id: 'tabs_issues_<%$id%>',
		region: 'center',
		layoutOnTabChange:true,
		deferredRender: false,
		defaults: {layout:'fit'},
		tbar: 	[ _('Search') + ' ', ' ',
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
				  id: 'open_tab_<%$id%>',
				  xtype : 'panel',
				  title : _('Open'),
				  items: [ grid_opened ]
				},
				{
				  id: 'closed_tab_<%$id%>',
				  xtype : 'panel',
				  title : _('Closed'),
				  items: [ grid_closed ]
				}		 
		],
		activeTab : 0,
		listeners: {
		    'tabchange': function(tabPanel, tab){
				if(tab.id == 'open_tab_<%$id%>'){
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
					if(tab.id == 'closed_tab_<%$id%>'){
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

	//Para cuando se envia el formulario no coja el atributo emptytext de los textfields
	Ext.form.Action.prototype.constructor = Ext.form.Action.prototype.constructor.createSequence(function() {
		Ext.applyIf(this.options, {
		submitEmptyText:false
		});
	});
		
	var add_edit_status = function(rec) {
		var win;
		var title = 'Create status';
		
        var ta = new Ext.form.TextArea({
            name: 'description',
            height: 130,
            enableKeyEvents: true,
            fieldLabel: _('Description'),
            emptyText: _('A brief description of the status')
        });		
		
	
		var form_status = new Ext.FormPanel({
			frame: true,
			url:'/issue/update_status',
			labelAlign: 'top',
			bodyStyle:'padding:10px 10px 0',
			buttons: [
					{
						text: _('Accept'),
						type: 'submit',
						handler: function() {
							var form = form_status.getForm();
							var action = form.getValues()['id'] >= 0 ? 'update' : 'add';
							
							if (form.isValid()) {
								form.submit({
									params: {action: action},
									success: function(f,a){
										Baseliner.message(_('Success'), a.result.msg );
										form.findField("id").setValue(a.result.status_id);
										store_status.load();
										win.setTitle(_('Edit status'));
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
				{ xtype:'textfield', name:'name', fieldLabel:_('Issues: Status'), allowBlank:false, emptyText:_('Name of status') },
				ta
			]
		});

		if(rec){
			var ff = form_status.getForm();
			ff.loadRecord( rec );
			title = 'Edit status';
		}
		
		win = new Ext.Window({
			title: _(title),
			width: 400,
			autoHeight: true,
			items: form_status
		});
		win.show();		
	};
	
	var btn_add_status = new Ext.Toolbar.Button({
		text: _('New'),
		icon:'/static/images/icons/add.gif',
		cls: 'x-btn-text-icon',
		handler: function() {
					add_edit_status();
		}
	});
	
	var btn_edit_status = new Ext.Toolbar.Button({
		text: _('Edit'),
		icon:'/static/images/icons/edit.gif',
		cls: 'x-btn-text-icon',
		disabled: true,
		handler: function() {
			var sm = grid_status.getSelectionModel();
			if (sm.hasSelection()) {
				var sel = sm.getSelected();
				add_edit_status(sel);
			} else {
				Baseliner.message( _('ERROR'), _('Select at least one row'));    
			};
		}
	});

	var btn_delete_status = new Ext.Toolbar.Button({
		text: _('Delete'),
		icon:'/static/images/icons/delete.gif',
		cls: 'x-btn-text-icon',
		disabled: true,
		handler: function() {
			var statuses_checked = getStatuses();
			Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the statuses selected?'), 
			function(btn){ 
				if(btn=='yes') {
					Baseliner.ajaxEval( '/issue/update_status?action=delete',{ idsstatus: statuses_checked },
						function(response) {
							if ( response.success ) {
								Baseliner.message( _('Success'), response.msg );
								init_buttons_status('disable');
								store_status.load();
								var labels_checked = getLabels();
								var categories_checked = getCategories();
								filtrar_issues(labels_checked, categories_checked);
							} else {
								Baseliner.message( _('ERROR'), response.msg );
							}
						}
					
					);
				}
			});
		}
	});	
	
	var check_status_sm = new Ext.grid.CheckboxSelectionModel({
		singleSelect: false,
		sortable: false,
		checkOnly: true
	});
	
	var grid_status = new Ext.grid.GridPanel({
		title : _('Issues: Statuses'),
		sm: check_status_sm,
		header: true,
		stripeRows: true,
		autoScroll: true,
		enableHdMenu: false,
		store: store_status,
		viewConfig: {forceFit: true},
		selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		loadMask:'true',
		columns: [
			{ hidden: true, dataIndex:'id' },
			check_status_sm,
			{ header: _('Issues: Status'), dataIndex: 'name', width:50, sortable: false },
			{ header: _('Description'), dataIndex: 'description', sortable: false }	
		],
		autoSizeColumns: true,
		deferredRender:true,	
		tbar: [ 
				btn_add_status,
				btn_edit_status,
				btn_delete_status,
				'->'
		]		
	});	

	grid_status.on('cellclick', function(grid, rowIndex, columnIndex, e) {
		if(columnIndex == 1){
			var statuses_checked = getStatuses();
			var categories_checked = getCategories();
			var labels_checked = getLabels();
			filtrar_issues(labels_checked, categories_checked);
			if (statuses_checked.length == 1){
				init_buttons_status('enable');
			}else{
				if(statuses_checked.length == 0){
					init_buttons_status('disable');
				}else{
					btn_delete_status.enable();
					btn_edit_status.disable();
				}
			}			
		}
	});
	
	grid_status.on('headerclick', function(grid, columnIndex, e) {
		if(columnIndex == 1){
			var statuses_checked = getStatuses();
			var categories_checked = getCategories();
			var labels_checked = getLabels();
			filtrar_issues(labels_checked, categories_checked);
			if(statuses_checked.length == 0){
				init_buttons_status('disable');
			}else{
				btn_delete_status.enable();
				btn_edit_status.disable();
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
		
        var column1 = {
			xtype:'panel',
			columnWidth:0.50,
			layout:'form',
			defaults:{anchor:'100%'},
			items: [
				{ xtype: 'hidden', name: 'id', value: -1 },
				{ xtype:'textfield', name:'name', fieldLabel:_('Category'), allowBlank:false, emptyText:_('Name of category') },
				ta
			]
        };
		
		var check_category_status_sm = new Ext.grid.CheckboxSelectionModel({
			singleSelect: false,
			sortable: false,
			checkOnly: true
		});

		var grid_category_status = new Ext.grid.GridPanel({
			sm: check_category_status_sm,
			header: false,
			height: 157,
			stripeRows: true,
			autoScroll: true,
			enableHdMenu: false,
			store: store_status,
			viewConfig: {forceFit: true},
			selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
			loadMask:'true',
			columns: [
				{ hidden: true, dataIndex:'id' },
				check_category_status_sm,
				{ header: _('Issues: Status'), dataIndex: 'name', width:50, sortable: false },
				{ header: _('Description'), dataIndex: 'description', sortable: false }	
			],
			autoSizeColumns: true,
			deferredRender:true,
			listeners: {
				viewready: function() {
					var me = this;
					
					var datas = me.getStore();
					var recs = [];
					datas.each(function(row, index){
						if(rec.data.statuses){
							for(i=0;i<rec.data.statuses.length;i++){
								if(row.get('id') == rec.data.statuses[i]){
									recs.push(index);	
								}
							}
						}						
					});
					me.getSelectionModel().selectRows(recs);					
				
				}
			}	
			
		});			
		
        var column2 = {
           xtype:'panel',
		   defaults:{anchor:'98%'},
		   columnWidth:0.50,
           items: grid_category_status
        };		
		
		
		var form_category = new Ext.FormPanel({
			frame: true,
			url:'/issue/update_category',
            layout: {
                type: 'column',
                padding: '5'
            },			
			buttons: [
					{
						text: _('Accept'),
						type: 'submit',
						handler: function() {
							var form = form_category.getForm();
							var action = form.getValues()['id'] >= 0 ? 'update' : 'add';
							
							if (form.isValid()) {
								
								var statuses_checked = new Array();
								check_category_status_sm.each(function(rec){
									statuses_checked.push(rec.get('id'));
								});								
								
								
								form.submit({
									params: {action: action, idsstatus: statuses_checked},
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
			defaults: { bodyStyle:'padding:0 18px 0 0'},
			items: [
                column1,
                column2
			]			
		});

		if(rec){
			var ff = form_category.getForm();
			ff.loadRecord( rec );
			title = 'Edit category';
		}
		
		win = new Ext.Window({
			title: _(title),
			width: 700,
			autoHeight: true,
			items: form_category
		});
		win.show();		
	};


	var btn_add_category = new Ext.Toolbar.Button({
		text: _('New'),
		icon:'/static/images/icons/add.gif',
		cls: 'x-btn-text-icon',
		handler: function() {
					add_edit_category();
		}
	});
	
	var btn_edit_category = new Ext.Toolbar.Button({
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
		text: _('Delete'),
		icon:'/static/images/icons/delete.gif',
		cls: 'x-btn-text-icon',
		disabled: true,
		handler: function() {
			var categories_checked = getCategories();
			Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the categories selected?'), 
			function(btn){ 
				if(btn=='yes') {
					Baseliner.ajaxEval( '/issue/update_category?action=delete',{ idscategory: categories_checked },
						function(response) {
							if ( response.success ) {
								Baseliner.message( _('Success'), response.msg );
								init_buttons_category('disable');
								store_category.load();
								var labels_checked = getLabels();
								filtrar_issues(labels_checked, null);								
							} else {
								Baseliner.message( _('ERROR'), response.msg );
							}
						}
					
					);
				}
			});
		}
	});

	var check_categories_sm = new Ext.grid.CheckboxSelectionModel({
		singleSelect: false,
		sortable: false,
		checkOnly: true
	});
	
	var grid_categories = new Ext.grid.GridPanel({
		title : _('Categories'),
		sm: check_categories_sm,
		header: true,
		stripeRows: true,
		autoScroll: true,
		enableHdMenu: false,
		store: store_category,
		viewConfig: {forceFit: true},
		selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		loadMask:'true',
		columns: [
			{ hidden: true, dataIndex:'id' },
			check_categories_sm,
			{ header: _('Category'), dataIndex: 'name', width:50, sortable: false },
			{ header: _('Description'), dataIndex: 'description', sortable: false }	
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
			if (categories_checked.length == 1){
				init_buttons_category('enable');
			}else{
				if(categories_checked.length == 0){
					init_buttons_category('disable');
				}else{
					btn_delete_category.enable();
					btn_edit_category.disable();
				}
			}
		}
	});
	
	grid_categories.on('headerclick', function(grid, columnIndex, e) {
		if(columnIndex == 1){
			var categories_checked = getCategories();
			var labels_checked = getLabels();
			filtrar_issues(labels_checked, categories_checked);
			if(categories_checked.length == 0){
				init_buttons_category('disable');
			}else{
				btn_delete_category.enable();
				btn_edit_category.disable();
			}
		}
	});

	var btn_add_label = new Ext.Toolbar.Button({
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

	var color_lbl = '000000';
	var color_label = new Ext.form.TextField({
		id:'color_label_<%$id%>',
		width: 25,
		readOnly: true,
		style:'background:#' + color_lbl
	});
	
	var colorMenu = new Ext.menu.ColorMenu({
		handler: function(cm, color) {
			eval("Ext.get('color_label_<%$id%>').setStyle('background','#" + color + "')");
			color_lbl = color ;
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
						} else {
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
		items: [
				{
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
		checkOnly: true
	});

	var grid_labels = new Ext.grid.GridPanel({
		title : _('Labels'),
		sm: check_labels_sm,
		autoScroll: true,
		header: true,
		stripeRows: true,
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
	
	function getStatuses(){
		var statuses_checked = new Array();
		check_status_sm.each(function(rec){
			statuses_checked.push(rec.get('id'));
		});
		return statuses_checked
	}	

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
	
	function getPriorities(){
		var priorities_checked = new Array();
		check_priorities_sm.each(function(rec){
			priorities_checked.push(rec.get('id'));
		});
		return priorities_checked
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


	var add_edit_priority = function(rec) {
		var win;
		var title = 'Create priority';
		
		function load_cbx(form, rec){
			var expr = rec.data.expr_response_time.split(':');
			for (i=0; i < expr.length; i++){
				var value = expr[i].substr(0, expr[i].length - 1);
				if(value != 0){
					var type = 	expr[i].substr(expr[i].length - 1, 1);
					switch (type){
						case 'M': 	form.findField("txt_rsptime_months").setValue(value);
									break;
						case 'W': 	form.findField("txt_rsptime_weeks").setValue(value);
									break;
						case 'D': 	form.findField("txt_rsptime_days").setValue(value);
									break;
						case 'h': 	form.findField("txt_rsptime_hours").setValue(value);
									break;
						case 'm': 	form.findField("txt_rsptime_minutes").setValue(value);
									break;
					}
				}
				
			}
			expr = rec.data.expr_deadline.split(':');
			for (i=0; i < expr.length; i++){
				var value = expr[i].substr(0, expr[i].length - 1);
				if(value != 0){
					var type = 	expr[i].substr(expr[i].length - 1, 1);
					switch (type){
						case 'M': 	form.findField("txt_deadline_months").setValue(value);
									break;
						case 'W': 	form.findField("txt_deadline_weeks").setValue(value);
									break;
						case 'D': 	form.findField("txt_deadline_days").setValue(value);
									break;
						case 'h': 	form.findField("txt_deadline_hours").setValue(value);
									break;
						case 'm': 	form.findField("txt_deadline_minutes").setValue(value);
									break;
					}
				}
				
			}
			
		}

		var txt_rsptime_months = new Ext.ux.form.Spinner({
			name: 'txt_rsptime_months',
			fieldLabel: _('Months'),
			strategy: new Ext.ux.form.Spinner.NumberStrategy({minValue:'1', maxValue:'12'})
		});
		
		var txt_rsptime_weeks = new Ext.ux.form.Spinner({
			name: 'txt_rsptime_weeks',
			fieldLabel: _('Weeks'),
			strategy: new Ext.ux.form.Spinner.NumberStrategy({minValue:'1', maxValue:'4'})
		});
		
		var txt_rsptime_days = new Ext.ux.form.Spinner({
			name: 'txt_rsptime_days',
			fieldLabel: _('Days'),
			strategy: new Ext.ux.form.Spinner.NumberStrategy({minValue:'1', maxValue:'31'})
		});
		
		var txt_rsptime_hours = new Ext.ux.form.Spinner({
			name: 'txt_rsptime_hours',
			fieldLabel: _('Hours'),
			strategy: new Ext.ux.form.Spinner.NumberStrategy({minValue:'1', maxValue:'24'})
		});
		
		var txt_rsptime_minutes = new Ext.ux.form.Spinner({
			name: 'txt_rsptime_minutes',
			fieldLabel: _('Minutes'),
			strategy: new Ext.ux.form.Spinner.NumberStrategy({minValue:'1', maxValue:'60'})
		});
		
		var txt_deadline_months = new Ext.ux.form.Spinner({
			name: 'txt_deadline_months',
			fieldLabel: _('Months'),
			strategy: new Ext.ux.form.Spinner.NumberStrategy({minValue:'1', maxValue:'12'})
		});
		
		var txt_deadline_weeks = new Ext.ux.form.Spinner({
			name: 'txt_deadline_weeks',
			fieldLabel: _('Weeks'),
			strategy: new Ext.ux.form.Spinner.NumberStrategy({minValue:'1', maxValue:'4'})
		});
		
		var txt_deadline_days = new Ext.ux.form.Spinner({
			name: 'txt_deadline_days',
			fieldLabel: _('Days'),
			strategy: new Ext.ux.form.Spinner.NumberStrategy({minValue:'1', maxValue:'31'})
		});		
		
		var txt_deadline_hours = new Ext.ux.form.Spinner({
			name: 'txt_deadline_hours',
			fieldLabel: _('Hours'),
			strategy: new Ext.ux.form.Spinner.NumberStrategy({minValue:'1', maxValue:'24'})
		});
		
		var txt_deadline_minutes = new Ext.ux.form.Spinner({
			name: 'txt_deadline_minutes',
			fieldLabel: _('Minutes'),
			strategy: new Ext.ux.form.Spinner.NumberStrategy({minValue:'1', maxValue:'60'})
		});		
		
		var form_priority = new Ext.FormPanel({
			frame: true,
			url:'/issue/update_priority',
			bodyStyle:'padding:10px 10px 0',
			buttons: [
					{
						text: _('Accept'),
						type: 'submit',
						handler: function() {
							var form = form_priority.getForm();
							var action = form.getValues()['id'] >= 0 ? 'update' : 'add';
							var rsptime = new Array();
							var deadline = new Array();
							
							var txt_rsptime_months =  form.findField("txt_rsptime_months").getValue();
							var txt_rsptime_weeks =  form.findField("txt_rsptime_weeks").getValue();
							var txt_rsptime_days =  form.findField("txt_rsptime_days").getValue();
							var txt_rsptime_hours =  form.findField("txt_rsptime_hours").getValue();
							var txt_rsptime_minutes =  form.findField("txt_rsptime_minutes").getValue();

							var txt_deadline_months =  form.findField("txt_deadline_months").getValue();
							var txt_deadline_weeks =  form.findField("txt_deadline_weeks").getValue();
							var txt_deadline_days =  form.findField("txt_deadline_days").getValue();
							var txt_deadline_hours =  form.findField("txt_deadline_hours").getValue();
							var txt_deadline_minutes =  form.findField("txt_deadline_minutes").getValue();
							
							txt_rsptime_months =  txt_rsptime_months ? txt_rsptime_months : 0;
							txt_rsptime_weeks =  txt_rsptime_weeks ? txt_rsptime_weeks : 0;
							txt_rsptime_days =  txt_rsptime_days ? txt_rsptime_days : 0;
							txt_rsptime_hours =  txt_rsptime_hours ? txt_rsptime_hours : 0;
							txt_rsptime_minutes =  txt_rsptime_minutes ? txt_rsptime_minutes : 0;

							txt_deadline_months =  txt_deadline_months ? txt_deadline_months : 0;
							txt_deadline_weeks =  txt_deadline_weeks ? txt_deadline_weeks : 0;
							txt_deadline_days =  txt_deadline_days ? txt_deadline_days : 0;
							txt_deadline_hours =  txt_deadline_hours ? txt_deadline_hours : 0;
							txt_deadline_minutes =  txt_deadline_minutes ? txt_deadline_minutes : 0;
							
							rsptime[0] = txt_rsptime_months + 'M:' + txt_rsptime_weeks + 'W:' + txt_rsptime_days + 'D:' + txt_rsptime_hours + 'h:' + txt_rsptime_minutes + 'm';
							rsptime[1] = (txt_rsptime_months * 31 * 24 * 60 * 60) + (txt_rsptime_weeks * 7 * 24 * 60 * 60) + (txt_rsptime_days * 24 * 60 * 60) + (txt_rsptime_hours * 60) + txt_rsptime_minutes;
							
							deadline[0] = txt_deadline_months + 'M:' + txt_deadline_weeks + 'W:' + txt_deadline_days + 'D:' + txt_deadline_hours + 'h:' + txt_deadline_minutes + 'm';
							deadline[1] = (txt_deadline_months * 31 * 24 * 60 * 60) + (txt_deadline_weeks * 7 * 24 * 60 * 60) + (txt_deadline_days * 24 * 60 * 60) + (txt_deadline_hours * 60) + txt_deadline_minutes;
							
							
							if (form.isValid()) {
								form.submit({
									params: {action: action, rsptime: rsptime, deadline: deadline},
									success: function(f,a){
										Baseliner.message(_('Success'), a.result.msg );
										form.findField("id").setValue(a.result.priority_id);
										store_priority.load();
										win.setTitle(_('Edit priority'));
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
				{ xtype:'textfield', name:'name', fieldLabel:_('Priority'), allowBlank:false, emptyText:_('Name of priority') },
				{
					// column layout with 2 columns
					layout:'column'
					,defaults:{
						columnWidth:0.5
						,layout:'form'
						,border:false
						,xtype:'panel'
						,bodyStyle:'padding:0 10px 0 0'
					}
					,items:[
							{
								// left column
								defaults:{anchor:'100%'}
								,items:[
										{
											xtype:'fieldset',
											title: 'Response time',
											autoHeight:true,
											defaults: {width: 40},
											defaultType: 'textfield',
											items :[
												txt_rsptime_months,
												txt_rsptime_weeks,
												txt_rsptime_days,
												txt_rsptime_hours,
												txt_rsptime_minutes
											]
										}
								]
							},
							{
								// right column
								defaults:{anchor:'100%'}
								,items:[
										{
											xtype:'fieldset',
											title: 'Deadline',
											autoHeight:true,
											defaults: {width: 40},
											defaultType: 'textfield',
											items :[
												txt_deadline_months,
												txt_deadline_weeks,
												txt_deadline_days,
												txt_deadline_hours,
												txt_deadline_minutes
											]
										}
								]
							}
					]
				}
			]
		});

		if(rec){
			var ff = form_priority.getForm();
			ff.loadRecord( rec );
			load_cbx(ff, rec);
			title = 'Edit priority';
		}
		
		win = new Ext.Window({
			title: _(title),
			width: 450,
			autoHeight: true,
			items: form_priority
		});
		win.show();		
	};

	var btn_add_priority = new Ext.Toolbar.Button({
		text: _('New'),
		icon:'/static/images/icons/add.gif',
		cls: 'x-btn-text-icon',
		handler: function() {
					add_edit_priority();
		}
	});
	
	var btn_edit_priority = new Ext.Toolbar.Button({
		text: _('Edit'),
		icon:'/static/images/icons/edit.gif',
		cls: 'x-btn-text-icon',
		disabled: true,
		handler: function() {
			var sm = grid_priority.getSelectionModel();
			if (sm.hasSelection()) {
				var sel = sm.getSelected();
				//load_cbx();
				add_edit_priority(sel);
			} else {
				Baseliner.message( _('ERROR'), _('Select at least one row'));    
			};
		}
	});


	var btn_delete_priority = new Ext.Toolbar.Button({
		text: _('Delete'),
		icon:'/static/images/icons/delete.gif',
		cls: 'x-btn-text-icon',
		disabled: true,
		handler: function() {
			var priorities_checked = getPriorities();
			Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the priorities selected?'), 
			function(btn){ 
				if(btn=='yes') {
					Baseliner.ajaxEval( '/issue/update_priority?action=delete',{ idspriority: priorities_checked },
						function(response) {
							if ( response.success ) {
								Baseliner.message( _('Success'), response.msg );
								init_buttons_priority('disable');
								store_priority.load();
								var labels_checked = getLabels();
								var categories_checked = getCategories();
								filtrar_issues(labels_checked, categories_checked);								
							} else {
								Baseliner.message( _('ERROR'), response.msg );
							}
						}
					
					);
				}
			});
		}
	});


	var show_expr = function(value,metadata,rec,rowIndex,colIndex,store) {
		var expr = value.split(':');
		var str_expr = '';
		for(i=0; i < expr.length; i++)
		{
			if (expr[i].length == 2 && expr[i].substr(0,1) == '0'){
				continue;
			}else{
				str_expr += expr[i] + ' ';
			}
		}
		return str_expr;
	};

	var check_priorities_sm = new Ext.grid.CheckboxSelectionModel({
		singleSelect: false,
		sortable: false,
		checkOnly: true
	});

	var grid_priority = new Ext.grid.GridPanel({
		title : _('Priorities'),
		sm: check_priorities_sm,
		autoScroll: true,
		header: true,
		stripeRows: true,
		enableHdMenu: false,
		store: store_priority,
		viewConfig: {forceFit: true},
		selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		loadMask:'true',
		columns: [
			{ hidden: true, dataIndex:'id' },
			check_priorities_sm,
			{ header: _('Priority'), dataIndex: 'name', width:50, sortable: true },
			{ header: _('Response time'), dataIndex: 'expr_response_time', sortable: false, renderer: show_expr },
			{ header: _('Deadline'), dataIndex: 'expr_deadline', sortable: false, renderer: show_expr }	
		],
		autoSizeColumns: true,
		deferredRender:true,	
		tbar: [ 
				btn_add_priority,
				btn_edit_priority,
				btn_delete_priority,
				'->'
		]	
	});
	
	grid_priority.on('cellclick', function(grid, rowIndex, columnIndex, e) {
		if(columnIndex == 1){
			var priorities_checked = getPriorities();
			var categories_checked = getCategories();
			var labels_checked = getLabels();
			filtrar_issues(labels_checked, categories_checked);
			if (priorities_checked.length == 1){
				init_buttons_priority('enable');
			}else{
				if(priorities_checked.length == 0){
					init_buttons_priority('disable');
				}else{
					btn_delete_priority.enable();
					btn_edit_priority.disable();
				}
			}			
		}
	});
	
	grid_priority.on('headerclick', function(grid, columnIndex, e) {
		if(columnIndex == 1){
			var priorities_checked = getPriorities();
			var categories_checked = getCategories();
			var labels_checked = getLabels();
			filtrar_issues(labels_checked, categories_checked);
			if(priorities_checked.length == 0){
				init_buttons_priority('disable');
			}else{
				btn_delete_priority.enable();
				btn_edit_priority.disable();
			}
		}
	});	

	var panel = new Ext.Panel({
		layout : "border",
		items : [ config_tabs,   
				{
					region : 'east',
					width: 350,
					layout:'accordion',
					split: true,
					collapsible: true,
					defaults: {collapsed : true},
					items: [
							grid_status,
							grid_categories,
							grid_labels,
							grid_priority
					]
				}
		]
	});
	
	var query_id = '<% $c->stash->{query_id} %>';
	store_opened.load({params:{start:0 , limit: ps, filter:'O', query_id: '<% $c->stash->{query_id} %>'}});
	store_closed.load({params:{start:0 , limit: ps, filter:'C'}});
	store_status.load();
	store_category.load();
	store_label.load();
	store_priority.load();
	
	return panel;
})
