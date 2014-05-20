<%doc>
    job_new.mas - new job creation screen
</%doc>
<%perl>
    use Baseliner::Utils;
    use utf8;
    my $iid = "div-" . _nowstamp;
    $c->stash->{job_types} = [
        { name=>'job_type', inputValue=> 'promote', boxLabel => _loc('Promote'), checked=>\1 },
        { name=>'job_type', inputValue=> 'demote', boxLabel => _loc('Demote') }
        ];
    my $now = DateTime->now;
    $now->set_time_zone(_tz);
    my $today =  $now->strftime('%d/%m/%Y');
    my $hm =  $now->strftime('%H:%M');
</%perl>
(function(opts){
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

    var job_grid_data = function(params) {
        // turn grid into JSON to post data
        var warn_missing = params!=undefined ? params.warn : false;
        var cnt = jc_grid.getStore().getCount();
        if( cnt == 0 ) {
            if( warn_missing )
                Ext.Msg.show({icon: 'ext-mb-error', buttons: { cancel: true }, title: "Form Error", msg: _('Missing job contents') });
                return 1;
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
        data : <% js_dumper( $c->stash->{baselines} ) %>
        });
    var combo_baseline = new Ext.form.ComboBox({
        name: 'bl',
        hiddenName: 'bl',
        fieldLabel: label_dest,
        mode: 'local',
        store: baselines,
        valueField: 'bl',
        value: '<% $c->stash->{baselines}->[0]->[0] %>',
        displayField:'name',
        editable: false,
        forceSelection: true,
        triggerAction: 'all',
        allowBlank: false,
        listeners: {
            select: { fn: function(){
                    Baseliner.jobResetAll();
                    ds_combo.removeAll();
                    jc_grid.getStore().removeAll();
                    } 
                }
            },
        width: 120
        });

    var window_check = new Ext.form.Checkbox({
        name: 'window_check',
        fieldLabel: 'Ventana Personalizada' ,
        boxLabel: 'Chequee si quiere crear un pase fuera de ventana.',
        handler: _setOutWindow
        });

    var field_calendar = new Ext.ux.form.DateFieldPlus({
        id: 'job_date<% $iid %>',
        name: 'job_date',
        disabled: true,
        //readOnly: true,
        fieldLabel: '<% _loc('Date') %>',
        allowBlank: false,
        usePickerPlus: true,
        format: 'd/m/Y',
        value: '<% $today %>',
        minValue: '<% $today %>',
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
        width: 150,
        labelWidth: 250,
        listeners:{
            'change':function(p,t){ }, //after the users changes it by hand 
            'beforedateclick':function(picker,t){ },
            'beforerender':function(picker){
                _setDatePicker(this);
                },
            'afterdateclick':function(picker,t){
                //Baseliner.calendar_reload();
                Baseliner.time_reload(t);
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

    var field_spinner = new Ext.ux.form.Spinner({
        id:   'time_spinner<% $iid %>',
        name: 'job_time',
        format : "H:i",
        fieldLabel: '<% _loc('Time') %>',
        allowBlank: false,
        disabled:true,
        value: '<% $hm %>',
        //editable: false,
        vtype: 'hour',
        width: 150,
        labelWidth: 250,
        strategy: new Ext.ux.form.Spinner.TimeStrategy(),
        listeners:{
            'spin':function(p,t){ 
                this.validate();
                }
            }
        });
        
    var txtComment = new Ext.form.TextArea({
        id:   'comments<% $iid %>',
        fieldLabel: '<% _loc('Comments') %>',
        width: 500,
        name: 'comments'
        });

    // Enable all calendar selection fields
    var enableAll = function() {
        //main_form.getForm().reset();
        window_check.setDisabled(false);
        job_time.setDisabled(false);
        field_calendar.setDisabled(false);
        field_spinner.setDisabled(false);
        };

        // Clean up the whole form
    Baseliner.jobResetAll = function() {
        //main_form.getForm().reset();
        window_check.setDisabled(true);
        job_time.setRawValue('');
        job_time.setDisabled(true);
        field_calendar.setRawValue('');
        field_calendar.setDisabled(true);
        field_spinner.setRawValue('');
        field_spinner.setDisabled(true);
        jc_grid.getStore().removeAll();
        ds_combo.removeAll();
        };

    var _datePicker = null;

    function _setDatePicker(picker){_datePicker = picker;}

    var time_store = new Baseliner.JsonStore({
        root: 'data',
        url: '/job/check_time',
        fields: [
                {  name: 'displayText' },
                {  name: 'valueJson' },
                {  name: 'start_time' },
                {  name: 'end_time' },
                {  name: 'type' }
                ]
        });

// '<div class="search-item"><img src="/static/images/icons/time.gif"/>\t{displayText}</b></div>',
    var time_tpl = new Ext.XTemplate(
        '<tpl for=".">',
        '<div class="search-item"><img src="/static/images/chromium/history_favicon.png"/><span><b>{displayText}</span></b></div>',
        '</tpl>'
        );

// var resultRange = new Ext.XTemplate(
    // '<tpl for="."><div class="search-item {type}">{displayText}</div></tpl>'
    // );

    var job_time  = new Ext.form.ComboBox({
        name: 'job_combo',
        hiddenName: 'job_combo',
        fieldLabel: '<% _loc('Franja horaria') %>',
        valueField: 'valueJson',
        displayField:'displayText',
        itemSelector: 'div.search-item',
        store: time_store,
        allowBlank: false,
        width: 150,
        labelWidth: 250,
        typeAhead: true,
        mode: 'local',
        forceSelection: true,
        triggerAction: 'all',
        tpl: time_tpl,
        disabled: true,
        selectOnFocus:true
        });

    Baseliner.calendar_reload = function(newMonth, newDate) {
        try {
            if(newDate != undefined) main_form.getForm().findField('job_date').setRawValue(parseFromDate(newDate));
            var cnt = jc_grid.getStore().getCount();
            var _now = new Date();
            var job_date = (newMonth==undefined)?main_form.getForm().findField('job_date').getRawValue(): "01/" + (newMonth + 1) + "/" + _now.getFullYear();
            var time_spinner = main_form.getForm().findField('time_spinner<% $iid %>');
            var bl = combo_baseline.getValue();
            var json_res = job_grid_data({ warn: false });
            if( cnt > 0 ) {
                if(!window_check.checked){
                    //time_store.load({ params: { bl: bl, job_date: job_date, job_contents: json_res } });
                    Baseliner.showLoadingMask(main_form.getEl(), "Cargando fechas...");
                    Ext.Ajax.request({
                        url: '/job/check_date',
                        params: { bl: bl, job_date: job_date, job_contents: json_res },
                        success: function(xhr) {
                            Baseliner.hideLoadingMask( main_form.getEl() );
                            var expr = xhr.responseText.replace(/\"/g, "");
                            var _raw = eval( "("+xhr.responseText+")" );
                            var error = (!_raw.success);
                            if(!error){
                                var dates = eval("[" + _raw.data + "]");
                                if(dates.length>0 ){
                                    window_check.setDisabled(false);
                                    _datePicker.setDisabled(false);
                                    _datePicker.setAllowedDates(dates, true);
                                    _datePicker.update(_datePicker.activeDate, true, true);
                                    if(CheckValidDate(_datePicker,job_time,time_spinner,dates,job_date)){
                                        Baseliner.time_reload();
                                        }
                                } else {
                                    Ext.Msg.show({icon: 'ext-mb-error', buttons: { cancel: true }, title: "Sin Fechas", msg: "No hay fechas disponibles para el pase. Seleccione una ventana personalizada."});
                                    window_check.setValue( true );
                                }
                            }else{
                                Ext.Msg.show({icon: 'ext-mb-error', buttons: { cancel: true }, title: "Error Calendarios", msg: "No hay calendarios disponibles para el pase. La busqueda ha devuelto una excepcion:<b>"+_raw.data+"</b>."});
                                }
                            },
                        failure: function(xhr) {
                            Baseliner.hideLoadingMask( main_form.getEl() );
                            Ext.Msg.show({icon: 'ext-mb-error', buttons: { cancel: true }, title: "Form Error", msg: "Se ha producido un error de timeout."});
                            //Baseliner.errorWin( 'Logout Error', xhr.responseText );
                            }
                        });
                    //TODO main_form.getForm().findField('job_date').setValue( time_store.getRowAt(0) );
                    <%doc>
                    Ext.Ajax.request({
                        url: '/job/check_time',
                        params: { bl: bl, job_date: job_date, job_contents: json_res },
                        success: function(xhr) {
                            var times = eval( "("+xhr.responseText+")" );
                            for( var i in times.data ) {
                                var e = times.data[i];
                                }
                            },
                        failure: function(xhr) {
                            Baseliner.hideLoadingMask( main_form.getEl() );
                            Ext.Msg.show({icon: 'ext-mb-error', buttons: { cancel: true }, title: "Form Error", msg: "Se ha producido un error de timeout."});
                            //Baseliner.errorWin( 'Logout Error', xhr.responseText );
                            }
                        });
                    </%doc>
                    }
            } else {
                // no job contents loaded, keep it disabled
                window_check.setDisabled(true);
                _datePicker.setDisabled(true);
                job_time.setDisabled(true);
                time_spinner.setDisabled(true);
                }
        } catch(e) {
            Baseliner.message(_('Error'), _('Could not reload calendar') );
            }
        };

    Baseliner.time_reload = function(t) {
        if(!window_check.checked){
            var job_date = ( t != undefined) ? t.getDate() + "/" + (t.getMonth()+1) + "/" + t.getFullYear() : main_form.getForm().findField('job_date').getRawValue();
            var bl = combo_baseline.getValue();
            var json_res = job_grid_data({ warn: false });
            Baseliner.showLoadingMask(main_form.getEl(), "Actualizando horas...");
            time_store.load({
                params: { bl: bl, job_date: job_date, job_contents: json_res }
                });
            }
        }

    function CheckValidDate(picker,job_time,time_spinner,dates,job_date){ //called by calendar reload
        var currentDate = parseToDate(job_date);
        if(dates!=null && dates.length >0){
            for(var i=0;i<dates.length; i++){
                if(currentDate.getDate() == dates[i].getDate() && currentDate.getMonth() == dates[i].getMonth() && currentDate.getFullYear() == dates[i].getFullYear()){
                    return true;
                    }
                }
            if(!window_check.checked){
                //picker.setDisabled(true);
                //job_time.setDisabled(true);
                //time_spinner.setDisabled(true);
                main_form.getForm().findField('job_date').setRawValue('');
                main_form.getForm().findField('time_spinner<% $iid %>').setRawValue('');
                job_time.setRawValue('');
                //Baseliner.calendar_reload(undefined,dates[0]);
                }
        } else {
            if(!window_check.checked){
                picker.setDisabled(true);
                job_time.setDisabled(true);
                time_spinner.setDisabled(true);
                }
            }
        return false;
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

    var checkExpired = function( val ) {
        var myHora = parseTime(val, main_form.getForm().findField('job_date').value);
        myHora.setSeconds(59);          
        if ( myHora < __now ) {
            field_spinner.markInvalid( _('Hora de pase Caducada') );
            Ext.form.VTypes['hourText'] = _('Hora de pase Caducada');
            return true;
            }
        return false;
        };
        
    var checkInRange = function(val, range) {
        eval("_range = " + range + ";");                    
        var range_str = _range.start_time + " - " + _range.end_time;
        // alert( ">" + _range.start_time + "<" );
        var a = to_hour( _range.start_time );
        var b = to_hour( val );
        var c = to_hour( _range.end_time );
        if( a <= b && b <= c ) return true;
        field_spinner.markInvalid( _('Time off range %1', range_str ) );
        Ext.form.VTypes['hourText'] = _("Pase fuera de ventana. Seleccione 'Ventana personalizada' si quiere un pase fuera de las ventanas permitidas");
        return false;
        };

    // hour validator
    Ext.form.VTypes['hourVal']  = /^[0-2][0-9]:[0-5][0-9]$/; 
    Ext.form.VTypes['hourMask'] = /[0-9:]/; 
    Ext.form.VTypes['hourText'] = _('Formato de Hora inválido (00:00-23:59)');
    Ext.form.VTypes['hour']     = function(v){ 
        var t = Ext.form.VTypes['hourVal'].test(v); 
        if( ! t ) return false;
        if( !window_check.checked && !checkInRange(v,job_time.getValue() ) ) return false;
        if( checkExpired(v) ) return false;
        var arr = v.split(":"); 
        if( arr[0] > 23 || arr[1] > 59 ) {
            field_spinner.markInvalid( _('Formato de Hora inválido (00:00-23:59)') );
            return false;
            }
        return true;
        }; 

    function parseTime (time, date){
        // date=main_form.getForm().findField('job_date').value;
        var _now;
        if ( date==undefined ) {
             _now = new Date();
        } else {
             _now = parseToDate(date);
            }
        // var _now = new Date(date);
        if(time.indexOf(":")>-1){
            var hh_mm = time.split(":");
            _now.setHours(parseInt(hh_mm[0],"10"));
            _now.setMinutes(parseInt(hh_mm[1],"10"));
            }
        return _now;
        }

    function getTimeString (date){
        return date.getHours() + ":" + date.getMinutes();
        }

    function selectNearestTimeRange(data){
        var time_spinner = main_form.getForm().findField('time_spinner<% $iid %>');
        var _currentTime = parseTime(time_spinner.getRawValue());

        for(var i=0;i<data.length;i++){
            var _datos = data[i].data;
            var _startTime = parseTime(_datos.start_time, main_form.getForm().findField('job_date').value);
            var _endTime = parseTime(_datos.end_time, main_form.getForm().findField('job_date').value);
            if( _currentTime <= _endTime ){
                job_time.setValue(_datos.valueJson);
                if(_currentTime >= _startTime ) {
                    var _minValue=time_spinner.getRawValue();
                    var _maxValue=_datos.end_time;
                    _maxValue = _maxValue.replace(/24:00/g, "23:59");
                    time_spinner.strategy = new Ext.ux.form.Spinner.TimeStrategy({minValue:_minValue, maxValue:_maxValue});
                    time_spinner.setRawValue(time_spinner.getRawValue());
                } else {
                    var _minValue=_datos.start_time;
                    var _maxValue=_datos.end_time;
                    _maxValue = _maxValue.replace(/24:00/g, "23:59");
                    time_spinner.strategy = new Ext.ux.form.Spinner.TimeStrategy({minValue:_minValue, maxValue:_maxValue});
                    time_spinner.setRawValue(_datos.start_time);
                    }
                job_time.on("select", function(combo, record, index) {
                    changeTime();
                    });
                changeTime();
                return;
                }
            }

        if(data.length >0){
            job_time.setValue(data[0].data.valueJson);
            changeTime();
            }
        }

    function changeTime(val){
        var time_spinner = main_form.getForm().findField('time_spinner<% $iid %>');
        var _jsonData = null;
        eval("_jsonData = " + job_time.getValue() + ";");
        var m_currentTime = parseTime(time_spinner.getRawValue());
        var m_startTime = parseTime(_jsonData.start_time, main_form.getForm().findField('job_date').value);
        var m_endTime = parseTime(_jsonData.end_time, main_form.getForm().findField('job_date').value);
        time_spinner.reset();
        var _minValue=_jsonData.start_time;
        var _maxValue=_jsonData.end_time;
        _maxValue = _maxValue.replace(/24:00/g, "23:59");
        time_spinner.strategy = new Ext.ux.form.Spinner.TimeStrategy({minValue:_minValue, maxValue:_maxValue});
        if (!(m_currentTime >= m_startTime && m_currentTime <= m_endTime)){
            time_spinner.setRawValue(_jsonData.start_time);
            }
        time_spinner.validate();
        time_spinner.focus();
        }

    time_store.on('load', function(xhr){
        var time_spinner = main_form.getForm().findField('time_spinner<% $iid %>');
        job_time.setDisabled(false);
        time_spinner.setDisabled(false);
        selectNearestTimeRange(xhr.data.items);
        Baseliner.hideLoadingMask( main_form.getEl() );
        });

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
            job_time.setDisabled(true);
            txtComment.validate();
        } else {
            field_calendar.el.dom.setAttribute('readOnly',true);
            main_form.getForm().findField('job_date').setRawValue('<% $today %>');
            Baseliner.calendar_reload();
            }
        }

    //    bd.createChild({tag: 'h2', html: 'Select the job contents'});
    //------- Search Combo

    var colModel = new Ext.grid.ColumnModel([
        {width: 32, sortable: true, locked:false, dataIndex: 'icon', renderer: Baseliner.render_icon},
        {header: _('Job Item'), width: 160, sortable: true, locked:false, dataIndex: 'item', renderer: function(v){ return '<b>'+v+'</b>'} },
        {header: _('Item Type'), width: 150, hidden: true, sortable: true, dataIndex: 'ns_type'},
        {header: _('User'), hidden: true, width: 75, sortable: true, dataIndex: 'user', renderer: Baseliner.render_user_field },
        {header: _('Location'), width: 85, sortable: true, dataIndex: 'ns' },
        {header: _('Last Updated'), width: 110, sortable: true, dataIndex: 'date' },
        {header: _('Description'), width: 230, sortable: true, dataIndex: 'text'}
        ]);
        
    var ds_grid = new Ext.data.Store({});
    var jc_grid = new Ext.grid.GridPanel({
        width: 800,
        height: 150,
        enableDragDrop: true,
        ddGroup: 'explorer_dd',
        style: 'margin-top: 20px',
        name: 'jc',
        title: _('Job Contents'),
        border: true,
        ds: ds_grid,
        cm: colModel
    });
    jc_grid.on( 'render', function(){
        var el = jc_grid.getView().el.dom.childNodes[0].childNodes[1];
        var jc_grid_dt = new Baseliner.DropTarget(el, {
            comp: jc_grid,
            ddGroup: 'explorer_dd',
            copy: true,
            notifyDrop: function(dd, e, data) {
                var n = dd.dragData.node;
                var s = jc_grid.store;
                var add_node = function(node) {
                    var data = node.attributes.data;
                    //console.log( node );
                    var rec = new Ext.data.Record({
                        ns: data.ns,
                        icon: node.attributes.icon,
                        //item: data.name,
                        item: node.text,
                        text: node.text 
                    });
                       /* {name: 'provider', mapping: 'provider'},
                        {name: 'related', mapping: 'related'},
                        {name: 'ns_type', mapping: 'ns_type'},
                        {name: 'recordCls', mapping: 'recordCls'},
                        {name: 'why_not', mapping: 'why_not'},
                        {name: 'can_job', mapping: 'can_job'},
                        {name: 'item', mapping: 'item'},
                        {name: 'user', mapping: 'user'},
                        {name: 'service', mapping: 'service'},
                        {name: 'ns', mapping: 'ns'},
                        {name: 'date', mapping: 'date'},
                        {name: 'icon', mapping: 'icon'},
                        {name: 'data', mapping: 'data'},
                        {name: 'text', mapping: 'text'}
                        */
                    s.add(rec);
                    //s.sort('action', 'ASC');
                    var parent_node = node.parentNode;
                    // node.disable();
                    enableAll();
                    main_form.getForm().findField('job_date').setRawValue('<% $today %>');
                    Baseliner.calendar_reload();
                    button_submit.enable();
                    //tree_check_folder_enabled(parent_node);
                }
                var attr = n.attributes;
                var data = n.attributes.data;
                var job_type = main_form.getForm().getValues()['job_type'];
                var bl = combo_baseline.getValue();
                var cnt = jc_grid.getStore().getCount();  // auto set ?

                //if( data.promotable[ bl ] == 1  || data.demot) {
                var bl_item = ( job_type == 'promote' ) ? data.promotable[bl] : data.demotable[bl];
                if ( bl_item == undefined ) {  
                    Ext.Msg.alert( _('Error'),
                        _("Cannot promote/demote changeset %1 to baseline %2 (job type %3)", '<b>' + n.text + '</b>', bl, job_type ) );
                } else {
                    add_node(n);
                }
                return (true); 
             }
        });
    });
        
    var button_submit = new Ext.Button({
            xtype:'button', text: _('Create'),
            icon:'/static/images/icons/write.gif',
            cls: 'x-btn-text-icon',
            handler: function(){
                if( window_check.checked && txtComment.getValue().length == 0 ) {
                    Ext.Msg.show({ title: _('Failure'), msg: _('En pases fuera de ventana, es obligatorio informar el motivo del pase en el campo observaciones'), width: 500, buttons: { ok: true } });
                } else {
                    var json_res = job_grid_data();
                    button_submit.disable();
                    main_form.getForm().submit({
                        params: { job_contents: json_res },
                        success: function(form,action){
                            //form submit ok
                            //alert( 'ok' + action );
                            Baseliner.message("<% _loc('New Job') %>", action.result.msg);
                            // reset everything
                            Baseliner.jobResetAll();
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
        style: 'margin: 3px',
        items: [
            <%doc>
            {
            text: 'List Job Items',
            icon:'/static/images/drop-add.gif',
            cls: 'x-btn-text-icon',
            handler: function() {
                var w = new Ext.Window({
                    layout: 'fit',
                    height: 600, width: 700,
                    closeAction: 'hide',
                    autoDestroy: false,
                    title: 'Choose Job Items',
                    items: pp
                    });
                w.show();
                }
            },
            </%doc>
            button_submit,
            {
            xtype: 'button',
            text: _('Remove Job Item'),
            icon:'/static/images/del.gif',
            cls: 'x-btn-text-icon',
            handler: function() {
                var sm = jc_grid.getSelectionModel();
                var sel = sm.getSelected();
                jc_grid.getStore().remove(sel);
                Baseliner.calendar_reload();
                }
            },
            { 
            xtype:'button', text: _('Reset'),
            icon:'/static/images/asterisk.gif',
            cls: 'x-btn-text-icon',
            handler: Baseliner.jobResetAll
            }, 
            '->'
            ]
        });
        
    var main_form = new Ext.FormPanel({
        url: '/job/submit',
        frame: true,
        title: '<% _loc('Job Options') %>',
        width: 900,
        items: [
            tb,
            { 
            xtype: 'radiogroup',
            name: 'job_type',
            columns: 3,
            width: 300,
            fieldLabel: '<% _loc('Job Type') %>',
            listeners: {
                change: { fn: function(t,checked) {
                    ds_combo.removeAll();
                    jc_grid.getStore().removeAll();
                    combo_baseline.setFieldLabel( checked.inputValue =='demote' ? label_orig : label_dest );
                    } }
                },
            items: <% js_dumper(  $c->stash->{job_types} ) %>
            },
            combo_baseline,
            jc_grid,
            window_check,
            field_calendar,
            job_time,
            field_spinner,
            txtComment
            ]
        });

    Ext.form.Field.prototype.msgTarget = 'side';

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
                        Baseliner.message("<% _loc('Warning') %>", "<% _loc('No records found') %>");
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
            {name: 'provider', mapping: 'provider'},
            {name: 'moreinfo', mapping: 'more_info'},
            {name: 'related', mapping: 'related'},
            {name: 'ns_type', mapping: 'ns_type'},
            {name: 'recordCls', mapping: 'recordCls'},
            {name: 'why_not', mapping: 'why_not'},
            {name: 'can_job', mapping: 'can_job'},
            {name: 'item', mapping: 'item'},
            {name: 'user', mapping: 'user'},
            {name: 'service', mapping: 'service'},
            {name: 'ns', mapping: 'ns'},
            {name: 'date', mapping: 'date'},
            {name: 'icon', mapping: 'icon'},
            {name: 'data', mapping: 'data'},
            {name: 'text', mapping: 'text'}
        ])
    });

    // Search Combo: Custom rendering Template
    var resultTpl = new Ext.XTemplate(
        '<tpl for="."><div class="search-item {recordCls}">',
        '<h3><span>{ns_type}<br />{user}</span><img src="{icon}" />{item}</h3>',
        '{text}',
        '<tpl if="moreinfo">',
        '<br />{moreinfo}',
        '</tpl>',
        '<tpl if="why_not">',
        '<br />{why_not}',
        '</tpl>',
        '</div></tpl>'
        );

    var search = new Ext.form.ComboBox({
        store: ds_combo,
        minChars :3,
        displayField:'item',
        typeAhead: false,
        loadingText: '<% _loc('Searching...') %>',
        width: 550,
                resizable: true,
        lazyRender: false,
        pageSize:21,
        hideTrigger:true,
        tpl: resultTpl,
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
                // enable all fields
                enableAll();
                // recalculate calendar
                main_form.getForm().findField('job_date').setRawValue('<% $today %>');
                Baseliner.calendar_reload();
                    button_submit.enable();
            } catch(e) {
                    //alert( e );
                }
            }
        });

    search.on('beforeselect', function(combo, record, index) {
        if( true || record.get('recordCls') == 'category-header' ) {
            return false;
            }
        });


    //if( Ext.isIE ) document.getElementById('search<% $iid %>').style.top = 0; // hack fix
% unless( scalar _array _array( $c->stash->{baselines} ) ) {
    Ext.MessageBox.show({
        title: 'Error',
        msg: 'Su usuario no tiene permisos de creación de pases en ningún entorno',
        buttons: Ext.MessageBox.OK,
        icon: Ext.MessageBox.ERROR
        });
% }
    return main_form;
})
