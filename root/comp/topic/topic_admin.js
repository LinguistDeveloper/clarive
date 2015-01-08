(function(){
    var store_status = new Baseliner.Topic.StoreStatus();
    var store_category = new Baseliner.Topic.StoreCategory({ baseParams: { swnotranslate : 1 } });
    
    var store_roles = new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id', 
        url: '/role/json',
        fields: [ 
            {  name: 'id' },
            {  name: 'role' },
            {  name: 'actions' },
            {  name: 'description' },
            {  name: 'mailbox' }
        ]
    }); 
    
    var store_label = new Baseliner.Topic.StoreLabel();
    
    var init_buttons_category = function(action) {
        eval('btn_edit_category.' + action + '()');
        eval('btn_duplicate_category.' + action + '()');
        eval('btn_delete_category.' + action + '()');
        eval('btn_edit_fields.' + action + '()');
        eval('btn_admin_category.' + action + '()');
    }   
    
    var init_buttons_label = function(action) {
        eval('btn_delete_label.' + action + '()');
    }

    var init_buttons_status = function(action) {
        eval('btn_edit_status.' + action + '()');       
        eval('btn_delete_status.' + action + '()');
    }
    
    var add_edit_status = function(rec) {
        var win;
        var title = 'Create status';
        
        var ta = new Ext.form.TextArea({
            name: 'description',
            height: 70,
            hidden: true,
            enableKeyEvents: true,
            fieldLabel: _('Description'),
            emptyText: _('A brief description of the status')
        });     
        
    
        var form_status = new Ext.FormPanel({
            frame: true,
            url:'/topicadmin/update_status',
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
                                    submitEmptyText: false,
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
                { xtype:'textfield', name:'name', fieldLabel:_('Topics: Status'),
                  allowBlank:false, emptyText:_('Name of status'),
                  regex: /^[^\.]+$/,
                  regexText: _('Character dot not allowed')             
                },
                ta,
                {
                    xtype: 'radiogroup',
                    id: 'statusgroup',
                    fieldLabel: _('Type'),
                    defaults: {xtype: "radio",name: "type"},
                    items: [
                        {boxLabel: _('General'), inputValue: 'G', checked: true},
                        {boxLabel: _('Initial'), inputValue: 'I'},
                        {boxLabel: _('Deployable'), inputValue: 'D'},
                        {boxLabel: _('Canceled'), inputValue: 'FC'},
                        {boxLabel: _('Final'), inputValue: 'F'}
                    ]
                },
                Baseliner.combo_baseline(),
                { xtype:'textfield', name:'seq', fieldLabel:_('Position') },
                { xtype:'checkbox', name:'frozen', boxLabel:_('Frozen') },
                { xtype:'checkbox', name:'readonly', boxLabel:_('Readonly') },
                { xtype:'checkbox', name:'ci_update', boxLabel:_('CI Update') },
                { xtype:'checkbox', name:'bind_releases', boxLabel:_('Bind releases') }
            ]
        });

        if(rec){
            var ff = form_status.getForm();
            ff.loadRecord( rec );
            ff.findField('bind_releases').setValue(rec.data.bind_releases);
            ff.findField('ci_update').setValue(rec.data.ci_update);
            ff.findField('frozen').setValue(rec.data.frozen);
            ff.findField('readonly').setValue(rec.data.readonly);
            title = 'Edit status';
        }
        
        win = new Baseliner.Window({
            title: _(title),
            width: 480,
            autoHeight: true,
            items: form_status
        });
        win.show();     
    };
    
    //var btn_add_status = new Ext.Toolbar.Button({
    //    text: _('New'),
    //    icon:'/static/images/icons/add.gif',
    //    cls: 'x-btn-text-icon',
    //    handler: function() {
    //                add_edit_status();
    //    }
    //});
    
    var btn_add_status = new Baseliner.Grid.Buttons.Add({    
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
                    Baseliner.ajaxEval( '/topicadmin/update_status?action=delete',{ idsstatus: statuses_checked },
                        function(response) {
                            if ( response.success ) {
                                Baseliner.message( _('Success'), response.msg );
                                init_buttons_status('disable');
                                store_status.load();
                                var labels_checked = getLabels();
                                var categories_checked = getCategories();
                                //filtrar_topics(labels_checked, categories_checked);
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

    var render_status_type = function (val){
        if( val == null || val == undefined ) return '';
        var str = val == 'G' ? _('General') : val == 'I' ? _('Initial') : val == 'D' ? _('Deployable'): val == 'FC' ? _('Canceled') : _('Final');
        return str;
    }   
    
    var render_category_type = function (val){
        if( val == null || val == undefined ) return '';
        var str = val == 'R' ? _('Release') : val == 'C' ? _('Changeset') : _('Normal');
        return str;
    }   

    var render_status = function(value,metadata,rec,rowIndex,colIndex,store){
        var ret = 
            '<b><span style="text-transform:uppercase;font-family:Helvetica Neue,Helvetica,Arial,sans-serif;color:#111">' + value + '</span></b>';
        return ret;
    };
    
    var render_status2 = function(value,metadata,rec,rowIndex,colIndex,store){
        if( typeof value == 'object' ) 
            value = value.join(', ');
        value = '<div style="white-space:normal !important;">'+ value +'</div>';
        var ret = 
            '<span style="text-transform:uppercase;font-family:Helvetica Neue,Helvetica,Arial,sans-serif;color:#111">' + value + '</span>';
        return ret;
    };
    var render_status_arrow = function(value,metadata,rec,rowIndex,colIndex,store){
        return '<img src="/static/images/icons/right-arrow.png" />';
    };
    
    var grid_status = new Ext.grid.GridPanel({
        title : _('Topics: Statuses'),
        sm: check_status_sm,
        height: 400,
        header: true,
        border: true,
        stripeRows: true,
        autoScroll: true,
        enableHdMenu: false,
        store: store_status,
        viewConfig: {forceFit: true, scrollOffset: 2},
        selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
        loadMask:'true',
        columns: [
            { hidden: true, dataIndex:'id' },
            // check_status_sm,
            { header: _('Topics: Status'), dataIndex: 'name', width:100, sortable: true, renderer: render_status },
            { header: _('Description'), dataIndex: 'description', sortable: true },
            { header: _('Order'), width: 40, dataIndex: 'seq', sortable: true },
            { header: _('Baseline'), dataIndex: 'bl', sortable: true, renderer: Baseliner.render_bl },
            { header: _('Type'), dataIndex: 'type', width:50, sortable: true, renderer: render_status_type }
        ],
        autoSizeColumns: true,
        deferredRender:true,    
        tbar: [ 
                // btn_add_status,
                // btn_edit_status,
                // btn_delete_status,
                '->'
        ]
    }); 

    grid_status.on('cellclick', function(grid, rowIndex, columnIndex, e) {
        if(columnIndex == 1){
            var statuses_checked = getStatuses();
            var categories_checked = getCategories();
            var labels_checked = getLabels();
            //filtrar_topics(labels_checked, categories_checked);
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
            //filtrar_topics(labels_checked, categories_checked);
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
        
        // Combo Providers
        //   TODO read from provider.topic.*
        var store_providers =new Ext.data.SimpleStore({
            fields: ['provider', 'name'],
            data:[ 
                [ 'internal', _('Internal') ],
                [ 'bugzilla', _('Bugzilla') ],
                [ 'basecamp', _('Basecamp') ],
                [ 'trac', _('Trac') ],
                [ 'redmine', _('Redmine') ],
                [ 'remedy', _('BMC Remedy') ],
                [ 'jira', _('Jira') ],
                [ 'hp_ppm', _('HP PPM') ],
                [ 'clarity', _('Clarity') ]
            ]
        });
        
        var combo_providers = new Ext.form.ComboBox({
            store: store_providers,
            displayField: 'name',
            valueField: 'provider',
            hiddenName: 'provider',
            name: 'provider',
            editable: false,
            mode: 'local',
            forceSelection: true,
            triggerAction: 'all', 
            fieldLabel: _('Providers'),
            emptyText: _('select providers...'),
            autoLoad: true
        });

        var ta = new Ext.form.TextArea({
            name: 'description',
            height: 130,
            enableKeyEvents: true,
            fieldLabel: _('Description'),
            emptyText: _('A brief description of the category')
        });     
        var category_name_field = new Ext.form.TextField({ 
            name:'name', fieldLabel:_('Category'),
            allowBlank:false, emptyText:_('Name of category'),
            regex: /^[^\.]+$/,
            regexText: _('Character dot not allowed')
        });
        var acronym = new Ext.form.TextField({ 
            name:'acronym', fieldLabel:_('Acronym'),
            allowBlank:false, emptyText:_('Short name for the category'),
            regex: /^[^\.]+$/,
            regexText: _('Character dot not allowed')
        });
        //   Color settings 
        var category_color = new Ext.form.Hidden({ name:'category_color' });
        category_color.setValue(rec ? rec.data.color : '#999');
        var color = rec ? rec.data.color : '';

        var color_pick = new Ext.ColorPalette({ 
            value: color, 
            colors: [
                '8E44AD', '30BED0', 'A01515', 'A83030', '003366', '000080', '333399', '333333',
                '800000', 'FF6600', '808000', '008000', '008080', '0000FF', '666699', '808080',
                'FF0000', 'FF9900', '99CC00', '339966', '33CCCC', '3366FF', '800080', '969696',
                'FF00FF', 'FFCC00', 'F1C40F', '00ACFF', '20BCFF', '00CCFF', '993366', 'C0C0C0',
                'FF99CC', 'DDAA55', 'BBBB77', '88CC88', 'D35400', '99CCFF', 'CC99FF', '11B411',
                '1ABC9C', '16A085', '2ECC71', '27AE60', '3498DB', '2980B9', 'E74C3C', 'C0392B'
            ]
        });
        color_pick.on('select', function(pal,color){
            var cl = '#' + color.toLowerCase();
            category_color.setRawValue( cl ); 
            color_button.setText( color_btn_gen(cl) );
        });
        
        var color_btn_gen = function(color){
            return String.format('<div id="boot" style="margin-top: -3px; background: transparent"><span class="label" style="background: {0}">{1}</span></div>', 
                color, category_name_field.getValue() || ( rec ? rec.data.name : _('Sample') ) );
        };
        var color_button = new Ext.Button({ 
            text: color_btn_gen( color ), 
            fieldLabel: _('Pick a Color'),
            height: 30,
            menu: { items: [color_pick] }
        });
        
        // Main Edit for Categories
        var column1 = {
            xtype:'panel',
            columnWidth:0.50,
            layout:'form',
            defaults:{anchor:'100%'},
            items: [
                { xtype: 'hidden', name: 'id', value: -1 },
                category_color,
                category_name_field,
                acronym,
                ta,
                {
                    xtype: 'radiogroup',
                    fieldLabel: _('Type'),
                    defaults: {xtype: "radio",name: "type"},
                    items: [
                        {boxLabel: _('Normal'), inputValue: 'N', checked: true},
                        {boxLabel: _('Changeset'), inputValue: 'C'},
                        {boxLabel: _('Release'), inputValue: 'R'}
                    ]
                },
                color_button,
                { xtype: 'panel', style: { 'margin-top': '20px' }, layout: 'form', items: [ combo_providers ] },
                { xtype:'checkboxgroup', name:'readonly', fieldLabel:_('Options'),
                    items:[
                        { xtype:'checkbox', name:'readonly', boxLabel:_('Readonly') }
                    ]
                }
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
            viewConfig: {forceFit: true, scrollOffset: 2},
            selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
            loadMask:'true',
            columns: [
                { hidden: true, dataIndex:'id' },
                check_category_status_sm,
                { header: _('Topics: Status'), dataIndex: 'name', width:50, sortable: true },
                { header: _('Description'), dataIndex: 'description', sortable: true } 
            ],
            autoSizeColumns: true,
            deferredRender:true,
            listeners: {
                viewready: function() {
                    var me = this;
                    
                    var datas = me.getStore();
                    var recs = [];
                    datas.each(function(row, index){
                        //if(rec.data.statuses){
                        if(rec && rec.data && rec.data.statuses){
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
           items: [ grid_category_status ]};      
        
        
        var form_category = new Ext.FormPanel({
            frame: true,
            url:'/topicadmin/update_category',
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
                                    submitEmptyText: false,
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

        form_category.on('afterrender',function(){
            combo_providers.setValue('internal');
        });

        if(rec){
            console.dir(rec);
            var ff = form_category.getForm();
            ff.loadRecord( rec );
            title = 'Edit category';
        }
        
        win = new Baseliner.Window({
            title: _(title),
            width: 750,
            autoHeight: true,
            items: form_category
        });
        win.show();     
    };


    //var btn_add_category = new Ext.Toolbar.Button({
    //    text: _('New'),
    //    icon:'/static/images/icons/add.gif',
    //    cls: 'x-btn-text-icon',
    //    handler: function() {
    //                add_edit_category();
    //    }
    //});
    
    var btn_add_category = new Baseliner.Grid.Buttons.Add({    
        text: null,
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
    
    var btn_duplicate_category = new Ext.Toolbar.Button({
        text: _('Duplicate'),
        icon:'/static/images/icons/copy.gif',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
            var sm = grid_categories.getSelectionModel();
            if (sm.hasSelection()) {
                var sel = sm.getSelected();
                Baseliner.ajaxEval( '/topicadmin/duplicate',
                    { id_category: sel.data.id },
                    function(response) {
                        if ( response.success ) {
                            store_category.reload();
                            Baseliner.message( _('Success'), response.msg );
                            init_buttons_category('disable');
                        } else {
                            Baseliner.message( _('ERROR'), response.msg );
                        }
                    }
                
                );                
            } else {
                Ext.Msg.alert('Error',  _('Select at least one row'));    
            };
        }
    });     

    var btn_delete_category = new Ext.Toolbar.Button({
        icon:'/static/images/icons/delete.gif',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
            var categories_checked = getCategories();
            Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the categories selected?'), 
            function(btn){ 
                if(btn=='yes') {
                    Baseliner.ajaxEval( '/topicadmin/update_category?action=delete',{ idscategory: categories_checked },
                        function(response) {
                            if ( response.success ) {
                                Baseliner.message( _('Success'), response.msg );
                                init_buttons_category('disable');
                                store_category.load();
                                var labels_checked = getLabels();
                                //filtrar_topics(labels_checked, null);                               
                            } else {
                                Baseliner.message( _('ERROR'), response.msg );
                            }
                        }
                    
                    );
                }
            });
        }
    });
     
    //var btn_update_fields = new Ext.Toolbar.Button({
    //    text: _('System'),
    //    icon:'/static/images/icons/restart.png',
    //     cls: 'x-btn-text-icon',
   //     handler: function() {
   //         Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to update the system?'), 
   //         function(btn){ 
   //             if(btn=='yes') {
   //                 Baseliner.ajaxEval( '/topicadmin/update_system',{},
   //                     function(response) {
   //                         if ( response.success ) {
  //                              Baseliner.message( _('Success'), response.msg );
  //                          } else {
  //                              Baseliner.message( _('ERROR'), response.msg );
  //                          }
  //                      }
  //                  
  //                  );
  //              }
   //         });
   //    }
   // }); 
    

    var add_edit_admin_category = function(rec) {
        var win;
        var title = _('Workflow: %1', rec.data.name );
        var id = Ext.id();

        var store_category_status = new Baseliner.Topic.StoreCategoryStatus();
        var store_admin_status = new Baseliner.Topic.StoreCategoryStatus({
                listeners: {
                    'load': function( store, rec, obj ) {
                        statusCbx = Ext.getCmp('status-combo_' + id);
                        // store.filter( { fn   : function(record) {
                        
                        //                                             return record.get('name') != statusCbx.getRawValue();
                        //                                         }
                        //                             });
                    }
                }   
        });
    
        store_roles.load();
        store_category_status.load({params:{categoryId: rec.data.id}});
        
        var ta = new Ext.form.TextArea({
            name: 'description',
            height: 120,
            enableKeyEvents: true,
            fieldLabel: _('Description'),
            emptyText: _('A brief description of the category'),
            disabled: true
        });     
        
        var check_admin_status_sm = new Ext.grid.CheckboxSelectionModel({
            singleSelect: false,
            sortable: false,
            checkOnly: true
        });
        
        var job_type_switch = function( rec, data ) {
            var sel = check_admin_status_sm.getSelections();
            var flag = false;
            if (sel.length > 0 ) { flag = true; }
            for( var i=0; i<sel.length; i++ ) {
                var bl = sel[i].data.bl;
                if( bl==undefined || bl == ''  || bl == '*' ) 
                    flag = false;
            }
            if( flag && ( rec.data.is_changeset==1 || rec.data.is_release )
                && data.bl!= undefined && data.bl.bl!='' && data.bl.bl != '*' ) {
                combo_job_type.show();
                combo_job_type.setValue('promote');
            } else {
                combo_job_type.hide();
                combo_job_type.setRawValue('*');
            }
        };
        check_admin_status_sm.on('rowselect', function( sm,ix,row ){
            job_type_switch( rec, row.data );
        });

        check_admin_status_sm.on('rowdeselect', function( sm,ix,row ){
            job_type_switch( rec, row.data );
        });


        var grid_admin_status = new Ext.grid.GridPanel({
            sm: check_admin_status_sm,
            store: store_admin_status,
            header: false,
            height: 157,
            stripeRows: true,
            autoScroll: true,
            enableHdMenu: false,
            viewConfig: {forceFit: true, scrollOffset: 2},
            selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
            loadMask:'true',
            columns: [
                { hidden: true, dataIndex:'id' },
                  check_admin_status_sm,
                { header: _('Status To'), dataIndex: 'name', width:50, sortable: false }
            ],
            autoSizeColumns: true,
            deferredRender:true
        });         
        
        var column2 = {
           xtype:'panel',
           defaults:{anchor:'98%'},
           columnWidth:0.50,
           items: grid_admin_status
        };
        
        var combo_status = new Ext.form.ComboBox({
            mode: 'local',
            id: 'status-combo_' + id,
            forceSelection: true,
            triggerAction: 'all',
            emptyText: _('select status...'),
            fieldLabel: _('Status From'),
            name: 'status_from',
            hiddenName: 'status_from',
            displayField: 'name',
            valueField: 'id',
            allowBlank:false,
            store: store_category_status,
            listeners:{
                'select': function(combo, r, idx) {
                    if(store_admin_status.getCount()) {
                        // store_admin_status.filter( {    fn   : function(record) {
                        //                                             return record.get('name') != r.data.name;
                        //                                         },scope:this
                        //                             });
                    }else{
                        store_admin_status.load({params:{categoryId: rec.data.id}});
                    }

                    // show job_type combo ?
                    var bl = r.data.bl;
                    job_type_switch( rec, r.data );
                }
            }           
        });
        
        var check_roles_sm = new Ext.grid.CheckboxSelectionModel({
            singleSelect: false,
            sortable: false,
            checkOnly: true
        });

        var grid_roles = new Ext.grid.GridPanel({
            title: _('Available Roles'),
            sm: check_roles_sm,
            store: store_roles,
            stripeRows: true,
            autoScroll: true,
            autoWidth: true,
            viewConfig: { forceFit: true, scrollOffset: 2 },            
            height:190,
            columns: [
                check_roles_sm,
                { hidden: true, dataIndex:'id' }, 
                { header: _('All'), width:250, dataIndex: 'role', sortable: true }
            ],
            autoSizeColumns: true
        });      
    
        var render_project = function(value,metadata,rec,rowIndex,colIndex,store){
            if(rec.data.projects){
                for(i=0;i<rec.data.projects.length;i++){
                    tag_project_html = tag_project_html + "<div id='boot' class='alert' style='float:left'><button class='close' data-dismiss='alert'>×</button>" + rec.data.projects[i].project + "</div>";
                }
            }
            return tag_project_html;
        };
    
        var render_statuses_to = function (val){
            if( val == null || val == undefined ) return '';
            if( typeof val != 'object' ) return '';
            var str = '';
            for( var i=0; i<val.length; i++ ) { str += String.format('<li>{0}</li>', val[i]); }
            return str;
        }   
    
        var reader = new Ext.data.JsonReader({
            root: 'data' , 
            remoteSort: true,
            totalProperty:"totalCount", 
            id: 'id'
            }, 
            [ 
                    {name: 'role' },
                    {name: 'status_from' },
                    {name: 'id_category' },                 
                    {name: 'id_role' },
                    {name: 'id_status_from' },                  
                    {name: 'statuses_to' }  
            ]
        );
        
        var store_categories_admin = new Baseliner.GroupingStore({           
            reader: reader,
            url: '/topicadmin/list_categories_admin',
            groupField: 'role',
            sortInfo:{field: 'role', direction: "ASC"}
        });
        
        var btn_delete_row = new Ext.Toolbar.Button({
            text: _('Delete row'),
            icon:'/static/images/icons/delete.gif',
            cls: 'x-btn-text-icon',
            disabled: true,
            handler: function() {
                var sm = grid_categories_admin.getSelectionModel();
                if (sm.hasSelection()) {
                    var row = sm.getSelected();
                    Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the row selected?'), 
                    function(btn){ 
                        if(btn=='yes') {
                            var id_category = row.data.id_category;
                            var id_role = row.data.id_role;
                            var id_status_from = row.data.id_status_from;
                            Baseliner.ajaxEval( '/topicadmin/delete_row',{ id_category: id_category, id_role: id_role, id_status_from: id_status_from },
                                function(response) {
                                    if ( response.success ) {
                                        Baseliner.message( _('Success'), response.msg );
                                        btn_delete_row.disable();
                                        store_categories_admin.load({params:{categoryId: id_category}});
                                    } else {
                                        Baseliner.message( _('ERROR'), response.msg );
                                    }
                                }
                            );
                        }
                    });
                }
            }
        });
        
        
        var grid_categories_admin = new Ext.grid.GridPanel({
            height: 300,
            title: _('Roles/Workflow'),
            stripeRows: true,
            autoScroll: true,
            autoWidth: true,
            store: store_categories_admin,
            view: new Ext.grid.GroupingView({
                forceFit:true,
                groupTextTpl: '{[ values.rs[0].data["role"] ]}'
            }),         
            iconCls: 'icon-grid',
            selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
            loadMask:'true',
            columns: [
                { header: _('Role'), width: 120, dataIndex: 'role', hidden: true }, 
                { header: _('From Status'), width: 60, dataIndex: 'status_from', renderer: render_status },
                { width: 16, renderer: render_status_arrow },
                { header: _('To Status'), width: 150, dataIndex: 'statuses_to', renderer: render_status2 }
            ],
            autoSizeColumns: true,
            deferredRender:true,
            bbar: [btn_delete_row]
        });
        
        grid_categories_admin.on('rowclick', function(grid, rowIndex, columnIndex, e) {
            btn_delete_row.enable();
        });     
         
        store_categories_admin.load({params:{categoryId: rec.data.id}});

        // Combo Job Type
        var store_job_type =new Ext.data.SimpleStore({
            fields: ['job_type', 'name'],
            data:[ 
                [ 'none', _('none') ],
                [ 'static', _('static') ],
                [ 'promote', _('promote') ],
                [ 'demote', _('demote') ]
            ]
        });
        
        var combo_job_type = new Ext.form.ComboBox({
            store: store_job_type,
                displayField: 'name',
                valueField: 'job_type',
                hiddenName: 'job_type',
                name: 'job_type',
            editable: false,
            mode: 'local',
            hidden: true,
            forceSelection: true,
            triggerAction: 'all', 
            fieldLabel: _('Job Type'),
            emptyText: _('select job type...'),
            autoLoad: true
        });
        var form_category_admin = new Ext.FormPanel({
            frame: true,
            url:'/topicadmin/update_category_admin',
            buttons: [
                    {
                        //text: _('Add'),
                        type: 'submit',
                        cls: 'btn-text-icon',
                        icon: '/static/images/icons/down.png',
                        handler: function() {
                            var form = form_category_admin.getForm();
                            var action = '';
                            
                            if (form.isValid()) {
                                
                                var roles_checked = new Array();
                                check_roles_sm.each(function(rec){
                                    roles_checked.push(rec.get('id'));
                                }); 
                                var statuses_to_checked = new Array();
                                
                                check_admin_status_sm.each(function(rec){
                                    statuses_to_checked.push(rec.get('id'));
                                });                             
                                
                                if( ! combo_job_type.isVisible() ) {
                                    combo_job_type.setValue('');
                                }

                                if(roles_checked.length>0 && statuses_to_checked.length>0){
                                    form.submit({
                                        submitEmptyText: false,
                                        params: {action: action, idsroles: roles_checked, idsstatus_to: statuses_to_checked},
                                        success: function(f,a){
                                            Baseliner.message(_('Success'), a.result.msg );
                                            store_categories_admin.load({params:{categoryId: rec.data.id}});
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
                                else { Baseliner.message(_('Error'), _('Select at least one role and status to') ); }

                            }
                        }
                    },
                    '-',
                    {
                        //text: _('Delete'),
                        cls: 'btn-text-icon',
                        icon: '/static/images/icons/remove.png',
                        handler: function() {
                            var form = form_category_admin.getForm();
                            var action = '';
                            
                            if (form.isValid()) {
                                
                                var roles_checked = new Array();
                                check_roles_sm.each(function(rec){
                                    roles_checked.push(rec.get('id'));
                                }); 
                                var statuses_to_checked = new Array();
                                
                                check_admin_status_sm.each(function(rec){
                                    statuses_to_checked.push(rec.get('id'));
                                });                             
                                
                                var d = form.getValues();
                                d.idsroles = roles_checked;
                                d.idsstatus = statuses_to_checked;
                                Baseliner.ajaxEval('/topicadmin/workflow/delete', d , function(res){
                                    if( res.success ) {
                                        Baseliner.message(_('Success'), res.msg );
                                        store_categories_admin.load({params:{categoryId: rec.data.id}});
                                    } else {
                                        Ext.Msg.alert( _('Error'), res.msg ); 
                                    }
                                });
                            }
                        }
                    },
                    '-',
                    {
                    text: _('Close'),
                    handler: function(){ 
                            win.close();
                        }
                    }
            ],
            defaults: { bodyStyle:'padding:0 18px 0 0', anchor:'100%'},
            items: [
                { xtype: 'hidden', name: 'id', value: -1 },
                { xtype: 'container', style: { padding: '10px' },
                        html: String.format( '<span id="boot"><span class="label" style="background-color: {0}">{1}</span></span>',
                                                                rec.data.color, rec.data.name ) },
                {
                    // column layout with 2 columns
                    layout:'column'
                    ,defaults:{
                        layout:'form'
                        ,border:false
                        ,xtype:'panel'
                        ,bodyStyle:'padding:10px 10px 10px 10px'
                    }
                    ,items:[
                        {
                            // left column
                            columnWidth:0.50,
                            defaults:{anchor:'100%'}
                            ,items:[
                                grid_roles
                            ]
                        },
                        {
                            // right column             
                            columnWidth:0.50,
                            defaults:{anchor:'100%'},
                            items:[
                                combo_status,
                                column2
                            ]
                        }
                    ]
                },
                combo_job_type
            ]           
        });

        if(rec){
            var ff = form_category_admin.getForm();
            ff.loadRecord( rec );
        }
        
        win = new Baseliner.Window({
            title: _(title),
            width: 700,
            autoHeight: true,
            items: [form_category_admin,
                    grid_categories_admin
            ]
        });
        win.show();     
    };
    
    var edit_fields = function(rec) {
        var title = render_category( rec.data.name, {}, rec);
        
        var id_category = rec.data.id;
        Baseliner.require('/comp/topic/form_editor.js' + '?'+Math.random(), function(){
            var form_fields = new Baseliner.FieldEditor({ id_category: id_category });
            
            var win = new Baseliner.Window({
                title: _(title),
                width: 700,
                autoHeight: true,
                items: [form_fields]
            });
            win.show();     
        });
    };

    var btn_edit_fields = new Ext.Toolbar.Button({
        text: _('Fields'),
        icon:'/static/images/icons/detail.png',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
            var sm = grid_categories.getSelectionModel();
            if (sm.hasSelection()) {
                var sel = sm.getSelected();
                edit_fields(sel);
            } else {
                Baseliner.message( _('ERROR'), _('Select at least one row'));    
            };          
        }
    });

    var btn_admin_category = new Ext.Toolbar.Button({
        text: _('Workflow'),
        icon:'/static/images/icons/workflow.png',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
            var sm = grid_categories.getSelectionModel();
            if (sm.hasSelection()) {
                var sel = sm.getSelected();
                add_edit_admin_category(sel);
            } else {
                Baseliner.message( _('ERROR'), _('Select at least one row'));    
            };          
        }
    });
    
    var btn_tools_category = new Ext.Toolbar.Button({
        icon:'/static/images/icons/wrench.png',
        cls: 'x-btn-text-icon',
        disabled: false,
        menu: [
            { text: _('Import'), 
                icon: '/static/images/icons/import.png',
                handler: function(){
                    category_import();
                 }
            },
            { text: _('Export'), 
                icon: '/static/images/icons/export.png',
                handler: function(){ 
                    var sm = grid_categories.getSelectionModel();
                    if (sm.hasSelection()) {
                        var sel = sm.getSelected();
                        category_export(sel);
                    } else {
                        Baseliner.message( _('ERROR'), _('Select at least one row'));    
                    };          
                 }
            }
        ]
    });      
    
    var check_categories_sm = new Ext.grid.CheckboxSelectionModel({
        singleSelect: false,
        sortable: false,
        checkOnly: true
    });
    
    var render_category = function(value,metadata,rec,rowIndex,colIndex,store){
        var color = rec.data.color;
        var ret = '<div id="boot"><span class="label" style="float:left;padding:2px 8px 2px 8px;background: '+ color + '">' + value + '</span></div>';
        return ret;
    };

    var grid_categories = new Ext.grid.GridPanel({
        title : _('Categories'),
        sm: check_categories_sm,
        height: 400,
        header: true,
        stripeRows: true,
        autoScroll: true,
        enableHdMenu: false,
        store: store_category,
        viewConfig: {forceFit: true, scrollOffset: 2},
        loadMask:'true',
        columns: [
            { hidden: true, dataIndex:'id' },
            check_categories_sm,
            { header: _('Category'), dataIndex: 'name', width:50, sortable: true, renderer: render_category },
            { header: _('Acronym'), dataIndex: 'acronym', width:15, sortable: true },
            { header: _('Description'), dataIndex: 'description', sortable: true },
            { header: _('Type'), dataIndex: 'type', width:50, sortable: false, renderer: render_category_type }
        ],
        autoSizeColumns: true,
        deferredRender:true,    
        tbar: [ 
                btn_add_category,
                '-',
                btn_delete_category,
                '-',
                btn_edit_category,
                btn_duplicate_category,
                '->',
                //btn_update_fields,
                btn_edit_fields,
                //btn_form_category,
                btn_admin_category,
                btn_tools_category
        ]       
    }); 
    
    grid_categories.on('cellclick', function(grid, rowIndex, columnIndex, e) {
        if(columnIndex == 1){
            var categories_checked = getCategories();
            var labels_checked = getLabels();
            //filtrar_topics(labels_checked, categories_checked);
            if (categories_checked.length == 1){
                init_buttons_category('enable');
            }else{
                if(categories_checked.length == 0){
                    init_buttons_category('disable');
                }else{
                    btn_delete_category.enable();
                    btn_edit_category.disable();
                    btn_duplicate_category.disable();
                    btn_edit_fields.disable();
                    //btn_form_category.disable();
                    btn_admin_category.disable();
                }
            }
        }
    });
    
    grid_categories.on('headerclick', function(grid, columnIndex, e) {
        if(columnIndex == 1){
            var categories_checked = getCategories();
            var labels_checked = getLabels();
            //filtrar_topics(labels_checked, categories_checked);
            if(categories_checked.length == 0){
                init_buttons_category('disable');
            }else{
                btn_delete_category.enable();
                btn_edit_category.disable();
                btn_duplicate_category.disable();
            }
        }
    });
    
    
    var btn_add_label = new Baseliner.Grid.Buttons.Add({    
        handler: function() {
            if(label_box.getValue() != ''){
                if ( btn_by_project.pressed ) {
                    if (!projects_box.getValue()){
                        Ext.Msg.show({
                                title: _('Information'), 
                                msg: _('There are not projects selected'), 
                                buttons: Ext.Msg.OK, 
                                icon: Ext.Msg.INFO
                            });
                        return
                    }       
                }
                
                Baseliner.ajaxEval( '/topicadmin/update_label?action=add',{ label: label_box.getValue(), color: '#' + color_lbl, projects: projects_box.getValue()},
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
                    Baseliner.ajaxEval( '/topicadmin/update_label?action=delete',{ idslabel: labels_checked },
                        function(response) {
                            if ( response.success ) {
                                Baseliner.message( _('Success'), response.msg );
                                init_buttons_label('disable');
                                store_label.load();
                                var categories_checked = getCategories();
                                //filtrar_topics(null, categories_checked);
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
        width: 25,
        readOnly: true,
        style:'background:#' + color_lbl
    });
    
    var colorMenu = new Ext.menu.ColorMenu({
        handler: function(cm, color) {
            color_label.el.setStyle('background','#' + color );
            color_lbl = color ;
        }
    });

    var blank_image = new Ext.BoxComponent({autoEl: {tag: 'img', src: Ext.BLANK_IMAGE_URL}});
    
    var label_box = new Ext.form.TextField({ width: '120', enableKeyEvents: true });
    
    var projects_box = new Ext.form.TextField({ hidden:true });
    
    label_box.on('specialkey', function(f, e){
        if(e.getKey() == e.ENTER){
            if(f.getValue() != ''){
                Baseliner.ajaxEval( '/topicadmin/update_label?action=add',{ label: label_box.getValue(), color: '#' + color_lbl, projects: projects_box.getValue()},
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

    var btn_by_project = new Ext.Toolbar.Button({
        text: _('By project'),
        icon:'/static/images/icons/project.png',
        cls: 'x-btn-text-icon',
        enableToggle: true, pressed: false, allowDepress: true,
        handler: function() {
            if (btn_by_project.pressed){
                btn_choose_projects.enable();
            }else{
                btn_choose_projects.disable();
                projects_box.setValue('');
            }
        }       
    });
    
    
    var btn_choose_projects = new Ext.Toolbar.Button({
        icon:'/static/images/icons/add_new_form_16.png',
        cls: 'x-btn-text-icon',
        disabled: true,
        //enableToggle: true, pressed: false, allowDepress: true,
        handler: function() {
            
            var treeRoot = new Ext.tree.AsyncTreeNode({
                text: _('All'),
                draggable: false,
                checked: false,
                id: 'All',
                data: {
                    project: '',
                    id_project: 'todos',
                    parent_checked: ''
                }
            });
        

            var tree_projects = new Ext.tree.TreePanel({
                title: _('Available Projects'),
                dataUrl: "user/projects_list",
                split: true,
                colapsible: true,
                useArrows: true,
                ddGroup: 'secondGridDDGroup',
                animate: true,
                enableDrag: true,
                containerScroll: true,
                autoScroll: true,
                height:200,         
                rootVisible: true,
                preloadChildren: true,
                root: treeRoot
            });
            
            tree_projects.getLoader().on("beforeload", function(treeLoader, node) {
                var loader = tree_projects.getLoader();
            
                loader.baseParams = node.attributes.data;
                node.attributes.data.parent_checked = (node.attributes.checked)?1:0;
            });
            
            tree_projects.on('checkchange', function(node, checked) {
                if(node != treeRoot){
                    if (node.attributes.checked == false){
                         treeRoot.attributes.checked = false;
                         treeRoot.getUI().checkbox.checked = false;
                    }
                }
                node.eachChild(function(n) {
                    n.getUI().toggleCheck(checked);
                });
                
            });
            
            var w = new Baseliner.Window({ layout:'fit',width:400, height:400, items: tree_projects });
            w.show();
            
            tree_projects.on('beforedestroy', function(){
                var projects_checked = new Array();
                var projects_parents_checked = new Array();
                selNodes = tree_projects.getChecked();
                Ext.each(selNodes, function(node){
                    if(node.attributes.leaf){
                        projects_checked.push(node.attributes.data.id_project);
                    }else{
                        if(node.childNodes.length > 0 || node.attributes.data.id_project == 'todos'){
                            projects_checked.push(node.attributes.data.id_project);
                        }
                        else{
                            projects_parents_checked.push(node.attributes.data.id_project);
                        }
                    }
                });             
                
                projects_box.setValue( projects_checked );
                w.close();
            });         
            
        }       
    }); 
    
    var tb = new Ext.Toolbar({
        items: [
                {
                    text:   _('Pick a Color'),
                    menu:   colorMenu
                },
                color_label,
                blank_image,
                label_box,
                projects_box,
                btn_add_label,
                btn_delete_label,
                '->'//,
% #if ($c->stash->{can_admin_labels}) {              
                //btn_by_project,
                //btn_choose_projects
% #}             
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
        height: 250,
        autoScroll: true,
        header: true,
        stripeRows: true,
        enableHdMenu: false,
        store: store_label,
        viewConfig: {forceFit: true, scrollOffset: 2},
        selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
        loadMask:'true',
        columns: [
            { hidden: true, dataIndex:'id' },
            check_labels_sm,
            { header: _('Color'), dataIndex: 'color', width:15, sortable: false, renderer: render_color },
            { header: _('Label'), dataIndex: 'name', sortable: true },
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
    
    grid_labels.on('cellclick', function(grid, rowIndex, columnIndex, e) {
        if(columnIndex == 1){
            var labels_checked = getLabels();
            var categories_checked = getCategories();
            //filtrar_topics(labels_checked, categories_checked);
            init_buttons_label('enable');
        }
    });
    
    grid_labels.on('headerclick', function(grid, columnIndex, e) {
        if(columnIndex == 1){
            var labels_checked = getLabels();
            var categories_checked = getCategories();
            //filtrar_topics(labels_checked, categories_checked);
            init_buttons_label('enable');
        }
    });
    
    
    function load_cbx(form, rec){
        var expr = rec.data.expr_response_time.split(':');
        for (i=0; i < expr.length; i++){
            var value = expr[i].substr(0, expr[i].length - 1);
            if(value != 0){
                var type =  expr[i].substr(expr[i].length - 1, 1);
                switch (type){
                    case 'M':   form.findField("txt_rsptime_months").setValue(value);
                                break;
                    case 'W':   form.findField("txt_rsptime_weeks").setValue(value);
                                break;
                    case 'D':   form.findField("txt_rsptime_days").setValue(value);
                                break;
                    case 'h':   form.findField("txt_rsptime_hours").setValue(value);
                                break;
                    case 'm':   form.findField("txt_rsptime_minutes").setValue(value);
                                break;
                }
            }
            
        }
        expr = rec.data.expr_deadline.split(':');
        for (i=0; i < expr.length; i++){
            var value = expr[i].substr(0, expr[i].length - 1);
            if(value != 0){
                var type =  expr[i].substr(expr[i].length - 1, 1);
                switch (type){
                    case 'M':   form.findField("txt_deadline_months").setValue(value);
                                break;
                    case 'W':   form.findField("txt_deadline_weeks").setValue(value);
                                break;
                    case 'D':   form.findField("txt_deadline_days").setValue(value);
                                break;
                    case 'h':   form.findField("txt_deadline_hours").setValue(value);
                                break;
                    case 'm':   form.findField("txt_deadline_minutes").setValue(value);
                                break;
                }
            }
            
        }
        
    }
                
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

    var panel = new Ext.FormPanel({
        labelWidth: 75, // label settings here cascade unless overridden
        url:'save-form.php',
        frame:true,
        title: 'Simple Form with FieldSets',
        bodyStyle:'padding:5px 5px 0',
        width: 400,

        items: [
                
        {
        // column layout with 2 columns
        layout:'column'
        ,defaults:{
            layout:'form'
            ,border:false
            ,xtype:'panel'
            ,bodyStyle:'padding:10px 10px 10px 10px'
        }
        ,items:[
            
            ////////////{
            ////////////// left column
            ////////////columnWidth:0.50,
            ////////////defaults:{anchor:'100%'}
            ////////////,items:[
            ////////////    grid_status
            ////////////]
            ////////////},
            {
            // right column             
            columnWidth:1,
            defaults:{anchor:'100%'},
            items:[
                grid_categories
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
            ,bodyStyle:'padding:10px 10px 10px 10px'
        }
        ,items:[{
            // left column
            columnWidth:1,
            defaults:{anchor:'100%'}
            ,items:[
                grid_labels
            ]
            },
            {
            // right column             
            columnWidth:0.50,
            defaults:{anchor:'100%'},
            items:[
                //grid_status
            ]
            }                   
        ]
        }
        ]
    });
    
    var category_export = function(sel){
        var sel = check_categories_sm.getSelections();
        var ids = [];
        Ext.each( sel, function(s){
            ids.push( s.data.id );
        });
        Baseliner.ajaxEval('/topicadmin/export', { id_category: ids }, function(res){
            if( !res.success ) {
                Baseliner.error( _('Export'), res.msg );
                return;
            }
            var data_paste = new Baseliner.MonoTextArea({ value: res.yaml });
            var win = new Baseliner.Window({
                title: _('Export'),
                width: 800, height: 400, layout:'fit',
                items: data_paste
            });
            win.show();
        });
    };
    
    var category_import = function(){
        var data_paste = new Baseliner.MonoTextArea({ flex:1 });
        var results = new Baseliner.MonoTextArea({ flex:1 });
        var win = new Baseliner.Window({
            title: _('Import'),
            width: 800, height: 400, layout:'vbox',
            layout: { type: 'vbox', align: 'stretch' },
            items: [ data_paste, results ],
            tbar:[
                { text:_('Import'), 
                    icon: '/static/images/icons/import.png',
                    handler: function(){
                        Baseliner.ajaxEval('/topicadmin/import', { yaml: data_paste.getValue() }, function(res){
                            if( !res.success ) {
                                Baseliner.error( _('Import'), res.msg );
                                if( ! Ext.isArray( res.log ) ) res.log=[];
                                results.setValue( res.log.join("\n") + "\n" + res.msg )
                                results.el.setStyle('font-color', 'red');
                                return;
                            } else {
                                if( ! Ext.isArray( res.log ) ) res.log=[];
                                results.setValue( res.log.join("\n") + "\n" + res.msg )
                                results.el.setStyle('font-color', 'green');
                                Baseliner.message(_('Import'), res.msg );
                                grid_categories.getStore().reload();
                            }
                        });
                    }
                }
            ]
        });
        win.show();
    };

    store_status.load();
    store_category.load();
    
    store_label.load();
    
    return panel;
})
