<%perl>
    use Baseliner::Utils;
    my $id = _nowstamp;
</%perl>

(function(){
    var store_status = new Baseliner.Topic.StoreStatus();
    var store_category = new Baseliner.Topic.StoreCategory();
    
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
    var store_priority = new Baseliner.Topic.StorePriority();
	
	var store_config_priority = new Baseliner.JsonStore({
		root: 'data' , 
		remoteSort: true,
		totalProperty:"totalCount", 
		id: 'id', 
		url: '/topicadmin/get_config_priority',
		fields: [
			{  name: 'id' },
			{  name: 'id_category' },
			{  name: 'name' },
			{  name: 'response_time_min' },
			{  name: 'expr_response_time' },
			{  name: 'deadline_min' },
			{  name: 'expr_deadline' },
			{  name: 'is_active' }  
		]
	});
	
	var store_config_field = new Baseliner.JsonStore({
		root: 'data' , 
		remoteSort: true,
		totalProperty:"totalCount", 
		id: 'id', 
		url: '/topicadmin/get_config_field',
		fields: [
			{ name: 'id' },
			{ name: 'label' },
			{ name: 'default' },
			{ name: 'values' }
		]
	});		
    
    var init_buttons_category = function(action) {
        eval('btn_edit_category.' + action + '()');
        eval('btn_delete_category.' + action + '()');
        eval('btn_form_category.' + action + '()');
        eval('btn_admin_category.' + action + '()');
        eval('btn_admin_priority.' + action + '()');
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
                        {boxLabel: _('Final'), inputValue: 'F'}
                    ]
                },
                Baseliner.combo_baseline(),
                { xtype:'textfield', name:'seq', fieldLabel:_('Position') },
                { xtype:'checkbox', name:'frozen', boxLabel:_('Frozen') },
                { xtype:'checkbox', name:'readonly', boxLabel:_('Readonly') }
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
        var str = val == 'G' ? _('General') : val == 'I' ? _('Initial') : _('Final');
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
            check_status_sm,
            { header: _('Topics: Status'), dataIndex: 'name', width:100, sortable: false, renderer: render_status },
            { header: _('Description'), dataIndex: 'description', sortable: false },
            { header: _('Baseline'), dataIndex: 'bl', sortable: false, renderer: Baseliner.render_bl },
            { header: _('Type'), dataIndex: 'type', width:50, sortable: false, renderer: render_status_type }
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
        
        //   Color settings 
        var category_color = new Ext.form.Hidden({ name:'category_color' });

        var color_pick = new Ext.ColorPalette({ 
            value:'FF43B8',
            listeners: {
                select: function(cp, color){
                   category_color.setRawValue( '#' + color.toLowerCase() ); 
                }
            },
            colors: [
                'FF43B8', '30BED0', 'A01515', 'A83030', '003366', '000080', '333399', '333333',
                '800000', 'FF6600', '808000', '008000', '008080', '0000FF', '666699', '808080',
                'FF0000', 'FF9900', '99CC00', '339966', '33CCCC', '3366FF', '800080', '969696',
                'FF00FF', 'FFCC00', 'FFFF00', '00ACFF', '20BCFF', '00CCFF', '993366', 'C0C0C0',
                'FF99CC', 'DDAA55', 'BBBB77', '88CC88', 'CCFFFF', '99CCFF', 'CC99FF', '11B411'
            ]
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
                { xtype:'textfield', name:'name', fieldLabel:_('Category'),
				  allowBlank:false, emptyText:_('Name of category'),
				  regex: /^[^\.]+$/,
				  regexText: _('Character dot not allowed')
				},
                ta,
                {
                    xtype: 'radiogroup',
                    id: 'categorygroup',
                    fieldLabel: _('Type'),
                    defaults: {xtype: "radio",name: "type"},
                    items: [
                        {boxLabel: _('Normal'), inputValue: 'N', checked: true},
                        {boxLabel: _('Changeset'), inputValue: 'C'},
                        {boxLabel: _('Release'), inputValue: 'R'}
                    ]
                }
                ,{ xtype:'button', text:'Select Color', menu:{ items: color_pick } },
                { xtype: 'panel', style: { 'margin-top': '20px' }, layout: 'form', items: [ combo_providers ] },
                { xtype:'checkboxgroup', name:'readonly', fieldLabel:_('Options'),
                    items:[
                        { xtype:'checkbox', name:'readonly', boxLabel:_('Readonly') },
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
                { header: _('Topics: Status'), dataIndex: 'name', width:50, sortable: false },
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
           items: [ grid_category_status, ]};      
        
        
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
            var ff = form_category.getForm();
            ff.loadRecord( rec );
            title = 'Edit category';
        }
        
        win = new Ext.Window({
            title: _(title),
            width: 750,
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
    

    var add_edit_admin_category = function(rec) {
        var win;
        var title = _('Workflow: %1', rec.data.name );

        var store_category_status = new Baseliner.Topic.StoreCategoryStatus();
        var store_admin_status = new Baseliner.Topic.StoreCategoryStatus({
                listeners: {
                    'load': function( store, rec, obj ) {
                        statusCbx = Ext.getCmp('status-combo_<%$id%>');
                        store.filter( { fn   : function(record) {
                        
                                                                    return record.get('name') != statusCbx.getRawValue();
                                                                }
                                                    });
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
            //readOnly: true
        });     
        
        //var column1 = {
        //    xtype:'panel',
        //    columnWidth:0.50,
        //    layout:'form',
        //    defaults:{anchor:'100%'},
        //    items: [
        //        { xtype: 'hidden', name: 'id', value: -1 },
        //        { xtype:'textfield', name:'name', fieldLabel:_('Category'), readOnly:true, allowBlank:false, emptyText:_('Name of category') },
        //        ta
        //    ]
        //};
        
        var check_admin_status_sm = new Ext.grid.CheckboxSelectionModel({
            singleSelect: false,
            sortable: false,
            checkOnly: true
        });
        
        var job_type_switch = function( rec, data ) {
            var sel = check_admin_status_sm.getSelections();
            var flag = true;
            for( var i=0; i<sel.length; i++ ) {
                var bl = sel[i].data.bl;
                if( bl==undefined || bl == ''  || bl == '*' ) 
                    flag = false;
            }
            if( flag && ( rec.data.is_changeset==1 || rec.data.is_release )
                && data.bl!= undefined && data.bl!='' && data.bl != '*' ) {
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
                //{ header: _('Description'), dataIndex: 'description', sortable: false } 
            ],
            autoSizeColumns: true,
            deferredRender:true/*,
            listeners: {
                viewready: function() {
                    var me = this;
                    
                    var datas = me.getStore();
                    alert('pasa');
                    //var recs = [];
                    //datas.each(function(row, index){
                    //    if(rec.data.statuses){
                    //        for(i=0;i<rec.data.statuses.length;i++){
                    //            if(row.get('id') == rec.data.statuses[i]){
                    //                recs.push(index);   
                    //            }
                    //        }
                    //    }                       
                    //});
                    //me.getSelectionModel().selectRows(recs);                    
                }
            }   */
        });         
        
        var column2 = {
           xtype:'panel',
           defaults:{anchor:'98%'},
           columnWidth:0.50,
           items: grid_admin_status
        };
        
        //store_admin_status.load();                
        
        var combo_status = new Ext.form.ComboBox({
            mode: 'local',
            id: 'status-combo_<%$id%>',
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
                        store_admin_status.filter( {    fn   : function(record) {
                                                                    return record.get('name') != r.data.name;
                                                                },scope:this
                                                    });
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
                    //tag_project_html = tag_project_html ? tag_project_html + ',' + rec.data.projects[i].project: rec.data.projects[i].project;
                    tag_project_html = tag_project_html + "<div id='boot' class='alert' style='float:left'><button class='close' data-dismiss='alert'>×</button>" + rec.data.projects[i].project + "</div>";
                }
            }
            return tag_project_html;
        };
    
        var render_statuses_to = function (val){
            if( val == null || val == undefined ) return '';
            if( typeof val != 'object' ) return '';
            var str = ''
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
                    {name: 'statuses_to' }  
            ]
        );
        
        var store_categories_admin = new Baseliner.GroupingStore({           
            reader: reader,
            url: '/topicadmin/list_categories_admin',
            groupField: 'role',
            sortInfo:{field: 'role', direction: "ASC"}
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
            deferredRender:true
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
                        text: _('Add'),
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

                                form.submit({
                                    params: {action: action, idsroles: roles_checked, idsstatus_to: statuses_to_checked},
                                    success: function(f,a){
                                        Baseliner.message(_('Success'), a.result.msg );
                                        store_categories_admin.load({params:{categoryId: rec.data.id}});
                                        //form.findField("id").setValue(a.result.category_id);
                                        //store_category.load();
                                        //win.setTitle(_('Edit category'));
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
                        text: _('Delete'),
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
                        html: String.format( '<span id="boot"><span class="badge" style="background-color: {0}">{1}</span></span>',
                                                                rec.data.color, rec.data.name ) },
                //{ xtype:'textfield', hidden: true, name:'name', fieldLabel:_('Category'), disabled: true,  emptyText:_('Name of category') },
                //ta,
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
            //title = 'Edit category';
        }
        
        win = new Ext.Window({
            title: _(title),
            width: 700,
            autoHeight: true,
            items: [form_category_admin,
                    grid_categories_admin
            ]
        });
        win.show();     
    };
    
    
	Baseliner.store.Fields = function(c) {
		 Baseliner.store.Fields.superclass.constructor.call(this, Ext.apply({
			root: 'data' , 
			remoteSort: true,
			autoLoad: true,
			totalProperty:"totalCount", 
			baseParams: {},
			id: 'id', 
			url: '/topicadmin/list_fields',
			fields: ['id','params','name'] 
		 }, c));
	};
	Ext.extend( Baseliner.store.Fields, Baseliner.JsonStore );
    
	Baseliner.model.Fields = function(c) {
		//var tpl = new Ext.XTemplate( '<tpl for="."><div class="search-item {recordCls}">{name} - {title}</div></tpl>' );
		var tpl_list = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item">',
			'<span id="boot" style="width:200px"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: {color}">{[_(values.id)]}</span></span>',
			'&nbsp;&nbsp;<b>{title}</b></div></tpl>' );
		var tpl_field = new Ext.XTemplate( '<tpl for=".">',
			'<span id="boot"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: {color}">{[_(values.id)]}</span></span>',
			'</tpl>' );
		Baseliner.model.Fields.superclass.constructor.call(this, Ext.apply({
			allowBlank: true,
			msgTarget: 'under',
			allowAddNewData: true,
			addNewDataOnBlur: true, 
			//emptyText: _('Enter or select topics'),
			triggerAction: 'all',
			resizable: true,
			mode: 'local',
			fieldLabel: _('Fields'),
			typeAhead: true,
			name: 'fields',
			displayField: 'id',
			hiddenName: 'fields',
			valueField: 'id',
			tpl: tpl_list,
			displayFieldTpl: tpl_field,
			extraItemCls: 'x-tag',
			//preventDuplicates: false,
			removeValuesFromStore: false
		}, c));
	};
	Ext.extend( Baseliner.model.Fields, Ext.ux.form.SuperBoxSelect );

	var field_box_store = new Baseliner.store.Fields();
    
    var edit_form_category = function(rec) {
        var win;
        var title = _('Create fields');
		var config = new Array();
		var fields = new Array();
		var names_fields = new Array();
		
        var field_box = new Baseliner.model.Fields({
            store: field_box_store
        });
		
        //field_box_store.on('load',function(){
			//alert(rec.data.fields);
			//alert('rec data: ' + rec.data.fields );
            field_box.setValue( rec.data.fields ) ;            
        //});
		
		field_box.on('additem',function( obj, value, row){
			//if(row.data.config){
			
				//alert('add item: ' + value);
				//for(i=0;i<names_fields.length;i++){
				//	alert('ele: ' + names_fields[i]);
				//}
				//alert('row data: ' + row.data.params);
			
				if (names_fields.indexOf(value)!= -1){
					//alert('Encontrado');	
				}else{
					//alert('No Encontrado');
					names_fields.push(value);
					fields.push(Ext.util.JSON.encode(row.data.params));
					//alert('fields ' + value + ':' + Ext.util.JSON.encode(row.data.params));
				}
				
				
				
				//config.push({"text": _(row.data.name) , "leaf": true,  "id": row.data.id, "config": row.data.name });	
			//}
		});
		
		field_box.on('removeitem',function( obj, value, row){
			var obj_store = obj.getStore();
			var index = obj_store.indexOf(row);
			fields.splice(index,1);
		});		
		
		

        //////// --------------- Forms 
        //////var form_category_store = new Baseliner.JsonStore({
        //////    root: 'data' , 
        //////    remoteSort: true,
        //////    autoLoad: true,
        //////    totalProperty:"totalCount", 
        //////    baseParams: {},
        //////    id: 'form_path', 
        //////    url: '/topicadmin/list_forms',
        //////    fields: ['form_name','form_path'] 
        //////});
        //////var fc_tpl_list = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item">{form_name}</div></tpl>');
        //////var fc_tpl_field = new Ext.XTemplate( '<tpl for=".">{form_name}</tpl>' );
        //////
        //////var form_category_select = new Ext.ux.form.SuperBoxSelect({
        //////    store: form_category_store,
        //////    allowBlank: true,
        //////    msgTarget: 'under',
        //////    //allowAddNewData: true,
        //////    //addNewDataOnBlur: true, 
        //////    emptyText: _('Select forms to add to the category'),
        //////    triggerAction: 'all',
        //////    resizable: true,
        //////    mode: 'remote',
        //////    fieldLabel: _('Forms'),
        //////    typeAhead: true,
        //////        name: 'forms',
        //////        hiddenName: 'forms',
        //////        displayField: 'form_name',
        //////        valueField: 'form_name',
        //////    tpl: fc_tpl_list,
        //////    displayFieldTpl: fc_tpl_field,
        //////    extraItemCls: 'x-tag'
        //////});
		
		
		    var btn_clone_field = new Ext.Toolbar.Button({
			    text: _('Custom field'),
			    icon:'/static/images/icons/wrench.png',
			    cls: 'x-btn-text-icon',
			    handler: function() {
			
					var clone_field_store = new Baseliner.store.Fields({
						url: '/topicadmin/list_clone_fields'
					});
					
					var filter_store = new Baseliner.JsonStore({
						root: 'data' , 
						remoteSort: true,
						totalProperty:"totalCount", 
						id: 'id', 
						url: '/topicadmin/list_filters',
						fields: [
							{  name: 'name' },
							{  name: 'filter_json' }
						]
					});
					
					filter_store.load();
					
					var btn_cerrar_clone_field = new Ext.Toolbar.Button({
						text: _('Close'),
						width: 50,
						handler: function() {
							winCloneField.close();
						}
					})
					
					var btn_grabar_clone_field = new Ext.Toolbar.Button({
						text: _('Save'),
						width: 50,
						handler: function(){
							var v = combo_type_clone_field.getValue();
							var row = combo_type_clone_field.findRecord(combo_type_clone_field.valueField || combo_type_clone_field.displayField, v);
							
							var form = form_clone_field.getForm();
							
							if (form.isValid()) {
								form.submit({
									params: { id_category: rec.id, params: Ext.util.JSON.encode(row.data.params) },
									success: function(f,a){
										Baseliner.message(_('Success'), a.result.msg );
										//rec.data.fields.push(form.findField("name_field").getValue());
										
										var lista = field_box.getValue();
										var list_fields = lista.split(',');
										var name_field = form.findField("name_field").getValue()
										row.data.params.origin = 'custom';
										row.data.params.id_field = name_field;
										row.data.params.name_field = name_field;
										if (row.data.params.rel_field){
											row.data.params.rel_field = name_field;
										}
										list_fields.push(name_field);
								
										var record_meta = Ext.data.Record.create([
											{name: 'id'},
											{name: 'params'}
										]);
										
										var record = new record_meta({
											id: form.findField("name_field").getValue(),
											params: row.data.params
										});
										//****************************************************
										//fields.push(Ext.util.JSON.encode(row.data.params));
										//****************************************************
										
										field_box_store.add(record);
										field_box_store.commitChanges();
										
										field_box.setValue( list_fields );

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
					})

					var combo_type_clone_field = new Ext.form.ComboBox({
						mode: 'local',
						triggerAction: 'all',
						forceSelection: true,
						editable: false,
						fieldLabel: _('Type'),
						name: 'cmb_clone_field',
						hiddenName: 'field',
						displayField: 'name',
						valueField: 'id',
						//En un futuro se cargaran los distintos Host
						store: clone_field_store
					});
					
					combo_type_clone_field.on('select', function(cmb,row,index){
						if (row.data.params.filter){
							combo_filters.show();
						}else{
							combo_filters.hide();
						};
					});
					
					var combo_filters = new Ext.form.ComboBox({
						mode: 'local',
						triggerAction: 'all',
						forceSelection: true,
						editable: false,
						fieldLabel: _('Filter'),
						name: 'cmb_filter',
						hiddenName: 'filter',
						displayField: 'name',
						valueField: 'filter_json',
						hidden: true,						
						store: filter_store
					});					
					
					
					var form_clone_field = new Ext.FormPanel({
						name: 'form_clone_field',
						url: '/topicadmin/create_clone',
						frame: true,
						buttons: [btn_grabar_clone_field, btn_cerrar_clone_field],
						defaults:{anchor:'100%'},
						items   : [
									{ fieldLabel: _('Field'), name: 'name_field', xtype: 'textfield', allowBlank:false},
									combo_type_clone_field,
									combo_filters
								]
					});

					//if(rec){
					//	var ff = form_config.getForm();
					//	ff.loadRecord( rec );
					//	title = 'Edit configuration';
					//}
						
				    var winCloneField = new Ext.Window({
					    modal: true,
					    width: 500,
					    title: _('Custom field'),
					    items: [form_clone_field]
				    });
				    winCloneField.show();
			    }
		    });
		
		
		
		
		
		
		    var btn_config_fields = new Ext.Toolbar.Button({
			    text: _('Parameters'),
			    icon:'/static/images/icons/cog_edit.png',
			    cls: 'x-btn-text-icon',
				hidden: true,
			    handler: function() {
					
				    store_config_field.removeAll();
				    
				    var treeRoot = new Ext.tree.AsyncTreeNode({
					    text: _('Configuration'),
					    expanded: true,
					    draggable: false,
					    children: config
				    });
				    
		    
				    var tree_fields = new Ext.tree.TreePanel({
					    title: _('Configuration Fields'),
					    split: true,
					    colapsible: true,
					    useArrows: true,
					    animate: true,
					    containerScroll: true,
					    autoScroll: true,
					    height:300,		    
					    rootVisible: true,
					    root: treeRoot
				    });
				    
				    tree_fields.on('click', function(node, checked) {
						store_config_field.removeAll();
					    store_config_field.load({params: {config: node.attributes.config, id: node.attributes.id }});
				    });				
			    
				    var blank_image = new Ext.BoxComponent({autoEl: {tag: 'img', src: Ext.BLANK_IMAGE_URL}, height:10});
				    
				    var edit_config = function(rec) {
					    var win_config;
    
					    var btn_cerrar_config = new Ext.Toolbar.Button({
						    text: _('Close'),
						    width: 50,
						    handler: function() {
							    win_config.close();
						    }
					    })
					    
					    var btn_grabar_config = new Ext.Toolbar.Button({
						    text: _('Save'),
						    width: 50,
						    handler: function(){
							//    var form = form_config.getForm();
							//    
							//    var ff_dashboard = form_dashboard.getForm();
							//    var dashboard_id = ff_dashboard.findField("id").getValue();
							//    
							//    if (form.isValid()) {
							//	    form.submit({
							//		    params: { id_dashboard: dashboard_id, id: rec.data.id, dashlet: rec.data.dashlet },
							//		    success: function(f,a){
							//			    Baseliner.message(_('Success'), a.result.msg );
							//			    store_config.reload();
							//		    },
							//		    failure: function(f,a){
							//		    Ext.Msg.show({  
							//			    title: _('Information'), 
							//			    msg: a.result.msg , 
							//			    buttons: Ext.Msg.OK, 
							//			    icon: Ext.Msg.INFO
							//		    }); 						
							//		    }
							//	    });
							//    }
						    }
					    })
    


						var combo_field = new Ext.form.ComboBox({
							mode: 'local',
							value: rec.data.default,
							triggerAction: 'all',
							forceSelection: true,
							editable: false,
							fieldLabel: _(rec.data.id),
							//name: 'cmb_field',
							//hiddenName: 'field',
							//displayField: 'name',
							//valueField: 'name',
							//En un futuro se cargaran los distintos Host
							store: rec.data.values
						}); 						
						
						
					    var form_config = new Ext.FormPanel({
						    name: form_dashlets,
						    url: '/dashboard/set_config',
						    frame: true,
						    buttons: [btn_grabar_config, btn_cerrar_config],
						    defaults:{anchor:'100%'},
						    items   : [
									    //{ fieldLabel: _(rec.data.id), name: 'value', xtype: 'textfield', allowBlank:false}
										combo_field
								    ]
					    });
    
					    if(rec){
						    var ff = form_config.getForm();
						    ff.loadRecord( rec );
						    title = 'Edit configuration';
					    }
    
					    win_config = new Ext.Window({
						    title: _(title),
						    autoHeight: true,
						    width: 400,
						    closeAction: 'close',
						    modal: true,
						    items: [
							    form_config
						    ]
					    });
					    win_config.show();
					    
				    }
				    
				    var grid_config = new Ext.grid.GridPanel({
					    title: _('Configuration'),
					    store: store_config_field,
					    stripeRows: true,
					    autoScroll: true,
					    autoWidth: true,
					    viewConfig: {
						    forceFit: true
					    },		    
					    height:300,
					    columns: [
						    { header: _('Property'), dataIndex: 'id', width: 100},
						    { header: _('Value'), dataIndex: 'default', width: 80}
					    ],
					    autoSizeColumns: true
				    });
				    
				    grid_config.on("rowdblclick", function(grid, rowIndex, e ) {
					    var sel = grid.getStore().getAt(rowIndex);
					    edit_config(sel);
				    });				
		    
				    var form_dashlets = new Ext.FormPanel({
					    name: form_dashlets,
					    url: '/user/update',
					    frame: true,
					    items   : [
							       {
								    xtype: 'panel',
								    layout: 'column',
								    items:  [
									    {  
									    columnWidth: .49,
									    items:  tree_fields
									    },
									    {
									    columnWidth: .02,
									    items: blank_image
									    },
									    {  
									    columnWidth: .49,
									    items: grid_config
								    }]  
								    }
							    ]
				    });
				    
				    var winYaml = new Ext.Window({
					    modal: true,
					    width: 800,
					    title: _('Parameters'),
					    tbar: [
							    {   xtype:'button',
								    text: _('Close'),
								    iconCls:'x-btn-text-icon',
								    icon:'/static/images/icons/leave.png',
								    handler: function(){
									    winYaml.close();
								    }
							    }           
					    ],
					    items: form_dashlets
				    });
				    winYaml.show();
			    }
		    });
		
		
		
        var form_category = new Ext.FormPanel({
            frame: false,
            border: false,
            url:'/topicadmin/update_fields',
            bodyStyle:'padding: 10px 0px 0px 10px',
            buttons: [
					btn_clone_field,
					btn_config_fields,
                    {
                        text: _('Accept'),
                        type: 'submit',
                        handler: function() {
                            var form = form_category.getForm();
                            if (form.isValid()) {
								
									//for(i=0;i<fields.length;i++){
									//	alert('campos: ' + fields[i]);
									//}								
								
                                form.submit({
									params: {values: fields},
                                    success: function(f,a){
                                        Baseliner.message(_('Success'), a.result.msg );
										store_category.load();
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
                            store_category.reload();
							fields = undefined;
                            win.close();
                        }
                    }
            ],
            defaults: { anchor:'95%'},
            items: [
                { xtype: 'hidden', name: 'id'},
                field_box,
                ////////form_category_select,
                { xtype : "fieldset", title : _("Main"), collapsible: true, autoHeight : true, hidden: true, items: [ ] }
            ]
        });

        if(rec){
            var ff = form_category.getForm();
            ff.loadRecord( rec );
            title = _('Edit fields');
        }

        ////////form_category_store.on('load', function(){
        ////////    if( rec && rec.data.forms != undefined ) {
        ////////        form_category_select.setValue( rec.data.forms[0] );    
        ////////    }
        ////////});
        
        win = new Ext.Window({
            title: _(title),
            width: 700,
            autoHeight: true,
            items: form_category
        });
        win.show();     
    };

    var btn_form_category = new Ext.Toolbar.Button({
        text: _('Fields'),
        icon:'/static/images/icons/detail.png',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
            var sm = grid_categories.getSelectionModel();
            if (sm.hasSelection()) {
                var sel = sm.getSelected();
                edit_form_category(sel);
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
	
    var add_edit_admin_priority = function(rec) {
        var win;
        var title = _('Priorities' );
		var config = new Array();
		store_config_priority.removeAll();
		
		store_priority.each(function(row, index){
			var ok = rec.data.priorities.indexOf(row.data.id);
			config.push({"text": _(row.data.name), "leaf": true, "id": row.data.id, "category_id": rec.data.id, "cls": ok != -1 ?'priority':'' });	
		});
		
		var treeRoot = new Ext.tree.AsyncTreeNode({
			text: _('Configuration'),
			expanded: true,
			draggable: false,
			children: config
		});
		
		var tree_priorities = new Ext.tree.TreePanel({
			title: _('Configuration Priorities'),
			split: true,
			colapsible: true,
			useArrows: true,
			animate: true,
			containerScroll: true,
			autoScroll: true,
			height:300,		    
			rootVisible: true,
			root: treeRoot
		});
		
		tree_priorities.on('click', function(node, checked) {
			store_config_priority.load({params: {id: node.attributes.id, category_id: node.attributes.category_id}});
		});				
							
		var grid_config_priorities = new Ext.grid.GridPanel({
			title: _('Configuration'),
			store: store_config_priority,
			stripeRows: true,
			autoScroll: true,
			autoWidth: true,
			viewConfig: {
				forceFit: true
			},		    
			height:300,
			columns: [
				
				{ header: _('Response time'), dataIndex: 'expr_response_time', sortable: false, renderer: show_expr },
				{ header: _('Deadline'), dataIndex: 'expr_deadline', sortable: false, renderer: show_expr } 
			],
			autoSizeColumns: true
		});
		
		var edit_config_priority = function(rec) {
			var win_config;
			
			var form_config_priority = new Baseliner.form.Priority({
				url:'/topicadmin/update_category_priority'}
			);
			var form = form_config_priority.getForm();
			form.findField("name").readOnly = true;			
		
			if(rec){
				var ff = form_config_priority.getForm();
				ff.loadRecord( rec );
				load_cbx(ff, rec);
				ff.findField("name").readOnly = true;
				ff.findField("priority_active_check").setValue( rec.data.is_active );
				title = 'Edit configuration';
			}
		
			win_config = new Ext.Window({
				title: _(title),
				autoHeight: true,
				width: 400,
				closeAction: 'close',
				modal: true,
				items: [
					form_config_priority
				],
				buttons: [
						{
							text: _('Accept'),
							type: 'submit',
							handler: function() {
								var form = form_config_priority.getForm();
								var action = form.getValues()['id'] >= 0 ? 'update' : 'add';								
								
								var rsptime = new Array();
								var deadline = new Array();
							
								getvalues_priority(form,rsptime,deadline);
								
								if (form.isValid()) {
									form.submit({
										params: {action: action, rsptime: rsptime, deadline: deadline},
										success: function(f,a){
											Baseliner.message(_('Success'), a.result.msg );
											form.findField("id").setValue(a.result.priority_id);
											store_config_priority.reload();
											var node = tree_priorities.getSelectionModel().getSelectedNode();
											if(form.findField("priority_active_check").getValue()){
												node.setCls('priority');
											}else{
												node.setCls('');
											}

											
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
						handler: function() {win_config.close();}
						}
				]
			});
			win_config.show();
		}
		
					
		grid_config_priorities.on("rowdblclick", function(grid, rowIndex, e ) {
			var sel = grid.getStore().getAt(rowIndex);
			edit_config_priority(sel);
		});				

		var blank_image = new Ext.BoxComponent({autoEl: {tag: 'img', src: Ext.BLANK_IMAGE_URL}, height:10});
		
		var pnl_priorities = new Ext.FormPanel({
			frame: true,
			items   : [
					   {
						xtype: 'panel',
						layout: 'column',
						items:  [
							{  
							columnWidth: .49,
							items:  tree_priorities
							},
							{
							columnWidth: .02,
							items: blank_image
							},
							{  
							columnWidth: .49,
							items: grid_config_priorities
						}]  
						}
					]
		});
					
       
        win = new Ext.Window({
            title: _(title),
            width: 800,
            autoHeight: true,
			modal: true,
			tbar: [
					{   xtype:'button',
						text: _('Close'),
						iconCls:'x-btn-text-icon',
						icon:'/static/images/icons/leave.png',
						handler: function(){
							win.close();
						}
					}           
			],
            items: pnl_priorities
        });
		
        win.show();     
    };	
	
    var btn_admin_priority = new Ext.Toolbar.Button({
        text: _('Priorities'),
        icon:'/static/images/icons/hourglass.png',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
            var sm = grid_categories.getSelectionModel();
            if (sm.hasSelection()) {
                var sel = sm.getSelected();
                add_edit_admin_priority(sel);
            } else {
                Baseliner.message( _('ERROR'), _('Select at least one row'));    
            };          
		}
    }); 	
    
    var check_categories_sm = new Ext.grid.CheckboxSelectionModel({
        singleSelect: false,
        sortable: false,
        checkOnly: true
    });
    
    var render_category = function(value,metadata,rec,rowIndex,colIndex,store){
        var color = rec.data.color;
        var ret = '<div id="boot"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: '+ color + '">' + value + '</span></div>';
        return ret;
    };

    var grid_categories = new Ext.grid.GridPanel({
        title : _('Categories'),
        sm: check_categories_sm,
        height: 350,
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
            { header: _('Category'), dataIndex: 'name', width:50, sortable: false, renderer: render_category },
            { header: _('Description'), dataIndex: 'description', sortable: false },
            { header: _('Type'), dataIndex: 'type', width:50, sortable: false, renderer: render_category_type }
        ],
        autoSizeColumns: true,
        deferredRender:true,    
        tbar: [ 
                btn_add_category,
                btn_edit_category,
                btn_delete_category,
                '->',
                btn_form_category,
                btn_admin_category,
				btn_admin_priority
        ]       
    }); 
    /* grid_categories.on('rowdblclick', function(grid, rowIndex, columnIndex, e) {
        
    }); */
    
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
                    btn_form_category.disable();
                    btn_admin_category.disable();
					btn_admin_priority.disable();
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
            }
        }
    });
    
    
    var btn_add_label = new Ext.Toolbar.Button({
        text: _('New'),
        icon:'/static/images/icons/add.gif',
        cls: 'x-btn-text-icon',
        handler: function() {
            if(label_box.getValue() != ''){
                Baseliner.ajaxEval( '/topicadmin/update_label?action=add',{ label: label_box.getValue(), color: '#' + color_lbl},
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
                Baseliner.ajaxEval( '/topicadmin/update_label?action=add',{ label: label_box.getValue(), color: '#' + color_lbl},
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
                    text:   _('Pick a Color'),
                    menu:   colorMenu
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
    
	
	Baseliner.form.Priority = function(c) {
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

		var priority_active_check = new Ext.form.Checkbox({
			name: 'priority_active_check',
			boxLabel: _('Active')
		});
		
		Baseliner.form.Priority.superclass.constructor.call(this, Ext.apply({
					frame: true,
					bodyStyle:'padding:10px 10px 0',
					defaults: { anchor:'100%'},
					items: [
						{ xtype: 'hidden', name: 'id', value: -1 },
						{ xtype: 'hidden', name: 'id_category', value: -1 },
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
													title: _('Response time'),
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
													title: _('Deadline'),
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
									},
									priority_active_check
							]
						}
					]
		}, c));
	};
	Ext.extend( Baseliner.form.Priority, Ext.FormPanel );	
	
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
				
	function getvalues_priority(form,rsptime,deadline){
		//var rsptime = new Array();
		//var deadline = new Array();
		
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
		rsptime[1] = (txt_rsptime_months * 31 * 24 * 60 ) + (txt_rsptime_weeks * 7 * 24 * 60 ) + (txt_rsptime_days * 24 * 60 ) + (txt_rsptime_hours * 60) + txt_rsptime_minutes;
		
		deadline[0] = txt_deadline_months + 'M:' + txt_deadline_weeks + 'W:' + txt_deadline_days + 'D:' + txt_deadline_hours + 'h:' + txt_deadline_minutes + 'm';
		deadline[1] = (txt_deadline_months * 31 * 24 * 60 ) + (txt_deadline_weeks * 7 * 24 * 60 ) + (txt_deadline_days * 24 * 60 ) + (txt_deadline_hours * 60) + txt_deadline_minutes;
	}
	
    var add_edit_priority = function(rec) {
        var win;
        var title = 'Create priority';

		var form_priority = new Baseliner.form.Priority({
			url:'/topicadmin/update_priority'}
		);
		
		var form = form_priority.getForm();
		form.findField("priority_active_check").hidden = true;
		
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
            items: form_priority,
		    buttons: [
					{
						text: _('Accept'),
						type: 'submit',
						handler: function() {
							var form = form_priority.getForm();
							var action = form.getValues()['id'] >= 0 ? 'update' : 'add';
							
							var rsptime = new Array();
							var deadline = new Array();
							
							getvalues_priority(form,rsptime,deadline);
							
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
					handler: function() {win.close();}
					}
			]
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
                    Baseliner.ajaxEval( '/topicadmin/update_priority?action=delete',{ idspriority: priorities_checked },
                        function(response) {
                            if ( response.success ) {
                                Baseliner.message( _('Success'), response.msg );
                                init_buttons_priority('disable');
                                store_priority.load();
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
        height: 250,
        autoScroll: true,
        header: true,
        stripeRows: true,
        enableHdMenu: false,
        store: store_priority,
        viewConfig: {forceFit: true, scrollOffset: 2},
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
            //filtrar_topics(labels_checked, categories_checked);
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
            //filtrar_topics(labels_checked, categories_checked);
            if(priorities_checked.length == 0){
                init_buttons_priority('disable');
            }else{
                btn_delete_priority.enable();
                btn_edit_priority.disable();
            }
        }
    }); 
    

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
        ,items:[{
            // left column
            columnWidth:0.50,
            defaults:{anchor:'100%'}
            ,items:[
                grid_status
            ]
            },
            {
            // right column             
            columnWidth:0.50,
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
            columnWidth:0.50,
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
                grid_priority
            ]
            }                   
        ]
        }
        ]
    });

    store_status.load();
    store_category.load();
    
    store_label.load();
    store_priority.load();
    
    return panel;
})
