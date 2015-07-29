(function(){
    var bl_edit;
    
    var hm = function(){
        new Date( Date.now() ).format('H:i:s')
    }
    var today = function(){
        //new Date( Date.now() ).format('Y-m-d H:i:s')
        new Date( Date.now() ).format('Y-m-d')
    }
    
    var store=new Baseliner.JsonStore({
        root: 'data', 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id', 
        url: '/scheduler/json',
        fields: [ 
            {name: 'id'},
            {name: 'name'},
            {name: 'service'},
            {name: 'id_last_log'},
            {name: 'id_rule'},
            {name: 'what'}, // unused
            {name: 'what_name'}, // rule name, service name
            {name: 'parameters'},
            {name: 'next_exec'},
            {name: 'last_exec'},
            {name: 'description'},
            {name: 'frequency'},
            {name: 'workdays'},
            {name: 'status'},
            {name: 'pid'}
        ]
    });


    var ps = 30; //page_size

    var search_field = new Baseliner.SearchField({
        store: store,
        params: {start: 0, limit: ps },
        emptyText: '<% _loc('<Enter your search string>') %>'
    });

    var button_toggle_activation = new Ext.Toolbar.Button({
        text: _('Activate'),
        hidden: true,
        cls: 'x-btn-text-icon',
        handler: function() {
            toggle_activation();
        }
    });

    var button_new_schedule = new Ext.Toolbar.Button({
        text: _('Create'),
        hidden: false,
        icon:'/static/images/icons/add.gif',
        cls: 'x-btn-text-icon',
        handler: function() {
            var next_exec = new Date( Date.now() ).format('Y-m-d H:i:s');
            edit_window({ next_exec: next_exec });
        }
    });

    var button_edit_schedule = new Ext.Toolbar.Button({
        text: _('Edit'),
        hidden: true,
        icon:'/static/images/icons/edit.gif',
        cls: 'x-btn-text-icon',
        handler: function() {
            bl_edit = true;
            var sm = grid.getSelectionModel();
            if ( sm.hasSelection() ){
                edit_window( sm.getSelected().data );
            } else {
                Baseliner.message(_('Error'), _('Select a row') );
            }     
        }
    });

    var delete_schedule = function () {
        var sm = grid.getSelectionModel();
        if ( sm.hasSelection() ){
            var r = sm.getSelected();
            Baseliner.ajaxEval( '/scheduler/delete_schedule', 
                    { id: r.data.id }, 
                    function(response) {
                        if ( response.success ) {
                            Baseliner.message( _('SUCCESS'), _('Scheduled task deleted') );
                            store.load({params:{ limit: ps }});
                        } else {
                            Baseliner.message( _('ERROR'), _('Scheduled task not deleted') );
                        }
                    }
            );
        }     
    };
    var button_delete_schedule = new Ext.Toolbar.Button({
        text: _('Delete'),
        hidden: true,
        icon:'/static/images/icons/delete_.png',
        cls: 'x-btn-text-icon',
        handler: function() {
            delete_schedule();
        }
    });

    var button_duplicate_schedule = new Ext.Toolbar.Button({
        text: _('Duplicate'),
        hidden: true,
        icon:'/static/images/icons/copy.gif',
        cls: 'x-btn-text-icon',
        handler: function() {
            bl_edit = true;
            var sm = grid.getSelectionModel();
            if ( sm.hasSelection() ){
                var rec = sm.getSelected();
                delete rec.id;
                edit_window(rec);
            } else {
                Baseliner.message(_('Error'), _('Select a row') );
            }     
        }
    });

    var button_run_schedule = new Ext.Toolbar.Button({
        text: _('Run now'),
        hidden: true,
        icon:'/static/images/icons/start.png',
        //icon:'/static/images/silk/clock_play.png',
        cls: 'x-btn-text-icon',
        handler: function() {
            run_schedule();
        }
    });

    var button_kill_schedule = new Ext.Toolbar.Button({
        text: _('Kill'),
        hidden: true,
        icon:'/static/images/silk/clock_stop.png',
        cls: 'x-btn-text-icon',
        handler: function() {
            kill_schedule();
        }
    });

    var tbar = new Ext.Toolbar({ items: [ _('Search') + ': ', ' ',
            search_field, ' ', ' ',
            button_new_schedule,
            button_edit_schedule,
            button_delete_schedule,
            button_duplicate_schedule,
            button_toggle_activation,
            button_run_schedule,
            button_kill_schedule
        ]
    });

    var paging = new Ext.PagingToolbar({
        store: store,
        pageSize: ps,
        displayInfo: true,
        displayMsg: '<% _loc('Rows {0} - {1} of {2}') %>',
        emptyMsg: "No hay registros disponibles"
    });
        
    store.load({params:{start:0 , limit: ps}}); 

    var render_name = function(value, metadata, rec, rowIndex, colIndex, store) {
        var str = value + String.format(' <a target="_blank" href="/scheduler/last_log?id={0}"><img src="/static/images/icons/moredata.gif" /></a>', rec.data.id_last_log);
        return "<div style='font-weight:bold; font-size: 15px;font-family: Calibri, Helvetica Neue, Arial, Arial, sans-serif'>" + str + "</div>" ;
    };

    // create the grid
    var grid = new Ext.grid.GridPanel({
        renderTo: 'main-panel',
        header: false,
        stripeRows: true,
        store: store,
        viewConfig: {
            enableRowBody: true,
            getRowClass: function(record, index, p, store){
                var css='';
                p.body='';
                var parms = record.data.parameters;
                if( parms != undefined ) {
                    p.body +='<p><div style="color: #333; font-weight: bold; margin: 0 0 5 30;">';
                    p.body += '<pre>' + parms + '</pre></div></p>';
                    css += ' x-grid3-row-expanded '; 
                }
                //css += index % 2 > 0 ? ' level-row info-odd ' : ' level-row info-even ' ;
                return css;
            },
            forceFit: true
        },
        selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
        loadMask:'true',
        columns: [
            { header: _('Name'), width: 300, dataIndex: 'name', sortable: true, renderer: render_name },   
            { header: _('Status'), width: 60, dataIndex: 'status', sortable: true },
            { header: _('Next execution'), width: 100, dataIndex: 'next_exec', sortable: true },   
            { header: _('Last execution'), width: 100, dataIndex: 'last_exec', sortable: true },
            { header: _('PID'), width: 60, dataIndex: 'pid', sortable: true },
            { header: _('Description'), width: 200, dataIndex: 'description', sortable: true },
            { header: _('Frequency'), width: 60, dataIndex: 'frequency', sortable: true },
            { header: _('Workdays'), width: 60, dataIndex: 'workdays', sortable: true },
            { header: _('What'), width: 100, dataIndex: 'what_name', sortable: true }
        ],
        bbar: paging,
        tbar: tbar
    });

    grid.getView().forceFit = true;

    grid.on("rowclick", function(grid, rowIndex, e ) {
        var r = grid.getStore().getAt(rowIndex);
        show_buttons();        
    });

    var show_buttons = function () {
        var sm = grid.getSelectionModel();
        var r = sm.getSelected();
        if( r == undefined ) return;

        if ( r.data.status == 'IDLE' || r.data.status == 'KILLED' ) {
            button_run_schedule.show();
            button_toggle_activation.setText( _('Deactivate') );
            button_toggle_activation.setIcon( '/static/images/icons/stop.png');
            button_delete_schedule.show();
            button_toggle_activation.show();
            button_kill_schedule.hide();
        } else if ( r.data.status == 'INACTIVE') {
            button_toggle_activation.setText( _('Activate') );
            button_toggle_activation.setIcon( '/static/images/icons/start.png');
            button_toggle_activation.show();
            button_delete_schedule.show();
            button_run_schedule.show();
            button_kill_schedule.hide();
        } else if ( r.data.status == 'RUNNING' ) {
            button_toggle_activation.hide();
            button_delete_schedule.hide();
            button_run_schedule.hide();
            button_kill_schedule.show();
        }
        button_edit_schedule.show();
        button_duplicate_schedule.show();
        tbar.doLayout();
    };

    var edit_window = function(rec){
    
        var schedule_id = new Ext.form.Hidden({
            name: 'id', value: rec.id
        });

        var schedule_name = new Ext.form.TextField({
            name: 'name',
            fieldLabel: _('Name'),
            width: 150,
            value: rec.name,
            labelWidth: 250
        });

        var schedule_description = new Ext.form.TextArea({
            name: 'description',
            fieldLabel: _('Description'),
            width: 150,
            height: 60,
            value: rec.description,
            labelWidth: 250
        });

        var schedule_parameters = new Ext.form.TextArea({
            name: 'parameters'
        });

        var schedule_date = new Ext.ux.form.DateFieldPlus({
            name: 'date',
            disabled: false,
            readOnly: false,
            fieldLabel: _('Date'),
            allowBlank: false,
            format: 'Y-m-d',
            value: today(),
            minValue: today(),
            noOfMonth : 2,
            noOfMonthPerRow : 2,
            renderTodayButton: false,
            showToday: true,
            multiSelection: false,
            allowMouseWheel:false,
            showWeekNumber: false,
            selectedDates: [],
            showActiveDate:true,
            summarizeHeader:true,
            width: 150,
            labelWidth: 250
        });

        var schedule_time = new Ext.ux.form.Spinner({
            name: 'time',
            format : "H:i",
            fieldLabel: _('Time'),
            allowBlank: false,
            disabled:false,
            value: hm(),
            editable: true,
            width: 150,
            labelWidth: 250,
            strategy: new Ext.ux.form.Spinner.TimeStrategy()
        });

        var schedule_frequency = new Ext.form.TextField({
            name: 'frequency',
            width: 150,
            labelWidth: 250,
            value: rec.frequency,
            fieldLabel: _('Frequency')
        });

        var chk_schedule_workdays = new Ext.form.Checkbox({
            name: 'workdays',
            checked: rec.workdays==1,
            fieldLabel: _('Workdays only')
        });

        var txtconfig;
        var btn_config_service = new Ext.Toolbar.Button({
            text: _('Parameters'),
            icon:'/static/images/icons/cog_edit.png',
            cls: 'x-btn-text-icon',
            disabled: true,
            handler: function() {
                var ta = new Ext.form.TextArea({
                    height: 300,
                    width: 500,
                    enableKeyEvents: true,
                    style: { 'font-family': 'Consolas, Courier, monotype' },
                    value: txtconfig
                });
                
                ta.on('keypress', function(TextField, e) {
                    btn_save_config.enable();
                });             
                
                var title;
                var img_icon;
                var bl_save = false;
                title = 'Apply';
                img_icon = '/static/images/icons/cog_edit.png';		
                
                form = schedule_form.getForm();
                var id = form.findField('id').value;

                if (bl_edit){
                    title = 'Save';
                    img_icon = '/static/images/icons/database_save.png';
                    bl_save = true;
                }
        
                var btn_save_config = new Ext.Toolbar.Button({
                    text: _(title),
                    icon: img_icon,
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        if(bl_save){
                           Baseliner.ajaxEval( '/scheduler/update_conf', { id: id, conf: ta.getValue() },
                               function(resp){
                                        Baseliner.message( _('Success'), resp.msg );
                                        store.load({params:{ limit: ps }});
                                        form = schedule_form.getForm();
                                        form.findField("txt_conf").setValue(ta.getValue());
                                        txtconfig = ta.getValue();
                                        btn_save_config.disable();
                               }
                           );
                        }else{
                           form = schedule_form.getForm();
                           form.findField("txt_conf").setValue(ta.getValue());
                           btn_save_config.disable();
                           
                        }                   
                    }
                });

                var winYaml = new Baseliner.Window({
                    modal: true,
                    width: 500,
                    title: _("Parameters"),
                    tbar: [ 
                        btn_save_config,
                        { xtype:'button', text: _('Close'), iconCls:'x-btn-text-icon', icon:'/static/images/icons/leave.png',
                            handler: function(){
                                winYaml.close();
                            }
                        }			
                    ],
                    items: ta
                });
                winYaml.show();
            }
        });
          
        //var schedule_service = Baseliner.combo_services({ hiddenName: 'service' });
        var store_chain = new Baseliner.JsonStore({
            url: '/rule/list', root: 'data', totalProperty: 'totalCount', id: 'id', 
            fields:['id','rule_name','rule_type', 'rule_desc']
        });
        var resultTpl = new Ext.XTemplate(
            '<tpl for="."><div class="x-combo-list-item">',
            '<span id="boot" style="background: transparent;">',
            '<strong>{rule_name}</strong>',
            '<tpl if="rule_desc">',
                '<br /><span style="color: #ccc">{rule_desc}<span>',
            '</tpl>',
            '</span>',
            '</div></tpl>'
        );
        var schedule_service = new Baseliner.SuperBox({
            singleMode: true,
            fieldLabel: _('Rule'),
                name: 'id_rule',
                displayField:'rule_name',
                hiddenName:'id_rule', 
                valueField: 'id',
            store: store_chain,
            //anchor: '50%',
            mode: 'remote',
            minChars: 0, //min_chars ,
            loadingText: _('Searching...'),
            tpl: resultTpl,
            allowBlank: false,
            value: rec.id_rule,
            editable: false,
            lazyRender: true
        });
        /* store_chain.on('load', function(){
            var row = store_chain.getAt(0);
            if( row ) {
                combo_chain.setValue( row.data.id );
            } else {
                Baseliner.message(_('Job'), _('No job chains available') );
            }
        });
        */
        store_chain.load();
        
        var check_configuration = function(id_service){
            // Baseliner.ajaxEval( '/chain/getconfig', {id: id_service}, function(res) {
            //     if( !res.success ) {
            //         //Baseliner.error( _('YAML'), res.msg );
            //     } else {
            //         // saved ok
            //         //Baseliner.message( _('YAML'), res.msg );
            //         if(res.yaml){
            //             txtconfig = res.yaml;
            //             btn_config_service.enable();
            //         }
            //         else{
            //             btn_config_service.disable();
            //         }
                    
            //     }
            // });
        };
        schedule_service.on('select', function(field, newValue, oldValue) {
            form = schedule_form.getForm();
            form.findField("txt_conf").setValue('');       
            check_configuration(newValue.data.id);
        });
        
        var btn_submit = new Ext.Button({
            text: _('Save'), 
            icon:'/static/images/icons/save.png', 
            handler: function(){
                if ( !valida_hora(schedule_time.getValue() ) ) {
                    Baseliner.error(_('Scheduler'), _('Time not valid'));
                } else {
                    var ff = schedule_form.getForm();
                    ff.submit({
                        success: function(form, action) { 
                            store.load({params:{ limit: ps }});
                            ff.reset();
                            win.close(); 
                        },
                        failure: function(form, action) { 
                            if( action.result ) {
                                Baseliner.error(_('Scheduler'), action.result.msg);
                            } else {
                                Baseliner.error(_('Scheduler'), _('Missing fields') );
                            }
                        }
                    }); 
                }
            }
        });
        
        var txt_conf = new Ext.form.TextArea({ 
            name: 'txt_conf', xtype: 'textarea', 
            hidden: 'true', value: rec.parameters });

        var schedule_form = new Baseliner.FormPanel({
            frame: true,
            url: '/scheduler/save_schedule',
            buttons: [
                btn_submit,
                {
                    text: _('Close'),
                    icon:'/static/images/icons/close.png', 
                    handler: function(){ 
                        win.close();
                    }
                }
            ],
            defaults:{anchor:'100%'},
            items: [ schedule_id, schedule_name,
                    txt_conf,
                    {
                    // column layout with 2 columns
                    layout:'column'
                    ,defaults:{
                            //columnWidth:0.5
                            layout:'form'
                            ,border:false
                            ,xtype:'panel'
                            ,bodyStyle:'padding:0 2px 0 0'
                    }
                    ,items:[{
                                // left column
                                columnWidth:0.86,
                                defaults:{anchor:'100%'},
                                items:[ schedule_service ]
                            },
                            {
                                // right column
                                columnWidth:0.14,
                                defaults:{anchor:'100%'},
                                items:[ btn_config_service ]
                            }
                    ]
                    },                 
                     schedule_date, schedule_time, schedule_frequency, schedule_description, chk_schedule_workdays ]
        });

        var win = new Baseliner.Window({
            autoScroll: true,
            title: _("Schedule information"),
            width: 650, 
            //closeAction: 'hide',
            items: [ schedule_form ]
        });
        
        if ( rec.next_exec ) {
            schedule_date.setValue(rec.next_exec.substring(0,10));
            schedule_time.setValue(rec.next_exec.substring(11,16));
        } else {
            schedule_date.setValue(undefined);
            schedule_time.setValue(undefined);                
        }
        win.show();
    }; // edit_window

    var toggle_activation = function () {
        var sm = grid.getSelectionModel();
        if ( sm.hasSelection() ){
            var r = sm.getSelected();
            Baseliner.ajaxEval( '/scheduler/toggle_activation', 
                    { id: r.data.id, status: r.data.status }, 
                    function(response) {
                        if ( response.success ) {
                            Baseliner.message( _('SUCCESS'), _(response.msg) );
                            store.load({params:{ limit: ps }});
                        } else {
                            Baseliner.message( _('ERROR'), _(response.msg) );
                        }
                    }
            ); 
        }     
    };

    store.on("load", function () {
        show_buttons();
    });

    var run_schedule = function () {
        var sm = grid.getSelectionModel();
        if ( sm.hasSelection() ){
            var r = sm.getSelected();
            Baseliner.ajaxEval( '/scheduler/run_schedule', 
                    { id: r.data.id }, 
                    function(response) {
                        if ( response.success ) {
                            Baseliner.message( _('SUCCESS'), _('Scheduled to run now') );
                            store.load({params:{ limit: ps }});
                        } else {
                            Baseliner.message( _('ERROR'), _('Could not schedule task') );
                        }
                    }
            );

        } else {
            alert(_('Select a row'));
        }     
    };

    var kill_schedule = function () {
        var sm = grid.getSelectionModel();
        if ( sm.hasSelection() ){
            Ext.Msg.confirm(_('Confirm'), _('Are you sure you want to kill the task?'), function(btn, text){
                if (btn == 'yes'){
                //alert('go ahead');
                //} else {
                    var r = sm.getSelected();
                    //alert(r.data.id);
                    Baseliner.ajaxEval( '/scheduler/kill_schedule', 
                            { id: r.data.id }, 
                            function(response) {
                                if ( response.success ) {
                                    Baseliner.message( _('SUCCESS'), _('Task killed') );
                                    store.load({params:{ limit: ps }});
                                } else {
                                    Baseliner.message( _('ERROR'), _('Could not kill task') );
                                }
                            }
                    );
                }
            });
        }
    };

    var valida_hora = function (time) {
        //var regexp = /^([0-1][0-9]|[2][0-3]):([0-5][0-9])$/;
        var regexp = /^(([0]?[1-9]|1[0-2])(:)([0-5][0-9]))$/;

        var returnvalue;
        if ( time ) {
            returnvalue = regexp.test(time);
        } else {
            returnvalue = true;
        }
        return true;
    };
    
    grid.on('rowdblclick', function(grid, rowIndex, columnIndex, e) {
        edit_schedule();
    });
    
    return grid;
})();


