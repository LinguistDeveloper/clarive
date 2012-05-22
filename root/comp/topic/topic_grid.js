<%perl>
    use Baseliner::Utils;
    my $id = _nowstamp;
</%perl>
(function(){
    <& /comp/search_field.mas &>
    var ps = 100; //page_size

    // Create store instances
    var store_category = new Baseliner.Topic.StoreCategory();
    var store_category_status = new Baseliner.Topic.StoreCategoryStatus();
    var store_priority = new Baseliner.Topic.StorePriority();
    var store_project = new Baseliner.Topic.StoreProject();
    var store_status = new Baseliner.Topic.StoreStatus();
    var store_label = new Baseliner.Topic.StoreLabel();
    var store_topics = new Baseliner.Topic.StoreList({
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
    //var store_closed = new Baseliner.Topic.StoreList({
    //        listeners: {
    //            'beforeload': function( obj, opt ) {
    //                obj.baseParams.filter = 'C';
    //                var labels_checked = getLabels();
    //                obj.baseParams.labels = labels_checked;
    //                var categories_checked = getCategories();
    //                obj.baseParams.categories = categories_checked;             
    //                }
    //            }           
    //});
    
    var init_buttons = function(action) {
        eval('btn_edit.' + action + '()');
        eval('btn_delete.' + action + '()');
        eval('btn_labels.' + action + '()');
        eval('btn_close.' + action + '()');
    }
    


    //var btn_add = new Ext.Toolbar.Button({
    //    text: _('New'),
    //    icon:'/static/images/icons/add.gif',
    //    cls: 'x-btn-text-icon',
    //    handler: function() {
    //        add_edit();
    //    }
    //});
    
    //var btn_edit = new Ext.Toolbar.Button({
    //    text: _('Edit'),
    //    icon:'/static/images/icons/edit.gif',
    //    cls: 'x-btn-text-icon',
    //    disabled: true,
    //    handler: function() {
    //    var sm = grid_opened.getSelectionModel();
    //        if (sm.hasSelection()) {
    //            var sel = sm.getSelected();
    //            add_edit(sel);
    //        } else {
    //            Baseliner.message( _('ERROR'), _('Select at least one row'));    
    //        };
    //    }
    //});
	
	var btn_add = new Baseliner.Grid.Buttons.Add({
		handler: function() {
			add_edit();
	    }		
	});
	
	var btn_edit = new Baseliner.Grid.Buttons.Edit({
		handler: function() {
			var sm = grid_topics.getSelectionModel();
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
            var sm = grid_topics.getSelectionModel();
            var sel = sm.getSelected();
            Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the topic') + ' <b>' + sel.data.id + '</b>?', 
				function(btn){ 
					if(btn=='yes') {
						Baseliner.ajaxEval( '/topic/update?action=delete',{ id: sel.data.id },
							function(response) {
								if ( response.success ) {
									grid_topics.getStore().remove(sel);
									Baseliner.message( _('Success'), response.msg );
									init_buttons('disable');
								} else {
									Baseliner.message( _('ERROR'), response.msg );
								}
							}
						
						);
					}
				}
			);
        }
	});
	


    //var btn_delete = new Ext.Toolbar.Button({
    //    text: _('Delete'),
    //    icon:'/static/images/icons/delete.gif',
    //    cls: 'x-btn-text-icon',
    //    disabled: true,
    //    handler: function() {
    //        var sm = grid_opened.getSelectionModel();
    //        var sel = sm.getSelected();
    //        Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the topic') + ' <b>' + sel.data.id + '</b>?', 
    //        function(btn){ 
    //            if(btn=='yes') {
    //                Baseliner.ajaxEval( '/topic/update?action=delete',{ id: sel.data.id },
    //                    function(response) {
    //                        if ( response.success ) {
    //                            grid_opened.getStore().remove(sel);
    //                            Baseliner.message( _('Success'), response.msg );
    //                            init_buttons('disable');
    //                        } else {
    //                            Baseliner.message( _('ERROR'), response.msg );
    //                        }
    //                    }
    //                
    //                );
    //            }
    //        } );
    //    }
    //});
    
    var btn_labels = new Ext.Toolbar.Button({
        text: _('Labels'),
        icon:'/static/images/icons/color_swatch.png',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
            var sm = grid_topics.getSelectionModel();
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
            var sm = grid_topics.getSelectionModel();
            var sel = sm.getSelected();
            Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to close the topic') + ' <b># ' + sel.data.id + '</b>?', 
            function(btn){ 
                if(btn=='yes') {
                    Baseliner.ajaxEval( '/topic/update?action=close',{ id: sel.data.id },
                        function(response) {
                            if ( response.success ) {
                                grid_topics.getStore().remove(sel);
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
        
		store_label.load();
			
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
                Baseliner.ajaxEval( '/topic/update_topiclabels',{ idtopic: rec.data.id, idslabel: labels_checked },
                    function(response) {
                        if ( response.success ) {
                            Baseliner.message( _('Success'), response.msg );
                            var labels_checked = getLabels();
                            filtrar_topics(labels_checked);
                            
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
        
        var title = 'Create topic';
        
        var combo_category = new Ext.form.ComboBox({
            mode: 'remote',
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
            fieldLabel: _('Topics: Status'),
            name: 'status',
            hiddenName: 'status',
            displayField: 'name',
            valueField: 'id',
            disabled: true,
            store: store_category_status
        });     
        
        function get_expr_response_time(row){
            var str_expr = '';
            var expr = row.data.expr_response_time.split(':');
            for(i=0; i < expr.length; i++)
            {
                if (expr[i].length == 2 && expr[i].substr(0,1) == '0'){
                    continue;
                }else{
                    str_expr += expr[i] + ' ';
                }
            }
            return str_expr;
        }
        
        function get_expr_deadline(row){
            var str_expr = '';
            var expr = row.data.expr_deadline.split(':');
            for(i=0; i < expr.length; i++)
            {
                if (expr[i].length == 2 && expr[i].substr(0,1) == '0'){
                    continue;
                }else{
                    str_expr += expr[i] + ' ';
                }
            }
            return str_expr;
        }
        
        function load_txt_values_priority(row){
            var ff = form_topic.getForm();
            var obj_rsp_expr_min = ff.findField("txt_rsptime_expr_min");
            var obj_rsp_time = ff.findField("txtrsptime");
            var obj_deadline_expr_min = ff.findField("txt_deadline_expr_min");
            var obj_deadline = ff.findField("txtdeadline");
            obj_rsp_expr_min.setValue('');
            obj_rsp_time.setValue('');
            obj_deadline_expr_min.setValue('');
            obj_deadline.setValue('');
            if(row.data.expr_response_time){
                obj_rsp_expr_min.setValue(row.data.expr_response_time + '#' + row.data.response_time_min);
                obj_rsp_time.setValue(get_expr_response_time(row));
            }
            if(row.data.expr_deadline){
                obj_deadline_expr_min.setValue(row.data.expr_deadline + '#' + row.data.deadline_min);
                obj_deadline.setValue(get_expr_deadline(row));
            }
        }
        
        var combo_priority = new Ext.form.ComboBox({
            mode: 'remote',
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
                    load_txt_values_priority(rec);
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
                    var form = form_topic.getForm();
                    var projects = '';
                    if(names_checked){
                        for(i=0;i<names_checked.length;i++){
                            projects = projects ? projects + ',' + names_checked[i]: names_checked[i];
                        }
                        ff.findField("txtprojects").setValue(projects);                     
                    }
                    
                    Baseliner.ajaxEval( '/topic/unassign_projects',{ idtopic: rec.data.id, idsproject: projects_checked },
                        function(response) {
                            if ( response.success ) {
                                Baseliner.message( _('Success'), response.msg );
                                var categories_checked = getCategories();
                                var labels_checked = getLabels();
                                form.findField("id").setValue(rec.data.id);
                                filtrar_topics(labels_checked, categories_checked);                             
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
            //text: _('Unassign projects'),
            text: _('projects'),
            handler: function() {
                show_projects(rec);
            }
        });
        
        var btn_unassign_roles = new Ext.Toolbar.Button({
            //text: _('Unassign projects'),
            text: _('roles'),
            handler: function() {
                show_projects(rec);
            }
        });         
        
        var form_topic = new Ext.FormPanel({
            frame: true,
            url:'/topic/update',
            bodyStyle:'padding:10px 10px 0',
            buttons: [
                {
                text: _('Accept'),
                type: 'submit',
                handler: function() {
                    var form = form_topic.getForm();
                    var action = form.getValues()['id'] >= 0 ? 'update' : 'add';
                    
                    if (form.isValid()) {
                           form.submit({
                           params: {action: action},
                           success: function(f,a){
                               Baseliner.message(_('Success'), a.result.msg );
                               form.findField("id").setValue(a.result.topic_id);
                               store_topics.load();
                               win.setTitle(_('Edit topic'));
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
                //combo_category,
                //combo_status,
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
                    columnWidth:0.50,
                    defaults:{anchor:'100%'}
                    ,items:[
                        combo_category
                    ]
                    },
                    {
                    columnWidth:0.50,
                    // right column
                    defaults:{anchor:'100%'},
                    items:[
                        combo_status
                    ]
                    }                   
                ]
                },              
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
                    columnWidth:0.40,
                    defaults:{anchor:'100%'}
                    ,items:[
                        combo_priority
                    ]
                    },
                    {
                    columnWidth:0.30,
                    // right column
                    defaults:{anchor:'100%'},
                    items:[
                        {
                            xtype:'textfield',
                            fieldLabel: _('Response'),
                            name: 'txtrsptime',
                            readOnly: true
                        }
                    ]
                    },
                    {
                    columnWidth:0.30,
                    // right column
                    defaults:{anchor:'100%'},
                    items:[
                        {
                            xtype:'textfield',
                            fieldLabel: _('Resolution'),
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
                    ,bodyStyle:'padding:0 10px 0 0'
                }
                ,items:[{
                    // left column
                    columnWidth:0.40,
                    defaults:{anchor:'100%'}
                    ,items:[
                        {
                            xtype:'textarea',
                            fieldLabel: _('Projects'),
                            name: 'txtprojects',
                            height: 100,
                            readOnly: true
                        }
                    ]
                    },
                    {
                    columnWidth:0.10,
                    // right column
                    defaults:{anchor:'100%'},
                    items:[
                        btn_unassign_project
                    ]
                    },
                    {
                    // left column
                    columnWidth:0.40,
                    defaults:{anchor:'100%'}
                    ,items:[
                        {
                            xtype:'textarea',
                            fieldLabel: _('Roles'),
                            name: 'txtroles',
                            height: 100,
                            readOnly: true
                        }
                    ]
                    },
                    {
                    columnWidth:0.10,
                    // right column
                    defaults:{anchor:'100%'},
                    items:[
                        btn_unassign_roles
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
            var ff = form_topic.getForm();
            ff.loadRecord( rec );
            load_txt_values_priority(rec);
            var projects = '';
            if(rec.data.projects){
                for(i=0;i<rec.data.projects.length;i++){
                    projects = projects ? projects + '\n' + rec.data.projects[i].project: rec.data.projects[i].project;
                }
                ff.findField("txtprojects").setValue(projects);
            }           
            title = 'Edit topic';
        }
        
        win = new Ext.Window({
            title: _(title),
            width: 700,
            autoHeight: true,
            items: form_topic
        });
        win.show();     
    };

    var add_comment = function() {
        var win;
        
        var blank_image = new Ext.BoxComponent({autoEl: {tag: 'img', src: Ext.BLANK_IMAGE_URL}, widht:10});
        
        var title = 'Create comment';
        
        var form_topic_comment = new Ext.FormPanel({
            frame: true,
            url:'/topic/viewdetail',
            labelAlign: 'top',
            bodyStyle:'padding:10px 10px 0',
            buttons: [
                {
                    text: _('Accept'),
                    type: 'submit',
                    handler: function() {
                        var form = form_topic_comment.getForm();
                        var text = form.findField("text").getValue();
                        var obj_tab = Ext.getCmp('tabs_topics_<%$id%>');
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
            items: form_topic_comment
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
		var date_created_on;
        tag_color_html = '';
        tag_project_html = '';
		date_created_on =  rec.data.created_on.dateFormat('M j, Y, g:i a');
		
        if(rec.data.labels){
            for(i=0;i<rec.data.labels.length;i++){
                tag_color_html = tag_color_html + "<div id='boot'><span class='badge' style='float:left;padding:2px 8px 2px 8px;color:#" + returnOpposite(rec.data.labels[i].color) + ";background-color:#" + rec.data.labels[i].color + "'>" + rec.data.labels[i].name + "</span></div>";
            }
        }
        return "<div style='font-weight:bold; font-size: 14px;' >" + value + "</div><br><div><b>" + date_created_on + "</b> <font color='808080'></br>by " + rec.data.created_by + "</font ></div>" + tag_color_html + tag_project_html;
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
                //tag_project_html = tag_project_html ? tag_project_html + ',' + rec.data.projects[i].project: rec.data.projects[i].project;
                tag_project_html = tag_project_html + "<div id='boot' class='alert' style='float:left'><button class='close' data-dismiss='alert'>×</button>" + rec.data.projects[i].project + "</div>";
            }
        }
        return tag_project_html;
    };

     var search_field = new Ext.app.SearchField({
                store: store_topics,
                params: {start: 0, limit: ps},
                emptyText: _('<Enter your search string>')
    });
 
    var grid_topics = new Ext.grid.GridPanel({
        title: _('Topics'),
        header: false,
        stripeRows: true,
        autoScroll: true,
        enableHdMenu: false,
        store: store_topics,
        enableDragDrop: true,
        viewConfig: {forceFit: true},
        selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
        loadMask:'true',
        columns: [
            { header: _('Topic'), dataIndex: 'id', width: 39, sortable: true, renderer: render_id },    
            { header: _('Title'), dataIndex: 'title', width: 250, sortable: true, renderer: render_title },
            { header: _('Comments'), dataIndex: 'numcomment', width: 60, sortable: true, renderer: render_comment },
            { header: _('Projects'), dataIndex: 'projects', width: 60, renderer: render_project },
            { header: _('Category'), dataIndex: 'namecategory', width: 50, sortable: true },
            { header: _('Description'), hidden: true, dataIndex: 'description' }
        ],
        tbar:   [ _('Search') + ' ', ' ',
                search_field,
                btn_add,
                btn_edit,
                btn_delete,
                btn_labels,
                '->',
                btn_comment,
                btn_close
        ], 		
        autoSizeColumns: true,
        deferredRender:true,
        bbar: new Ext.PagingToolbar({
            store: store_topics,
            pageSize: ps,
            displayInfo: true,
            displayMsg: _('Rows {0} - {1} of {2}'),
            emptyMsg: _('There are no rows available')
        })
    });
    
    grid_topics.on('rowclick', function(grid, rowIndex, columnIndex, e) {
        init_buttons('enable');
    });

    grid_topics.on("rowdblclick", function(grid, rowIndex, e ) {
        var r = grid.getStore().getAt(rowIndex);
        //Baseliner.addNewTab('/topic/view?id=' + r.get('id') , _('Topic') + ' #' + r.get('id'),{} );
        //Baseliner.addNewTabComp('/topic/view?id=' + r.get('id') , _('Topic') + ' #' + r.get('id'),{} );
        var title = _(r.get( 'namecategory' )) + ' #' + r.get('id');
        Baseliner.add_tabcomp('/topic/view?id=' + r.get('id') , title , { id: r.get('id'), title: title } );
    });
    
    grid_topics.on( 'render', function(){
        var el = grid_topics.getView().el.dom.childNodes[0].childNodes[1];
        var grid_topics_dt = new Ext.dd.DropTarget(el, {
            ddGroup: 'lifecycle_dd',
            copy: true,
            notifyDrop: function(dd, e, id) {
                var n = dd.dragData.node;
                var s = grid_topics.store;
                var add_node = function(node) {
                    var data = node.attributes.data;
                    // determine the row
                    var t = Ext.lib.Event.getTarget(e);
                    var rindex = grid_topics.getView().findRowIndex(t);
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
                        
                        Baseliner.ajaxEval( '/topic/update_project',{ id_project: data.id_project, id_topic: row.get('id') },
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

    //var grid_closed = new Ext.grid.GridPanel({
    //    title: _('Topics'),
    //    header: false,
    //    stripeRows: true,
    //    autoScroll: true,
    //    height: 400,
    //    enableHdMenu: false,        
    //    store: store_closed,
    //    viewConfig: {forceFit: true},
    //    selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
    //    loadMask:'true',
    //    columns: [
    //        { header: _('Topic'), dataIndex: 'id', width: 39, sortable: true, renderer: render_id },    
    //        { header: _('Title'), dataIndex: 'title', width: 250, sortable: true, renderer: render_title },
    //        { header: _('Comments'), dataIndex: 'numcomment', width: 60, sortable: true, renderer: render_comment },
    //        { header: _('Projects'), dataIndex: 'projects', width: 60, renderer: render_project },
    //        { header: _('Category'), dataIndex: 'namecategory', width: 50, sortable: true },
    //        { header: _('Description'), hidden: true, dataIndex: 'description' }
    //    ],
    //    autoSizeColumns: true,
    //    deferredRender:true,    
    //    bbar: new Ext.PagingToolbar({
    //        store: store_closed,
    //        pageSize: ps,
    //        displayInfo: true,
    //        displayMsg: _('Rows {0} - {1} of {2}'),
    //        emptyMsg: _('There are no rows available')
    //    })
    //});
    //
    //grid_closed.on("rowdblclick", function(grid, rowIndex, e ) {
    //    var r = grid.getStore().getAt(rowIndex);
    //    Baseliner.addNewTab('/topic/view?id=' + r.get('id') , _('Topic') + (' #') + r.get('id'),{},config_tabs );
    //});



    //var config_tabs = new Ext.TabPanel({
    //    id: 'tabs_topics_<%$id%>',
    //    region: 'center',
    //    layoutOnTabChange:true,
    //    deferredRender: false,
    //    defaults: {layout:'fit'},
    //    tbar:   [ _('Search') + ' ', ' ',
    //            search_field,
    //            btn_add,
    //            btn_edit,
    //            btn_delete,
    //            btn_labels,
    //            '->',
    //            btn_comment,
    //            btn_close
    //    ], 
    //    items : [
    //            {
    //              id: 'open_tab_<%$id%>',
    //              xtype : 'panel',
    //              title : _('Open'),
    //              items: [ grid_topics ]
    //            },
    //            {
    //              id: 'closed_tab_<%$id%>',
    //              xtype : 'panel',
    //              title : _('Closed'),
    //              items: [ grid_closed ]
    //            }        
    //    ],
    //    activeTab : 0,
    //    listeners: {
    //        'tabchange': function(tabPanel, tab){
    //            if(tab.id == 'open_tab_<%$id%>'){
    //                search_field.store = store_opened;
    //                var sm = grid_topics.getSelectionModel();
    //                var sel = sm.getSelected();
    //                if(sel){
    //                    btn_add.enable();
    //                    init_buttons('enable');
    //                }else{
    //                    init_buttons('disable');
    //                    btn_add.enable();
    //                }
    //                btn_comment.disable();
    //            }
    //            else{
    //                if(tab.id == 'closed_tab_<%$id%>'){
    //                    search_field.store = store_closed;
    //                    init_buttons('disable');
    //                    btn_add.disable();
    //                    btn_comment.disable();
    //                }
    //                else{
    //                    init_buttons('disable');
    //                    btn_add.disable();              
    //                    btn_comment.enable();
    //                }
    //            }
    //        }
    //    }       
    //});

   
    var check_status_sm = new Ext.grid.CheckboxSelectionModel({
        singleSelect: false,
        sortable: false,
        checkOnly: true
    });
    


    var check_categories_sm = new Ext.grid.CheckboxSelectionModel({
        singleSelect: false,
        sortable: false,
        checkOnly: true
    });
    
    
    var render_color = function(value,metadata,rec,rowIndex,colIndex,store) {
        return "<div width='15' style='border:1px solid #cccccc;background-color:" + value + "'>&nbsp;</div>" ;
    };  

    var check_labels_sm = new Ext.grid.CheckboxSelectionModel({
        singleSelect: false,
        sortable: false,
        checkOnly: true
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
    
    function filtrar_topics(labels_checked, categories_checked, statuses_checked, priorities_checked){
        var query_id = '<% $c->stash->{query_id} %>';
        store_topics.load({params:{start:0 , limit: ps, query_id: '<% $c->stash->{query_id} %>', labels: labels_checked, categories: categories_checked, statuses: statuses_checked, priorities: priorities_checked}});
		//store_topics.load({params:{start:0 , limit: ps, filter:'O', query_id: '<% $c->stash->{query_id} %>', labels: labels_checked, categories: categories_checked}});
        //store_closed.load({params:{start:0 , limit: ps, filter:'C', labels: labels_checked, categories: categories_checked}});      
    };


	var tree_filters = new Ext.tree.TreePanel({
		title: _('Available Filters'),
		dataUrl: "topic/filters_list",
		split: true,
		colapsible: true,
		useArrows: true,
		animate: true,
		autoScroll: true,
		rootVisible: false,
		root: new Ext.tree.AsyncTreeNode({
				text: 'Filters',
				expanded:true
			})
	});

	tree_filters.on('click', function(node, event){
		//alert('pasa');
	});
	
	tree_filters.on('checkchange', function(node, checked) {
		var labels_checked = new Array();
		var statuses_checked = new Array();
		var categories_checked = new Array();
		var priorities_checked = new Array();
		var type;
		selNodes = tree_filters.getChecked();
		Ext.each(selNodes, function(node){
			type = node.parentNode.attributes.id;
			switch (type){
				//Labels
				case 'L':  	labels_checked.push(node.attributes.id);
							break;
				//Statuses
				case 'S':   statuses_checked.push(node.attributes.id);
							break;
				//Categories
				case 'C':   categories_checked.push(node.attributes.id);
							break;
				//Priorities
				case 'P':   priorities_checked.push(node.attributes.id);
							break;
			}
		});
		filtrar_topics(labels_checked, categories_checked, statuses_checked, priorities_checked);
		
	});	
		
	tree_filters.getLoader();
		
    var panel = new Ext.Panel({
        layout : "border",
		defaults: {layout:'fit'},
        items : [
			 
					{
						region:'center',
						collapsible: false,
						items: [
							grid_topics
						]
				    },   
					{
						region : 'east',
						width: 350,
						split: true,
						collapsible: true,
						items: [
							tree_filters
	
						]
					}
        ]
    });
    
    var query_id = '<% $c->stash->{query_id} %>';
    store_topics.load({params:{start:0 , limit: ps, filter:'O', query_id: '<% $c->stash->{query_id} %>'}});
    //store_closed.load({params:{start:0 , limit: ps, filter:'C'}});


    
    return panel;
})
