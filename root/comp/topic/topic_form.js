(function(rec){
    var form_is_loaded = false;

    var store_category = new Baseliner.Topic.StoreCategory({
        fields: ['category', 'category_name' ]  
    });

    var store_category_status = new Baseliner.Topic.StoreCategoryStatus({
        url:'/topic/list_admin_category'
    });
    
    var store_priority = new Baseliner.Topic.StorePriority();
    var store_project = new Baseliner.Topic.StoreProject();
    
    var combo_category = new Ext.form.ComboBox({
        value: rec.category_name,
        mode: 'local',
        forceSelection: true,
        emptyText: 'select a category',
        triggerAction: 'all',
        fieldLabel: _('Category'),
        name: 'category',
        valueField: 'category',
        hiddenName: 'category',
        displayField: 'category_name',
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
        value: rec.status_name,
        mode: 'local',
        forceSelection: true,
        autoSelect: true,
        triggerAction: 'all',
        emptyText: 'select a status',
        fieldLabel: _('Status'),
        name: 'status_new',
        hiddenName: 'status_new',
        displayField: 'name',
        valueField: 'id',
        //disabled: true,
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
        value: rec.priority_name,
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

    var user_box_store = new Baseliner.Topic.StoreUsers({
        autoLoad: true,
        baseParams: {projects:[]}
    });
    
    var user_box = new Baseliner.model.Users({
        store: user_box_store 
    });
    
    user_box_store.on('load',function(){
        user_box.setValue( rec.users) ;            
    });
    
    var project_box_store = new Baseliner.store.UserProjects({ id: 'id' });
    
    var project_box = new Baseliner.model.Projects({
        store: project_box_store
    });
    
    project_box_store.on('load',function(){
        project_box.setValue( rec.projects) ;            
    });
    
    project_box.on('blur',function(obj){
        var projects = new Array();
        projects = (obj.getValue()).split(","); 
        user_box.store.load({
            params:{ projects: projects}
        }); 
    });    
    
    var pb_panel = new Ext.Panel({
        layout: 'form',
        enableDragDrop: true,
        border: false,
        //style: 'border-top: 0px',
        items: [ project_box ]
    });
    var form_topic = new Ext.FormPanel({
        frame: false,
        border: false,
        url:'/topic/update',
        //itemCls: 'boot',
        bodyStyle:'padding: 10px 0px 0px 15px',
        buttons: [ ],
        defaults: { anchor:'70%'},
        items: [
            {
                  xtype : "fieldset",
                  title : _("Main"),
                  collapsible: true,
                  autoHeight : true,
                  items: [
            
            { xtype: 'hidden', name: 'id', value: rec.id },
            { xtype: 'hidden', name: 'mid', value: rec.mid },
            {
                xtype:'textfield',
                fieldLabel: _('Title'),
                name: 'title',
                value: rec.title,
                style: { 'font-size': '16px' },
                width: '100%',
                height: 30,
                allowBlank: false
            },
            { xtype: 'hidden', name: 'txtcategory_old' },
            combo_category,
            { xtype: 'hidden', name: 'status', value: rec.status },
            combo_status,
            combo_priority,
            {
                xtype:'textfield',
                fieldLabel: _('Response'),
                hidden: true,
                name: 'txtrsptime',
                readOnly: true
            },
            {
                xtype:'textfield',
                fieldLabel: _('Resolution'),
                hidden: true,
                name: 'txtdeadline',
                readOnly: true
            },
            { xtype: 'hidden', name: 'txt_rsptime_expr_min', value: -1 },
            { xtype: 'hidden', name: 'txt_deadline_expr_min', value: -1 },
            pb_panel,
            user_box,
            { xtype: 'panel', layout:'fit', border:false,items: 
            {
                xtype: 'fileuploadfield',
                emptyText: _('Select a File'),
                fieldLabel: _('File'),
                name: 'file_path',
                buttonText: '',
                buttonCfg: {
                    iconCls: 'upload-icon'
                }
            }},
            { xtype:'panel', layout:'fit', items: [ //this panel is here to make the htmleditor fit
                {
                    xtype:'htmleditor',
                    name:'description',
                    fieldLabel: _('Description'),
                    width: '100%',
                    value: rec.description,
                    height:350
                }
            ]}
           ]
              }
        ]
    });

    // if we have an id, then async load the form
    form_topic.on('afterrender', function(){
        form_topic.body.setStyle('overflow', 'auto');

    });
    if( rec.new_category_id != undefined ) {
        store_category.on("load", function() {
           combo_category.setValue(rec.new_category_id);
        });
        store_category.load();
        //store_category_status.on('load', function(){
        //   combo_status.setValue( store_category_status.getAt(0).data.id );
        //});
        store_category_status.on('load', function(){
            combo_status.setValue( store_category_status.getAt(0).id );
        });
        store_category_status.load({
            params:{ 'change_categoryId': rec.new_category_id }
        });            
        store_priority.load();
        var form2 = form_topic.getForm();
        form2.findField("id").setValue(-1);
    }else {
        store_category.on("load", function() {
            combo_category.setValue(rec.category);
        });
        store_category.load();
        store_category_status.load({
                params:{ 'categoryId': rec.category, 'statusId': rec.status, 'statusName': rec.status_name }
        });        
    }

    pb_panel.on( 'afterrender', function(){
        var el = pb_panel.el.dom; //.childNodes[0].childNodes[1];
        var project_box_dt = new Ext.dd.DropTarget(el, {
            ddGroup: 'lifecycle_dd',
            copy: true,
            notifyDrop: function(dd, e, id) {
                var n = dd.dragData.node;
                //var s = project_box.store;
                var add_node = function(node) {
                    var data = node.attributes.data;
                    // determine the row
                    /* var t = Ext.lib.Event.getTarget(e);
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
                    } */

                    /* if( swSave ) {
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
                    */
                    
                };
                var attr = n.attributes;
                if( typeof attr.data.id_project == 'undefined' ) {  // is a project?
                    Baseliner.message( _('Error'), _('Node is not a project'));
                } else {
                    //add_node(n);
                    alert( n );
                }
                // multiple? Ext.each(dd.dragData.selections, add_node );
                return (true); 
             }
        });
    }); 
    return form_topic;
})


