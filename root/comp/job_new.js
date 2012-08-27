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

    my $default_baseline = config_value( 'job_new.default_baseline' );
    my $forms = config_value( 'job_new.form' );
    my $show_job_search_combo = config_value( 'site.show_job_search_combo' );
    my $show_no_cal = config_value( 'site.show_no_cal' );
    my $has_no_cal = $c->is_root || $c->has_action( 'action.job.no_cal' );
</%perl>
(function(){
    var forms = <% js_dumper( [ _array $forms ] ) %>;
    var default_baseline = '<% $default_baseline %>';
    var has_no_cal = <% $has_no_cal ? 'true' : 'false'  %>;
    var show_no_cal = <% $show_no_cal ? 'true' : 'false'  %>;
    var show_job_search_combo = <% $show_job_search_combo ? 'true' : 'false'  %>;
    var date_format = '<% $date_format %>';  // %Y-%m-%d 
    var picker_format = '<% $picker_format %>'; // Y-m-d
    var today = '<% $today %>';
    var min_chars = 3; 

    var data_any_time = function() {
        var arr = [];
        var name = _('no calendar window');
        for( var h=0; h<24; h++ ) {
           for( var m=0; m<60; m++ ) {
               arr.push(
                  [ String.leftPad( h,2,'0') + ':' + String.leftPad( m,2,'0'), name, 'F' ] 
               );
           }
        }
        return arr;
    };

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

    //*************************************************
    //
    // Baseline Combo
    //
    var label_dest = _('Destination Baseline');
    var label_orig = _('Origin Baseline');
    var store_baselines = new Ext.data.SimpleStore({
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
        store: store_baselines,
        value: default_baseline,
        editable: false,
        forceSelection: true,
        triggerAction: 'all',
        itemSelector: 'div.search-item',
        tpl: tpl_baseline,
        allowBlank: false,
        listeners: {
            select: function() {
                var bl = combo_baseline.getRawValue();
                form_reset_all();
                store_search.removeAll();
                jc_grid.getStore().removeAll();
                combo_baseline.setRawValue( bl );
            }
        },
        width: 200
    });

    combo_baseline.on( 'afterrender', function(){
    });

    var check_no_cal = new Ext.form.Checkbox({
        name: 'check_no_cal',
        fieldLabel: '',
        boxLabel: _("Create a job outside of the available time slots."),
        hidden: !show_no_cal,
        disabled: has_no_cal,
        handler: function (chk,val){
            if(val){
                store_time.removeAll();
                store_time.loadData( data_any_time() );
                combo_time.enable();
                combo_time.show();
                comments.validate();
                button_submit.enable();
            } else {
                button_submit.disable();
                calendar_reload();
            }
        }

    });

    var job_date = new Ext.ux.form.DateFieldPlus({
        name: 'job_date',
        disabled: false,
        fieldLabel: _('Date'),
        allowBlank: false,
        usePickerPlus: true,
        format: picker_format,
        value: today,
        minValue: today,
        noOfMonth : 2,
        noOfMonthPerRow : 2,
        renderTodayButton: true,
        showToday: false,
        multiSelection: false,
        allowMouseWheel: true,
        showWeekNumber: false,
        selectedDates: [],
        showActiveDate: true,
        summarizeHeader: true,
        submitFormat: 'Y-m-d',
        submitFormatAddon: '-format',
        width: 140,
        listeners:{
            'select':function(picker,t){
                calendar_reload( t.format( picker_format ) );
                //Baseliner.calendar_reload();
                // time_spinner.validate();
                // time_spinner.focus();
                // alert(time_spinner.getValue());
                //picker.el.dom.setAttribute('readOnly',true);
            }
        }
    });

    var comments = new Ext.form.TextArea({
        width: 750,
        height: 120,
        fieldLabel: _('Comments'),
        name: 'comments'
    });

    // Clean up the whole form
    var form_reset_all = function() {
        //main_form.getForm().reset();
        if( ! check_no_cal.checked ) {
            store_time.removeAll();
            combo_time.setRawValue('');
        }
        jc_grid.getStore().removeAll();
        store_search.removeAll();
        button_submit.disable();
    };

    var store_time = new Ext.data.SimpleStore({
        fields: ['time','name', 'type']
    });
    var tpl_time = new Ext.XTemplate(
        '<tpl for=".">',
        '<div class="search-item"><span style="color:{[ values.type=="N"?"green":(values.type=="U"?"red":"#444") ]}"><b>{time}</b> - {name}</span></div>',
        '</tpl>'
    );
    var combo_time  = new Ext.form.ComboBox({
        name: 'job_time',
        anchor: '100%',
        hiddenName: 'job_time',
        fieldLabel: _('Time'),
        valueField: 'time',
        displayField:'time',
        mode: 'local',
        store: store_time,
        allowBlank: false,
        typeAhead: true,
        forceSelection: true,
        triggerAction: 'all',
        tpl: tpl_time,
        itemSelector: 'div.search-item',
        disabled: true,
        selectOnFocus: false
    });
    combo_time.color_me = function( type ) { 
        switch( type ) {
            case 'N': combo_time.el.setStyle({ color: 'green' }); break;
            case 'U': combo_time.el.setStyle({ color: 'red' }); break;
            case 'F': combo_time.el.setStyle({ color: 'black' }); break;
        }
    };
    combo_time.on('select', function(combo,rec,ix){
        var type = rec.data.type;
        combo_time.color_me( type );
    });
    store_time.on('load', function(){
        var first = store_time.getAt(0);
        if( first ) {
            combo_time.enable();
            time_not_available.hide();
            combo_time.show();
            combo_time.setRawValue( first.data.time );
            combo_time.color_me( first.data.type );
            button_submit.enable();
        } else {
            time_not_available.show();
            combo_time.hide();
            button_submit.disable();
        }
        Baseliner.hideLoadingMask();
    });

    var calendar_reload = function( str_date ) {
        if( check_no_cal.checked ) return;
        try {
            var cnt = jc_grid.getStore().getCount();

            store_time.removeAll();
            combo_time.setRawValue('');

            if( cnt > 0 ) {
                var job_date_v = str_date ? str_date : job_date.getRawValue()
                Baseliner.showLoadingMask(main_form.getEl(), _("Loading available time for %1...", job_date_v ) );
                var bl  = combo_baseline.getValue();
                var json_res = job_grid_data({ warn: false });

                Baseliner.ajaxEval( '/job/build_job_window',
                    { bl: bl, job_date: job_date_v, job_contents: json_res, date_format: date_format  },
                    function(res){
                        if( res.success ) {
                            store_time.loadData( res.data ); // async
                        } else {
                            Baseliner.hideLoadingMask();
                            combo_time.disable();
                            Ext.Msg.alert( _('Error'), _('Error generating calendar windows: %1', res.msg ) );
                        }
                    }
                );
            } else {
                button_submit.disable();
                combo_time.disable();
            }
        } catch(e) {
            Baseliner.message(_('Error'), _('Could not reload calendar') );
        }
    };

    var time_not_available = new Ext.form.Label({
        hidden: true,
        fieldLabel: _('Time'), style: 'color: red; font-weight: bold; font-family: Calibri, Helvetica Neue, Arial, sans-serif;',
        text: _('no calendar windows available for selected date')
    });

    var render_icon = function( v ) {
        return String.format('<img style="float:left;vertical-align:top;" src="{0}" />', v );
    };

    var button_remove_item = new Ext.Button({
        text: _('Remove Job Item'),
        disabled: true,
        icon:'/static/images/del.gif',
        cls: 'x-btn-text-icon',
        handler: function() {
            var sm = jc_grid.getSelectionModel();
            var sel = sm.getSelected();
            if( sel ) {
                jc_grid.getStore().remove(sel);
                if (jc_grid.getStore().data.length == 0) { button_submit.disable(); }
                calendar_reload();
            }
        }
    });
    var adder = 80;

    var colModel = new Ext.grid.ColumnModel([
        { 
            dataIndex: 'icon', 
            renderer: render_icon,
            width: 20
        },
        { header: _('Job Item'),
             id:'item',
             width: 160 + adder,
             sortable: true,
             locked: false,
             renderer: function(v){ return String.format("<b>{0}</b>", v) },
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

    var jc_store = new Ext.data.Store({});

    var jc_grid = new Ext.grid.GridPanel({
        //fieldLabel:  _('Job Contents'),
        height: 300,
        anchor: '100%',
        name: 'jc',
        style: 'border:1px solid #bbb; margin-top: 10px',
        border: false,
        ds: jc_store,
        cm: colModel,
        enableDragDrop: true,
        ddGroup: 'lifecycle_dd',
        viewConfig: {
            enableRowBody: true,
            forceFit: true,
            getRowClass : function(rec, index, p, store){
                // slot squares
                var s = rec.data.moreInfo;
                if( ! s ) return;
                s = s.replace( /\<br\>/g , ', ');
                p.body = String.format(
                    '<div style="margin: 0 0 0 32;">{0}</div>'
                    , s );
                return ' x-grid3-row-expanded';
            }
        },
        tbar: [ button_remove_item ]
    });

    jc_grid.on('rowclick', function(){ button_remove_item.enable() } );
    jc_grid.on('rowdeselect', function(){ button_remove_item.disable() });
    
    // Drag and drop support
    jc_grid.on( 'render', function(){
        var el = jc_grid.getView().el.dom.childNodes[0].childNodes[1];
        var jc_grid_dt = new Ext.dd.DropTarget(el, {
            ddGroup: 'lifecycle_dd',
            copy: true,
            notifyDrop: function(dd, e, data) {
                var n = dd.dragData.node;
                var s = jc_grid.store;
                var add_node = function(node) {
                    var data = node.attributes.data;
                    // console.log( node );
                    var rec = new Ext.data.Record({
                        ns: data.ns,
                        icon: node.attributes.icon,
                        //item: data.name,
                        item: node.text,
                        text: node.text 
                    });
                    s.add(rec);
                    //s.sort('action', 'ASC');
                    var parent_node = node.parentNode;
                    // node.disable();
                    calendar_reload();
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
            if( check_no_cal.checked && comments.getValue().length == 0 ) {
                Ext.Msg.show({ title: _('Failure'), msg: _('En pases fuera de ventana, es obligatorio informar el motivo del pase en el campo observaciones'), width: 500, buttons: { ok: true } });
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
                        form_reset_all();
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

    var store_search = new Baseliner.JsonStore({
        url: '/job/items/json',
        listeners: {
            beforeload: {
                fn: function(store,opt) {
                    var bl = combo_baseline.getValue();
                    var job_type = main_form.getForm().getValues()['job_type'];
                    store.baseParams.bl = bl;
                    store.baseParams.job_type = job_type;
                }
            }
        },
        root: 'data',
        totalProperty: 'totalCount',
        id: 'id',
        fields: [
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
        ]
    });

    // Search Combo: Custom rendering Template
    // '<tpl if="moreInfo">',
    // '<br />{moreInfo}',
    // '</tpl>',
    // '<tpl if="packages">',
    // '<br />{packages}',
    // '</tpl>',

    var resultTpl = new Ext.XTemplate(
        '<tpl for="."><div ext:qtip="{moreInfo}" qtitle="' + _loc('More Info...') + '<hr>" class="search-item x-combo-list-item-unselectable {recordCls}">',
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
        fieldLabel: _('Add Job Items'),
        store: store_search,
        anchor: '50%',
        minChars: 0, //min_chars ,
        hidden: !show_job_search_combo,
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
            beforequery: function(qe){ delete qe.combo.lastQuery; }
        }
    });

    combo_search.on('beforeselect', function(combo, record, index) {
        if( record.get('can_job') != 1 ) {
            Ext.Msg.show({icon: 'ext-mb-error',
            buttons: { cancel: true },
            title: _('Blocked'),
            width: 500,
                msg: _('Package cannot be added to job')+":<br>" + record.get('why_not')
                });
            return false;
        }
        jc_store.add(record);
        store_search.remove(record);
        return false; // stops the combo from collapsing
    });     

    combo_search.on('collapse', function(){
        calendar_reload();
        //return true;
    });

    store_search.on('load', function(s,recs){
        if( recs.length == 0 ) {
            Baseliner.message(_('Warning'), _('No records found') );
            return;
        }
        if( jc_store.getCount() == 0 ) return;
        store_search.each( function(rec){
            var ix = jc_store.findExact('ns', rec.data.ns );
            if( ix > -1 ) {
                rec.set('recordCls', 'cannot-job' );
                rec.set('can_job', 0 );
            }
        });
        store_search.commitChanges();
    });

    var tb = new Ext.Toolbar({
        items: [
            '->',
            {
                xtype:'button', text: _('Reset'),
                icon:'/static/images/asterisk.gif',
                cls: 'x-btn-text-icon',
                handler: form_reset_all
            },
            button_submit
        ]
    });
    tb.on( 'afterrender', function(){
        //tb.el.parent().setStyle({ 'padding':'-10px' });
    });

    var main_form = new Ext.FormPanel({
        url: '/job/submit',
        //frame: true,
        bodyStyle: { 'background-color': '#eee', padding: 10 },
        title: _loc('Job Options'),
        forceFit: true,
        labelWidth: 150,
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
                        store_search.removeAll();
                        jc_grid.getStore().removeAll();
                        combo_baseline.setFieldLabel( checked.inputValue =='demote' ? label_orig : label_dest );
                        } }
                    },
                items: <% js_dumper(  $c->stash->{job_types} ) %>
            },
            combo_baseline,
            { 
                xtype:'fieldset', 
                style: { 'margin': '20 0 20 0' , 'padding': '15 15 15 15' },
                labelWidth: 135,
                items: [
                    combo_search,
                    { xtype: 'label', 
                        hidden: !show_job_search_combo,
                        style:'margin-left: 165px; font-size: 11px; font-family: Tahoma, Arial;', text:  _('Live search requires a minimum of %1 characters.', min_chars ) },
                    jc_grid
                ]
            },
            //combo_search,
            //{ xtype: 'container', style: 'height: 20px', fieldLabel:'x', html:  _('Live search requires a minimum of %1 characters.', min_chars ) },
            { 
                layout: 'column',
                fieldLabel: _('When'),
                columns: 2, bodyStyle: { 'background-color': '#eee'},
                bodyBorder: false,
                defaults: { bodyBorder: false, bodyStyle: { 'background-color': '#eee', 'padding': '0 25px 0 0'} },
                items: [
                    { width: 250, layout:'form', items: job_date, labelWidth: 40, bodyStyle: { 'background-color': '#eee'} },
                    { width: 500, layout:'form', items: combo_time , labelWidth: 40, bodyStyle: { 'background-color': '#eee'}},
                    time_not_available
                ]
            },
            check_no_cal,
            comments
        ]
    });

    comments.on('afterrender', function(){
        if( Ext.isIE ) {
            //comments.el.setStyle({ 'margin-left':'200px' });
        }
    });

    Ext.form.Field.prototype.msgTarget = 'side';
    
% unless( scalar _array _array( $c->stash->{baselines} ) ) {
    Ext.MessageBox.show({
        title: _('Error'),
        msg: _( "User doesn't have permissions to create a job in any environment" ),
        buttons: Ext.MessageBox.OK,
        icon: Ext.MessageBox.ERROR
        });
% }
    return main_form;
})
