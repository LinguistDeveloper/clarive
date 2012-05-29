(function(params){
    var json;
    // loads data into the form:
    var load_form = function(rec) {
        if( rec !== undefined ){
            store_admin_category.load({
                    params:{ 'categoryId': rec.category, 'statusId': rec.status }
                });
            
            var ff = form_topic.getForm();
            var store = combo_category.getStore();
            var category = rec.category;
            store.on("load", function() {
               combo_category.setValue(category);
            });
            store.load();
            var priority = rec.priority;
            store_priority.on("load", function() {
               combo_priority.setValue(priority);
            });
            store_priority.load();
            rec = { data: rec };  // loadRecord needs the actual record in "data: "
            ff.loadRecord( rec );
            load_txt_values_priority(rec);
            ff.findField("txtcategory_old").setValue(rec.data.category);
            var projects = '';
            if(rec.data.projects){
                for(i=0;i<rec.data.projects.length;i++){
                    projects = projects ? projects + '\n' + rec.data.projects[i].project: rec.data.projects[i].project;
                }
                ff.findField("txtprojects").setValue(projects);
            }         
            title = 'Edit topic';
        }
    };
       
    var blank_image = new Ext.BoxComponent({autoEl: {tag: 'img', src: Ext.BLANK_IMAGE_URL}, widht:10});
    
    var title = 'Create topic';

    var store_category = new Baseliner.Topic.StoreCategory();
    var store_admin_category = new Baseliner.Topic.StoreCategoryStatus({
        url:'/topic/list_admin_category'
    });
    var store_priority = new Baseliner.Topic.StorePriority();
    var store_project = new Baseliner.Topic.StoreProject();
    
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
                combo_status.clearValue();
                var ff;
                ff = form_topic.getForm();
                if(ff.findField("txtcategory_old").getValue() == this.getValue()){
                    combo_status.store.load({
                       params:{ 'categoryId': this.getValue(), 'statusId': ff.findField("status").getValue() }
                   });                   
                }else{
                    combo_status.store.load({
                        params:{ 'change_categoryId': this.getValue(), 'statusId': ff.findField("status").getValue() }
                    });                    
                }
            }
        }
    });
    
    var combo_status = new Ext.form.ComboBox({
        mode: 'local',
        forceSelection: true,
        triggerAction: 'all',
        emptyText: 'select a status',
        fieldLabel: _('Status new'),
        name: 'status_new',
        hiddenName: 'status_new',
        displayField: 'name',
        valueField: 'id',
        //disabled: true,
        store: store_admin_category
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
                    form.findField("txtprojects").setValue(projects);                     
                }
                
                Baseliner.ajaxEval( '/topic/unassign_projects',{ idtopic: rec.data.id, idsproject: projects_checked },
                    function(response) {
                        if ( response.success ) {
                            Baseliner.message( _('Success'), response.msg );
                            form.findField("id").setValue(rec.data.id);
                            Baseliner.ajaxEval( '/topic/json', { id: rec.data.id }, function(data) {
                                load_form( data );
                                json = data;
                                json = { data: json };
                            });                          
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
        text: _('projects'),
        handler: function() {
            show_projects(json);
        }
    });
    
    var btn_unassign_roles = new Ext.Toolbar.Button({
        text: _('roles'),
        handler: function() {
            show_projects(rec);
        }
    });         
    
    var form_topic = new Ext.FormPanel({
        frame: false,
        border: false,
        url:'/topic/update',
        itemCls: 'boot',
        bodyStyle:'margin:10px 10px 0',
        buttons: [
        ],
        defaults: { anchor:'70%'},
        items: [
            {
                  xtype : "fieldset",
                  title : _("Main"),
                  collapsible: true,
                  autoHeight : true,
                  items: [
            
            { xtype: 'hidden', name: 'id', value: -1 },
            {
                xtype:'textfield',
                fieldLabel: _('Title'),
                name: 'title',
                allowBlank: false
            },
            { xtype: 'hidden', name: 'txtcategory_old' },
            combo_category,
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
                    {
                        xtype:'textfield',
                        fieldLabel: _('Topics: Status'),
                        name: 'status_name',
                        readOnly: true
                    },
                    { xtype: 'hidden', name: 'status' },
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
            },            {
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
            { xtype:'panel', layout:'fit', items: [ //this panel is here to make the htmleditor fit
                {
                    xtype:'htmleditor',
                    name:'description',
                    fieldLabel: _('Description'),
                    width: '100%',
                    height:350
                }
            ]}
           ]
              }
        ]
    });

    // if we have an id, then async load the form
    form_topic.on('afterrender', function(){
        if( params!==undefined && params.id !== undefined ) {
            Baseliner.ajaxEval( '/topic/json', { id: params.id }, function(data) {
                load_form( data );
                json = data;
                json = { data: json };
            });
        }
    });

    return form_topic;
})
