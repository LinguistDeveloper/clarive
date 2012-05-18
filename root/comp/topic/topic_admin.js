<%perl>
    use Baseliner::Utils;
    my $id = _nowstamp;
</%perl>

(function(){
	var store_status = new Baseliner.Topic.StoreStatus();
	var store_category = new Baseliner.Topic.StoreCategory();
	var store_label = new Baseliner.Topic.StoreLabel();
	var store_priority = new Baseliner.Topic.StorePriority();
	
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
            url:'/topic/update_status',
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
                { xtype:'textfield', name:'name', fieldLabel:_('Topics: Status'), allowBlank:false, emptyText:_('Name of status') },
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
                    Baseliner.ajaxEval( '/topic/update_status?action=delete',{ idsstatus: statuses_checked },
                        function(response) {
                            if ( response.success ) {
                                Baseliner.message( _('Success'), response.msg );
                                init_buttons_status('disable');
                                store_status.load();
                                var labels_checked = getLabels();
                                var categories_checked = getCategories();
                                filtrar_topics(labels_checked, categories_checked);
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
        title : _('Topics: Statuses'),
        sm: check_status_sm,
		height: 200,
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
            { header: _('Topics: Status'), dataIndex: 'name', width:50, sortable: false },
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
            filtrar_topics(labels_checked, categories_checked);
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
            filtrar_topics(labels_checked, categories_checked);
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
            url:'/topic/update_category',
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
                    Baseliner.ajaxEval( '/topic/update_category?action=delete',{ idscategory: categories_checked },
                        function(response) {
                            if ( response.success ) {
                                Baseliner.message( _('Success'), response.msg );
                                init_buttons_category('disable');
                                store_category.load();
                                var labels_checked = getLabels();
                                filtrar_topics(labels_checked, null);                               
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
		height: 200,
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
            filtrar_topics(labels_checked, categories_checked);
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
            filtrar_topics(labels_checked, categories_checked);
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
                Baseliner.ajaxEval( '/topic/update_label?action=add',{ label: label_box.getValue(), color: color_lbl},
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
                    Baseliner.ajaxEval( '/topic/update_label?action=delete',{ idslabel: labels_checked },
                        function(response) {
                            if ( response.success ) {
                                Baseliner.message( _('Success'), response.msg );
                                init_buttons_label('disable');
                                store_label.load();
                                var categories_checked = getCategories();
                                filtrar_topics(null, categories_checked);
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
                Baseliner.ajaxEval( '/topic/update_label?action=add',{ label: label_box.getValue(), color: color_lbl},
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
		height: 200,
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
	
    function filtrar_topics(labels_checked, categories_checked){
        var query_id = '<% $c->stash->{query_id} %>';
        store_opened.load({params:{start:0 , limit: ps, filter:'O', query_id: '<% $c->stash->{query_id} %>', labels: labels_checked, categories: categories_checked}});
        store_closed.load({params:{start:0 , limit: ps, filter:'C', labels: labels_checked, categories: categories_checked}});      
    };

    grid_labels.on('cellclick', function(grid, rowIndex, columnIndex, e) {
        if(columnIndex == 1){
            var labels_checked = getLabels();
            var categories_checked = getCategories();
            filtrar_topics(labels_checked, categories_checked);
            init_buttons_label('enable');
        }
    });
    
    grid_labels.on('headerclick', function(grid, columnIndex, e) {
        if(columnIndex == 1){
            var labels_checked = getLabels();
            var categories_checked = getCategories();
            filtrar_topics(labels_checked, categories_checked);
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
            url:'/topic/update_priority',
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
                    Baseliner.ajaxEval( '/topic/update_priority?action=delete',{ idspriority: priorities_checked },
                        function(response) {
                            if ( response.success ) {
                                Baseliner.message( _('Success'), response.msg );
                                init_buttons_priority('disable');
                                store_priority.load();
                                var labels_checked = getLabels();
                                var categories_checked = getCategories();
                                filtrar_topics(labels_checked, categories_checked);                             
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
		height: 200,
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
            filtrar_topics(labels_checked, categories_checked);
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
            filtrar_topics(labels_checked, categories_checked);
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
        width: 350,

        items: [{
            xtype:'fieldset',
            title: _('Topics: Statuses'),
            collapsible: true,
            autoHeight:true,
            items :[
				grid_status
            ]
        },{
            xtype:'fieldset',
            title: _('Categories'),
            collapsible: true,
            autoHeight:true,
            items :[
				grid_categories
            ]
        },{
            xtype:'fieldset',
            title: _('Labels'),
            collapsible: true,
            autoHeight:true,
            items :[
				grid_labels
            ]
        },{
            xtype:'fieldset',
            title: _('Priorities'),
            collapsible: true,
            autoHeight:true,
            items :[
				grid_priority
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