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

    var record = Ext.data.Record.create([
        {name: 'filename'},
        {name: 'versionid'},
        {name: 'filesize'},     
        {name: 'size'},     
        {name: 'md5'},     
        {name: '_id', type: 'int'},
        {name: '_parent', type: 'auto'},
        {name: '_level', type: 'int'},
        {name: '_is_leaf', type: 'bool'}
    ]); 

    var store_file = new Ext.ux.maximgb.tg.AdjacencyListStore({  
       autoLoad : true,  
       url: '/topic/file_tree',
       baseParams: { topic_mid: rec.topic_mid },
       reader: new Ext.data.JsonReader({ id: '_id', root: 'data', totalProperty: 'total', successProperty: 'success' }, record )
    }); 
    var render_file = function(value,metadata,rec,rowIndex,colIndex,store) {
        var md5 = rec.data.md5;
        if( md5 != undefined ) {
            value = String.format('<a target="FrameDownload" href="/topic/download_file/{1}">{0}</a>', value, md5 );
        }
        value = '<div style="height: 20px; font-family: Consolas, Courier New, monospace; font-size: 12px; font-weight: bold; vertical-align: middle;">' 
            //+ '<input type="checkbox" class="ux-maximgb-tg-mastercol-cb" ext:record-id="' + record.id +  '"/>&nbsp;'
            + value 
            + '</div>';
        return value;
    };

    var file_del = function(){
        var sels = checked_selections();
        if ( sels != undefined ) {
            var sel = check_sm.getSelected();
            Baseliner.confirm( _('Are you sure you want to delete these artifacts?'), function(){
                var sels = checked_selections();
                Baseliner.ajaxEval( '/topic/file/delete', { md5 : sels.md5, topic_mid: rec.topic_mid }, function(res) {
                    Baseliner.message(_('Deleted'), res.msg );
                    var rows = check_sm.getSelections();
                    Ext.each(rows, function(row){ store_file.remove(row); })                    
                    //store_file.load();
                });
            });
        } 
        //Baseliner.Topic.file_del('', '', '' );
    };

    var checked_selections = function() {
        if (check_sm.hasSelection()) {
            var sel = check_sm.getSelections();
            var name = [];
            var md5 = [];
            for( var i=0; i<sel.length; i++ ) {
                md5.push( sel[i].data.md5 );
                name.push( sel[i].data.name );
            }
            return { count: md5.length, name: name, md5: md5 };
        }
        return undefined;
    };

    var check_sm = new Ext.grid.CheckboxSelectionModel({
        singleSelect: false,
        sortable: false,
        checkOnly: true
    });

    var filelist = new Ext.ux.maximgb.tg.GridPanel({
        height: 120,
        stripeRows: true,
        autoScroll: true,
        autoWidth: true,
        sortable: false,
        header: false,
        hideHeaders: true,
        sm: check_sm,
        store: store_file,
        tbar: [
            { xtype: 'checkbox', handler: function(){ if( this.getValue() ) check_sm.selectAll(); else check_sm.clearSelections() } },
            '->',
            { xtype: 'button', cls:'x-btn-icon', icon:'/static/images/icons/delete.gif', handler: file_del }
        ],
        viewConfig: {
            headersDisabled: true,
            enableRowBody: true,
            scrollOffset: 2,
            forceFit: true
        },
        master_column_id : 'filename',
        autoExpandColumn: 'filename',
        columns: [
          check_sm,
          { width: 16, dataIndex: 'extension', sortable: true, renderer: Baseliner.render_extensions },
          { id:"filename", header: _('File'), width: 250, dataIndex: 'filename', renderer: render_file },
          { header: _('Id'), hidden: true, dataIndex: '_id' },
          { header: _('Size'), width: 40, dataIndex: 'size' },
          { header: _('Version'), width: 40, dataIndex: 'versionid' }
        ]
    });
    /* tree.getLoader().on("beforeload", function(treeLoader, node) {
        var loader = tree.getLoader();
        loader.baseParams = { path: node.attributes.path, repo_path: repo_path, bl: bl };
    });

    tree.on('dblclick', function(node, ev){ 
        show_properties( node.attributes.path, node.attributes.item, node.attributes.version, node.leaf );
    }); */
    

    var filedrop = new Ext.Panel({
        border: false,
        style: { margin: '10px 0px 10px 0px' },
        height: '100px'
    });

    filedrop.on('afterrender', function(){
        var el = filedrop.el.dom;
        var uploader = new qq.FileUploader({
            element: el,
            action: '/topic/upload',
            //debug: true,  
            // additional data to send, name-value pairs
            params: {
                topic_mid: params.topic_mid ? params.topic_mid : 0
            },
            template: '<div class="qq-uploader">' + 
                '<div class="qq-upload-drop-area"><span>' + _('Drop files here to upload') + '</span></div>' +
                '<div class="qq-upload-button">' + _('Upload File') + '</div>' +
                '<ul class="qq-upload-list"></ul>' + 
             '</div>',
            onComplete: function(fu, filename, res){
                Baseliner.message(_('Upload File'), _('File %1 uploaded ok', filename) );
                if(res.file_uploaded_mid){
                    var form2 = form_topic.getForm();
                    var files_uploaded_mid = form2.findField("files_uploaded_mid").getValue();
                    files_uploaded_mid = files_uploaded_mid ? files_uploaded_mid + ',' + res.file_uploaded_mid : res.file_uploaded_mid;
                    form2.findField("files_uploaded_mid").setValue(files_uploaded_mid);
                    var files_mid = files_uploaded_mid.split(',');
                    store_file.baseParams = { files_mid: files_mid };
                    store_file.load();
                    
                }
                else{
                    store_file.load();                    
                }
            },
            onSubmit: function(id, filename){
            },
            onProgress: function(id, filename, loaded, total){},
            onCancel: function(id, filename){ },
            classes: {
                // used to get elements from templates
                button: 'qq-upload-button',
                drop: 'qq-upload-drop-area',
                dropActive: 'qq-upload-drop-area-active',
                list: 'qq-upload-list',
                            
                file: 'qq-upload-file',
                spinner: 'qq-upload-spinner',
                size: 'qq-upload-size',
                cancel: 'qq-upload-cancel',

                // added to list item when upload completes
                // used in css to hide progress spinner
                success: 'qq-upload-success',
                fail: 'qq-upload-fail'
            }
        });
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

    Baseliner.store.Topics = function(c) {
         Baseliner.store.Topics.superclass.constructor.call(this, Ext.apply({
            root: 'data' , 
            remoteSort: true,
            autoLoad: true,
            totalProperty:"totalCount", 
            baseParams: {},
            id: 'mid', 
            url: '/topic/related',
            fields: ['mid','name', 'title','description','color'] 
         }, c));
    };
    Ext.extend( Baseliner.store.Topics, Ext.data.JsonStore );

    Baseliner.model.Topics = function(c) {
        //var tpl = new Ext.XTemplate( '<tpl for="."><div class="search-item {recordCls}">{name} - {title}</div></tpl>' );
        var tpl_list = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item">',
            '<span id="boot" style="width:200px"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: {color}">{name}</span></span>',
            '&nbsp;&nbsp;<b>{title}</b></div></tpl>' );
        var tpl_field = new Ext.XTemplate( '<tpl for=".">',
            '<span id="boot"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: {color}">{name}</span></span>',
            '</tpl>' );
        Baseliner.model.Topics.superclass.constructor.call(this, Ext.apply({
            allowBlank: true,
            msgTarget: 'under',
            allowAddNewData: true,
            addNewDataOnBlur: true, 
            //emptyText: _('Enter or select topics'),
            triggerAction: 'all',
            resizable: true,
            mode: 'local',
            fieldLabel: _('Topics'),
            typeAhead: true,
            name: 'topics',
            displayField: 'name',
            hiddenName: 'topics',
            valueField: 'mid',
            tpl: tpl_list,
            displayFieldTpl: tpl_field,
            value: '/',
            extraItemCls: 'x-tag'
            /*
            ,listeners: {
                newitem: function(bs,v, f){
                    v = v.slice(0,1).toUpperCase() + v.slice(1).toLowerCase();
                    var newObj = {
                        mid: v,
                        title: v
                    };
                    bs.addItem(newObj);
                }
            }
            */
        }, c));
    };
    Ext.extend( Baseliner.model.Topics, Ext.ux.form.SuperBoxSelect );

    var topic_box_store = new Baseliner.store.Topics({ baseParams: { mid: rec.topic_mid } });
    var topic_box = new Baseliner.model.Topics({
        store: topic_box_store
    });
    topic_box_store.on('load',function(){
        topic_box.setValue( rec.topics ) ;            
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
            
            { xtype: 'hidden', name: 'topic_mid', value: rec.topic_mid },
            { xtype: 'hidden', name: 'files_uploaded_mid' },
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
            topic_box,
            {
                xtype: 'panel',
                border: false,
                layout: 'form',
                items: [
                    filelist,
                    filedrop
                ],
                fieldLabel: _('Files')
            },
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
        form2.findField("topic_mid").setValue(-1);
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
                    var swOk = true;
                    projects = (project_box.getValue()).split(",");
                    for(var i=0; i<projects.length; i++) {
                        if (projects[i] == data.id_project){
                            swOk = false;
                            break;
                        }
                    }
                    if(swOk){
                        projects.push(data.id_project);
                        project_box.setValue( projects );
                    }else{
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
    return form_topic;
})


