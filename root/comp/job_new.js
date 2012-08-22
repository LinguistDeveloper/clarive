<%args>
    $baselines
</%args>
<%doc>
    job_new.mas - new job creation screen
</%doc>
<%perl>
    use Baseliner::Utils;
    use Baseliner::Sugar;
    use utf8;
    my $iid = "div-" . _nowstamp;
    $c->stash->{job_types} = [
        { name=>'job_type', inputValue=> 'promote', boxLabel => _loc('Promote'), checked=>\1 },
        { name=>'job_type', inputValue=> 'demote', boxLabel => _loc('Demote') },
        ];
    my $now = _dt();
    my $date_format = config_value('calendar_date_format') || '%Y-%m-%d';
    my $today =  $now->strftime( $date_format ); # '%d/%m/%Y'
    ( my $picker_format = $date_format || 'd/m/Y' ) =~ s{%}{}g;

    $baselines = [
        map {
            [ $_->[0], "$_->[0] - $_->[1]" ]
        } _array( $baselines )
    ];
</%perl>
(function(){
    var date_format = '<% $date_format %>';
    var picker_format = '<% $picker_format %>';
    var today = '<% $today %>';
    var min_chars = 3; 

    function parseToDate(strDate){
        var dia = parseInt(strDate.substr(0,2),"10");
        var mes = parseInt(strDate.substr(3,2),"10");
        var anyo = parseInt(strDate.substr(6,4),"10");
        return new Date(anyo,mes-1,dia);
        }

    function parseFromDate(date){
        return date.getDate() + '/' + (date.getMonth()+1) + '/' + date.getFullYear();
        }

    Ext.QuickTips.init();
    Ext.apply(Ext.QuickTips.getQuickTip(), {
        maxWidth: 600,
        minWidth: 100,
        showDelay: 400,      // Show 50ms after entering target
        trackMouse: true
    });


    var job_grid_data = function(params) {
        // turn grid into JSON to post data
        var warn_missing = params!=undefined ? params.warn : false;
        var cnt = jc_grid.getStore().getCount();
        if( cnt == 0 ) {
            if( warn_missing ) {
                Ext.Msg.show({icon: 'ext-mb-error', buttons: { cancel: true }, title: "Form Error", msg: _('Missing job contents') });
                return 1;
                }
            }
        var json = [];
        for( i=0; i<cnt; i++) {
            var rec = jc_grid.getStore().getAt(i);
            json.push( Ext.util.JSON.encode( rec.data )) ;
            }
        var json_res = '[' + json.join(',') + ']';
        return json_res;
        };

    var __now=new Date();
    __now.setSeconds(00);

    // Baseline Combo
    var label_dest = _('Destination Baseline');
    var label_orig = _('Origin Baseline');
    var baselines = new Ext.data.SimpleStore({
        fields: ['bl', 'name'],
        id: 0,
        data : <% js_dumper( $baselines ) %>
        });

    var tpl_baseline = new Ext.XTemplate(
        '<tpl for=".">',
            '<div class="search-item">{name}</div>',
        '</tpl>'
        );
    var combo_baseline = new Ext.form.ComboBox({
        name: 'bl',
        hiddenName: 'bl',
        displayField:'name',
        valueField: 'bl',
        fieldLabel: label_dest,
        mode: 'local',
        store: baselines,
        value: '<% $baselines->[1]->[0] %>',
        editable: false,
        forceSelection: true,
        triggerAction: 'all',
        itemSelector: 'div.search-item',
        tpl: tpl_baseline,
        allowBlank: false,
        listeners: {
            select: { fn: function(){
                    job_reset_all();
                    ds_combo.removeAll();
                    jc_grid.getStore().removeAll();
                    combo_joboptionsglobal.getStore().removeAll();
                    Ext.getCmp('joboptionsglobal<% $iid %>').killItems();
                    Ext.getCmp('joboptionsglobal<% $iid %>').hide();
                    }
                }
            },
        width: 200
    });
    combo_baseline.on( 'afterrender', function(){
    });

    var check_no_cal = new Ext.form.Checkbox({
        name: 'check_no_cal',
        fieldLabel: _('Ventana Personalizada') ,
        boxLabel: _('Chequee si quiere crear un pase fuera de ventana.'),
        disabled: true,
        handler: _setOutWindow
    });

    var field_calendar = new Ext.ux.form.DateFieldPlus({
        name: 'job_date',
        disabled: true,
        // readOnly: true,  ## No muestra el boton del calendario
        fieldLabel: _('Date'),
        allowBlank: false,
        usePickerPlus: true,
        format: picker_format,
        value: today,
        minValue: today,
        noOfMonth : 2,
        noOfMonthPerRow : 2,
        renderTodayButton: false,
        showToday: false,
        multiSelection: false,
        allowMouseWheel:true,
        showWeekNumber: false,
        selectedDates: [],
        showActiveDate:true,
        summarizeHeader:true,
        width: 140,
        labelWidth: 145,
        listeners:{
            'change':function(p,t){ }, //after the users changes it by hand
            'beforedateclick':function(picker,t){ },
            'beforerender':function(picker){
                _setDatePicker(this);
                },
            'afterdateclick':function(picker,t){
                //Baseliner.calendar_reload();
                // Baseliner.time_reload(t);
                var time_spinner = main_form.getForm().findField('time_spinner<% $iid %>');
                time_spinner.validate();
                time_spinner.focus();
                // alert(time_spinner.getValue());
                //picker.el.dom.setAttribute('readOnly',true);
                },
            'aftermonthchange':function(picker,oldStartMonth, newStartMonth){
                //_setDatePicker(this);
                //Baseliner.calendar_reload(newStartMonth);
                }
            }
    });

    var comments = new Ext.form.TextArea({
        anchor: '50%',
        height: 80,
        fieldLabel: _('Comments'),
        name: 'comments'
    });

    // Enable all calendar selection fields
    var enableAll = function() {
        //main_form.getForm().reset();
        check_no_cal.setDisabled(false);
        field_calendar.setDisabled(false);
        combo_incidencias.setDisabled(false);
    };

        // Clean up the whole form
    var job_reset_all = function() {
        //main_form.getForm().reset();
        check_no_cal.setDisabled(true);
        field_calendar.setRawValue('');
        field_calendar.setDisabled(true);
        combo_incidencias.setDisabled(true);
        combo_incidencias.getStore().removeAll();
        Ext.getCmp('jobincidencias<% $iid %>').killItems();
        jc_grid.getStore().removeAll();
        ds_combo.removeAll();
        combo_joboptionsglobal.getStore().removeAll();
        combo_incidencias.getStore().removeAll();
        Ext.getCmp('joboptionsglobal<% $iid %>').killItems();
        Ext.getCmp('joboptionsglobal<% $iid %>').hide();
        Ext.getCmp('jobincidencias<% $iid %>').killItems();
        Ext.getCmp('jobincidencias<% $iid %>').hide();
        button_submit.disable();
        };

    var _datePicker = null;

    function _setDatePicker(picker){_datePicker = picker;}

    var store_time = new Ext.data.SimpleStore({
        fields: ['time','name', 'type']
    });
    var tpl_time = new Ext.XTemplate(
        '<tpl for=".">',
        '<div class="search-item"><span style="color:{[ values.type=="N"?"green":"red"]}"><b>{time}</b> - {name}</span></div>',
        '</tpl>'
    );
    var combo_time  = new Ext.form.ComboBox({
        name: 'job_time',
        hiddenName: 'job_time',
        fieldLabel: _('Hour'),
        valueField: 'time',
        displayField:'time',
        mode: 'local',
        store: store_time,
        allowBlank: false,
        width: 300,
        labelWidth: 145,
        typeAhead: true,
        forceSelection: true,
        triggerAction: 'all',
        tpl: tpl_time,
        itemSelector: 'div.search-item',
        disabled: true,
        selectOnFocus: true
    });

    var calendar_reload = function(newMonth, newDate) {
        try {
            if(newDate != undefined) main_form.getForm().findField('job_date').setRawValue(parseFromDate(newDate));
            var cnt = jc_grid.getStore().getCount();
            var _now = new Date();
            var job_date = (newMonth==undefined)?main_form.getForm().findField('job_date').getRawValue(): "01/" + (newMonth + 1) + "/" + _now.getFullYear();
            var time_spinner = main_form.getForm().findField('time_spinner<% $iid %>');
            var bl = combo_baseline.getValue();
            var json_res = job_grid_data({ warn: false });

            if( cnt > 0 ) {
                time_reload( bl, job_date, json_res );
            }

            // no job contents loaded, keep it disabled
             //    check_no_cal.setDisabled(true);
             //    _datePicker.setDisabled(true);
             //    time_spinner.setDisabled(true);
        } catch(e) {
            Baseliner.message(_('Error'), _('Could not reload calendar') );
        }
    };

    var time_reload = function(bl,job_date,json_res) {
        if(!check_no_cal.checked){
            Baseliner.ajaxEval( '/job/build_job_window',
                { bl: bl, job_date: job_date, job_contents: json_res, date_format: date_format  },
                function(res){
                    Baseliner.hideLoadingMask();
                    if( res.success ) {
                        store_time.loadData( res.data );
                        combo_time.enable();
                    } else {
                        combo_time.disable();
                        Ext.Msg.alert( _('Error'), _('Error generating calendar windows: %1', res.msg ) );
                    }
                }
            );
        }
    }

    //------ Tabbed Job Item list
    var tabpanel = new Ext.TabPanel({
        region: 'center',
        defaults: { closable: true, autoScroll: true },
        autoScroll: true,
        activeTab: 0
        });

    var pp = new Ext.Panel({
        layout: 'fit',
        items: [ tabpanel ]
        });

    var to_hour = function( val ) {
        var _ts = new Date();
        var hh_mm = val.split(":");
        _ts.setHours(parseInt(hh_mm[0],"10"));
        _ts.setMinutes(parseInt(hh_mm[1],"10"));
        _ts.setSeconds(00);
        return _ts;
        };


    function getTimeString (date){
        return date.getHours() + ":" + date.getMinutes();
        }

    function _setOutWindow(chk,val){
        var time_spinner = main_form.getForm().findField('time_spinner<% $iid %>');
        if(val){
            time_spinner.setDisabled(false);
            _datePicker.setDisabled(false);
            field_calendar.el.dom.setAttribute('readOnly',false);
            time_spinner.reset();
            time_spinner.strategy = new Ext.ux.form.Spinner.TimeStrategy();
            _datePicker.allowedDates = false;
            _datePicker.update(_datePicker.activeDate, true, false);
            combo_joboptionsglobal.clearValue(true);
            if (combo_joboptionsglobal.store.data.length > 0) {
                text=combo_joboptionsglobal.store.data.items[0].data.id;
                for (var i=1;i<combo_joboptionsglobal.store.data.length;i++) {
                    if (text.indexOf(combo_joboptionsglobal.store.data.items[i].data.id) < 0 ) {
                        text=text + "," + combo_joboptionsglobal.store.data.items[i].data.id;
                        }
                    }
                combo_joboptionsglobal.setValue(text);
                }
            combo_joboptionsglobal.show();
            // combo_incidencias.clearValue(combo_incidencias.getValue());
            combo_incidencias.clearValue(true);
            if (combo_incidencias.store.data.length > 0) {
                text=combo_incidencias.store.data.items[0].data.codigo;
                for (var i=1;i<combo_incidencias.store.data.length;i++) {
                    if (text.indexOf(combo_incidencias.store.data.items[i].data.id) < 0 ) {
                        text=text + "," + combo_incidencias.store.data.items[i].data.codigo;
                        }
                    }
                combo_incidencias.setValue(text);
                }
            combo_incidencias.show();
            comments.validate();
        } else {
            field_calendar.el.dom.setAttribute('readOnly',true);
            main_form.getForm().findField('job_date').setRawValue( today );
            combo_joboptionsglobal.hide();
            combo_incidencias.hide();
            calendar_reload();
            }
        }

    //    bd.createChild({tag: 'h2', html: 'Select the job contents'});
    //------- Search Combo

    var adder = 80;

    var colModel = new Ext.grid.ColumnModel([
        { header: _('Job Item'),
             id:'item',
             width: 160 + adder,
             sortable: true,
             locked: false,
             dataIndex: 'item'},
        { header: _('Item Type'),
             width: 120 + adder,
             sortable: true,
             dataIndex: 'ns_type'},
        { header: _('User'),
             width: 60 + adder,
             sortable: true,
             dataIndex: 'user',
             renderer: Baseliner.render_user_field },
        { header: _('Location'),
             width: 98 + adder,
             sortable: true,
             dataIndex: 'ns' },
        { header: _('Last Updated'),
             width: 110 + adder,
             sortable: true,
             dataIndex: 'date' },
        { header: _('Description'),
             width: 240 + adder,
             sortable: true,
             dataIndex: 'text'}
    ]);

    var ds_grid = new Ext.data.Store({});

    var jc_grid = new Ext.grid.GridPanel({
        fieldLabel:  _('Job Contents'),
        autoDestroy: 1,
        height: 300,
        anchor: '100%',
        name: 'jc',
        style: 'border:1px solid #bbb; margin-top: 10px',
        border: false,
        ds: ds_grid,
        cm: colModel,
        tbar: [
            {
                xtype: 'button',
                text: _('Remove Job Item'),
                icon:'/static/images/del.gif',
                cls: 'x-btn-text-icon',
                handler: function() {
                    var sm = jc_grid.getSelectionModel();
                    var sel = sm.getSelected();
                    jc_grid.getStore().remove(sel);
                    if (jc_grid.getStore().data.length == 0) { button_submit.disable(); }
                    calendar_reload();
                }
            }
         ]
    });

    var button_submit = new Ext.Button({
            xtype:'button', text: _('Create'),
            icon:'/static/images/icons/write.gif',
            cls: 'x-btn-text-icon',
            handler: function(){
                if( check_no_cal.checked && comments.getValue().length == 0 ) {
                    Ext.Msg.show({ title: _('Failure'), msg: _('En pases fuera de ventana, es obligatorio informar el motivo del pase en el campo observaciones'), width: 500, buttons: { ok: true } });
                } else if ( check_no_cal.checked && combo_incidencias.getValue().length == 0 ){
                        Ext.Msg.show({ title: _('Failure'), msg: _('En pases fuera de ventana, es obligatorio informar al menos una incidencia asociada'), width: 500, buttons: { ok: true } });
                } else {
                    var json_res = job_grid_data();
                    button_submit.disable();
                    main_form.getForm().submit({
                        params: { job_contents: json_res },
                        success: function(form,action){
                            //form submit ok
                            //alert( 'ok' + action );
                            Baseliner.message(_('New Job'), action.result.msg);
                            // reset everything
                            job_reset_all();
                            Baseliner.closeCurrentTab();
                            },
                        failure: function(form,action){
                            //alert( 'ko' + action );
                            //   not necessary, handled by standard failure?
                            button_submit.enable();
                            Ext.Msg.show({ title: _('Failure'), msg: action.result.msg, width: 500, buttons: { ok: true } });
                            }
                        });
                    }
                }
    });
    button_submit.disable();

    var tb = new Ext.Toolbar({
        items: [
            <%doc>
            {
                text: 'List Job Items',
                icon:'/static/images/drop-add.gif',
                cls: 'x-btn-text-icon',
                handler: function() {
                    var w = new Ext.Window({
                        layout: 'fit',
                        height: 600, width: 886,
                        closeAction: 'hide',
                        autoDestroy: false,
                        title: 'Choose Job Items',
                        items: pp
                        });
                    w.show();
                }
            },
            {
                xtype: 'button',
                text: _('Remove Job Item'),
                icon:'/static/images/del.gif',
                cls: 'x-btn-text-icon',
                handler: function() {
                    var sm = jc_grid.getSelectionModel();
                    var sel = sm.getSelected();
                    jc_grid.getStore().remove(sel);
                    calendar_reload();
                }
            },
            </%doc>
            '->',
            {
                xtype:'button', text: _('Reset'),
                icon:'/static/images/asterisk.gif',
                cls: 'x-btn-text-icon',
                handler: job_reset_all
            },
            button_submit
            ]
        });

    var store_joboptionsglobal = new Ext.data.ArrayStore({
        fields: ['id', 'name'],
        data: [],
        sortInfo: {field: 'name', direction: 'ASC'}
        });

    var combo_joboptionsglobal = new Ext.ux.form.SuperBoxSelect({
        id: 'joboptionsglobal<% $iid %>',
        allowBlank: true,
        msgTarget: 'under',
        allowAddNewData: true,
        width: 808,
        addNewDataOnBlur: true,
        hidden: true,
        //emptyText: _('Enter or select the category tags'),
        triggerAction: 'all',
        resizable: true,
        store: store_joboptionsglobal ,
        mode: 'local',
        fieldLabel: _('Job Options'),
        typeAhead: true,
        name: 'combo_joboptionsglobal',
        displayField: 'name',
        hiddenName: 'combo_joboptionsglobal',
        valueField: 'id',
        // displayFieldTpl: tpl2,
        // value: params.role_hash,
        extraItemCls: 'x-tag',
        listeners: {
            newitem: function(bs,v, f){
                v = v.slice(0,1).toUpperCase() + v.slice(1).toLowerCase();
                var newObj = {
                    id: v,
                    name: v
                };
                bs.addItem(newObj);
                },
            beforeremoveitem: function(bs,v, f){
                // if (check_no_cal.checked && ( v == 'chm_rf_ll' || v== 'chm_rf_db2')) return false;
                }
            }
        });
        
    var add_joboptionsglobal = function (rec) {
        if (rec.data.job_options_global == undefined) return;
        var arr=rec.data.job_options_global;
        if (arr.length==0) return;
        if (arr == undefined) return;

        for (var i=0;i<arr.length;i++) {
            var ix=store_joboptionsglobal.find('id',arr[i].id, 0, true, false);
            if (ix == -1) {
                arr[i].name=_(arr[i].name);
                store_joboptionsglobal.add(new Ext.data.Record(arr[i]));
                }
            }
        combo_joboptionsglobal.clearValue(true);
        if (combo_joboptionsglobal.store.data.length > 0) {
            text=combo_joboptionsglobal.store.data.items[0].data.id;
            for (var i=1;i<combo_joboptionsglobal.store.data.length;i++) {
                if (text.indexOf(combo_joboptionsglobal.store.data.items[i].data.id) < 0 ) {
                    text=text + "," + combo_joboptionsglobal.store.data.items[i].data.id;
                    }
                }
            combo_joboptionsglobal.setValue(text);
            }
        };

    var store_incidencias = new Ext.data.SimpleStore({
        fields: ['codigo'],
        data: [],
        sortInfo: {field: 'codigo', direction: 'ASC'}
        });

    var combo_incidencias = new Ext.ux.form.SuperBoxSelect({
        id: 'jobincidencias<% $iid %>',
        allowBlank: true,
        msgTarget: 'under',
        allowAddNewData: true,
        width: 808,
        addNewDataOnBlur: true,
        triggerAction: 'all',
        resizable: true,
        store: store_incidencias ,
        mode: 'local',
        fieldLabel: _('Incidencias'),
        typeAhead: true,
        hidden: true,
        name: 'combo_incidencias',
        displayField: 'codigo',
        hiddenName: 'combo_incidencias',
        valueField: 'codigo',
        extraItemCls: 'x-tag',
        listeners: {
            newitem: function(bs,v, f){
                v = v.slice(0,1).toUpperCase() + v.slice(1).toLowerCase();
                var newObj = {
                    codigo: v
                    };
                bs.addItem(newObj);
                }
            }
        });
        
    var add_incidencia = function (rec) {
        var arr=rec.data.inc_id;
        if (rec.data.inc_id == undefined) return;
        if (arr.length == 0) return;
        if (arr == undefined) return;
        if (arr[0].codigo == null) return;

        for (var i=0;i<arr.length;i++) {
            var ix=store_incidencias.find('codigo',arr[i].codigo);
            if (ix == -1) {
                store_incidencias.add(new Ext.data.Record(arr[i]));
                }
            }
        combo_incidencias.clearValue(true);
        if (combo_incidencias.store.data.length > 0) {
            text=combo_incidencias.store.data.items[0].data.codigo;
            for (var i=1;i<combo_incidencias.store.data.length;i++) {
                if (text.indexOf(combo_incidencias.store.data.items[i].data.codigo) < 0 ) {
                    text=text + "," + combo_incidencias.store.data.items[i].data.codigo;
                    }
                }
            combo_incidencias.setValue(text);
            }
        };

    var ds_combo = new Ext.data.Store({
        proxy: new Ext.data.HttpProxy({
            url: '/job/items/json',
            param: { bl: combo_baseline.getValue() }
            }),
        listeners: {
            beforeload: {
                fn: function(store,opt) {
                    var bl = combo_baseline.getValue();
                    var job_type = main_form.getForm().getValues()['job_type'];
                    store.baseParams.bl = bl;
                    store.baseParams.job_type = job_type;
                    }
                },
            load: {
                fn: function(store,opt) {
                        if( store.getTotalCount() == 0 ) {
                            Baseliner.message(_('Warning'), _('No records found') );
                        }
                    }
                }
            },
        reader: new Ext.data.JsonReader({
            root: 'data',
            totalProperty: 'totalCount',
            id: 'id'
            },
        [
            {name: 'provider',           mapping: 'provider'},
            {name: 'related',            mapping: 'related'},
            {name: 'ns_type',            mapping: 'ns_type'},
            {name: 'recordCls',          mapping: 'recordCls'},
            {name: 'why_not',            mapping: 'why_not'},
            {name: 'can_job',            mapping: 'can_job'},
            {name: 'item',               mapping: 'item'},
            {name: 'user',               mapping: 'user'},
            {name: 'service',            mapping: 'service'},
            {name: 'ns',                 mapping: 'ns'},
            {name: 'date',               mapping: 'date'},
            {name: 'icon',               mapping: 'icon'},
            {name: 'data',               mapping: 'data'},
            {name: 'text',               mapping: 'text'},
            {name: 'packages',           mapping: 'packages'},
            {name: 'subapps',            mapping: 'subapps'},
            {name: 'job_options',        mapping: 'job_options'},
            {name: 'job_options_global', mapping: 'job_options_global'},
            {name: 'inc_id',             mapping: 'inc_id'},
            {name: 'moreInfo',           mapping: 'moreInfo'}
            ])
        });

    // Search Combo: Custom rendering Template
    // '<tpl if="moreInfo">',
    // '<br />{moreInfo}',
    // '</tpl>',
    // '<tpl if="packages">',
    // '<br />{packages}',
    // '</tpl>',

    var resultTpl = new Ext.XTemplate(
        '<tpl for="."><div ext:qtip="{moreInfo}" qtitle="' + _loc('More Info...') + '<hr>" class="search-item {recordCls}">',
        '<h3><span>{ns_type}<br />{user}</span><img src="{icon}" />{item}</h3>',
        '<tpl if="packages">',
            '<br />{packages}',
        '</tpl>',
        '<tpl if="text">',
            '<br />{text}',
        '</tpl>',
        '<tpl if="subapps">',
            '<br />{subapps}',
        '</tpl>',
        '<tpl if="why_not">',
            '<br />{why_not}',
        '</tpl>',
        '</div></tpl>'
        );

    var combo_search = new Ext.form.ComboBox({
        // fieldLabel: _('Add Job Items'),
        store: ds_combo,
        anchor: '50%',
        minChars: min_chars ,
        displayField:'item',
        typeAhead: false,
        loadingText: _('Searching...'),
        lazyRender: true,
        queryDelay: 1000,
        pageSize: 20,
        tpl: resultTpl,
        // hideTrigger:true,
        itemSelector: 'div.search-item',
        listeners: {
            // delete the previous query in the beforequery event or set
            // combo.lastQuery = null (this will reload the store the next time it expands)
            beforequery: function(qe){
                delete qe.combo.lastQuery;
                }
            },
            onSelect: function(record){
                if( record.get('can_job') != 1 ) {
                    Ext.Msg.show({icon: 'ext-mb-error',
                    buttons: { cancel: true },
                    title: _('Blocked'),
                    width: 500,
                        msg: _('Package cannot be added to job')+":<br>" + record.get('why_not')
                        });
                    return false;
                }
                try {
                    //debugging: console.log( record );
                    // add from combo to grid
                    ds_grid.add(record);
                    // take if off from the list
                    ds_combo.remove(record);
                    // add job optons global
                    add_joboptionsglobal(record);
                    // add USD ticket
                    add_incidencia(record);
                    // enable all fields
                    enableAll();
                    // recalculate calendar
                    main_form.getForm().findField('job_date').setRawValue( today );
                    calendar_reload();
                    // button_submit.enable(); // Eric -- Mejor esto lo hacemos en otro sitio.
                } catch(e) {
                    //alert( e );
                }
            }
        });

    combo_search.on('beforeselect', function(combo, record, index) {
        if( true || record.get('recordCls') == 'category-header' ) {
            return false;
        }
    });     
     
    var search_form = new Ext.Panel({
        layout: 'anchor',
        anchor: '100%',
        fieldLabel:  _('Add Job Items'),
        items: [
            { xtype:'combo', width: '50%' },
            { xtype: 'container', style: 'height: 20px', html:  _('Live search requires a minimum of %1 characters.', min_chars ) },
            jc_grid
        ]
    });
        
    var main_form = new Ext.FormPanel({
        url: '/job/submit',
        frame: true,
        title: _loc('Job Options'),
        // width: 986,
        //autoWidth: 1,
        forceFit: true,
        // labelWidth: 145,
        tbar: tb,
        defaults: {
            msgTarget: 'under'
        },
        items: [
            {
                xtype: 'radiogroup',
                name: 'job_type',
                columns: 1,
                fieldLabel: _('Job Type'),
                listeners: {
                    change: { fn: function(t,checked) {
                        ds_combo.removeAll();
                        jc_grid.getStore().removeAll();
                        combo_baseline.setFieldLabel( checked.inputValue =='demote' ? label_orig : label_dest );
                        combo_joboptionsglobal.getStore().removeAll();
                        Ext.getCmp('joboptionsglobal<% $iid %>').killItems();
                        Ext.getCmp('joboptionsglobal<% $iid %>').hide();
                        } }
                    },
                items: <% js_dumper(  $c->stash->{job_types} ) %>
            },
            combo_baseline,
            search_form,
            //jc_grid,
            combo_joboptionsglobal,
            check_no_cal,
            field_calendar,
            combo_time,
            combo_incidencias,
            comments
        ]
    });

    Ext.form.Field.prototype.msgTarget = 'side';
        
    // if( Ext.isIE ) document.getElementById('search<% $iid %>').style.top = 0; // hack fix
    
% unless( scalar _array _array( $c->stash->{baselines} ) ) {
    Ext.MessageBox.show({
        title: 'Error',
        msg: 'Su usuario no tiene permisos de creacion de pases en ningun entorno',
        // msg: 'Su usuario no tiene permisos de creacion de pases en ningun entorno',
        buttons: Ext.MessageBox.OK,
        icon: Ext.MessageBox.ERROR
        });
% }
    return main_form;
})
