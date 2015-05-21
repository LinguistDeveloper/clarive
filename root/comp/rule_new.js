(function(params){
    var rule_id = params.rec.id || '';
    var check_sm_events = new Ext.grid.CheckboxSelectionModel({
        singleSelect: true,
        sortable: false,
        checkOnly: true
    });
    var store_events = new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        autoLoad: true,
        totalProperty:"totalCount", 
        url: '/rule/event_list',
        baseParams: Ext.apply({}, params),
        fields: [ 'type', 'name', 'description', 'key' ]
    });
    store_events.on('load',function(){
        var row = 0;
        store_events.each( function(r){
            if( r.data.key == params.rec.rule_event ) {
                check_sm_events.selectRow( row );
            }
            row++;
        });
    });
    var grid_events = new Ext.grid.GridPanel({
        sm: check_sm_events,
        store: store_events,
        border: false,
        height: 280,
        viewConfig: { forceFit: true },
        columns:[
            check_sm_events,
            { header: _('Event'), width: 100, dataIndex: 'name', renderer:function(v){ return '<b>'+v+'</b>'}},
            { header: _('Event Type'), width: 60, dataIndex: 'type' },
            { header: _('Event Key'), width: 60, hidden: true, dataIndex: 'key' },
            { header: _('Description'), width: 100, dataIndex: 'description', renderer: Baseliner.render_wrap }
        ]
    });
    var combo_type = new Ext.form.ComboBox({ 
               fieldLabel:_('Type'), 
               name: 'rule_type', 
               hiddenName: 'rule_type', 
               valueField: 'rule_type', 
               value: params.rec.rule_type || 'event',
               displayField: 'rule_type_name',
               typeAhead: false, minChars: 1, mode: 'local', 
               store: [
                  [ 'event', _('Event') ],
                  [ 'chain', _('Job Chain') ],
                  [ 'report', _('Report') ],
                  [ 'independent', _('Independent') ],
                  [ 'dashboard', _('Dashboard') ],
                  [ 'fieldlets', _('Fields') ]
               ],
               editable: false, forceSelection: true, triggerAction: 'all',
               allowBlank: false
    });
    combo_type.on('select', function(){
        var v = combo_type.getValue();
        reconfigure_on_type( v );
        store_events.load({ params: { event_type: v } });
    });
    var reconfigure_on_type = function(v){
        if( v == 'chain' ) {
            wiz.last = wiz.current;
            wiz.button_setup();
            job_chain_form.show();
            msg_job.show();
            msg_ev.hide();
            grid_events.hide();
        } else if( v == 'independent' ) {
            wiz.last = wiz.current;
            wiz.button_setup();
            job_chain_form.hide();
            webservice_form.show();
            msg_job.hide();
            msg_ev.hide();
            grid_events.hide();
        } else if( v == 'report' ) {
            wiz.last = wiz.current;
            wiz.button_setup();
            job_chain_form.hide();
            webservice_form.hide();
            msg_job.hide();
            msg_ev.hide();
            grid_events.hide();
        } else if( v == 'fieldlets' || v == 'dashboard' ) {
            wiz.last = wiz.current;
            wiz.button_setup();
            job_chain_form.hide();
            webservice_form.hide();
            msg_job.hide();
            msg_ev.hide();
            grid_events.hide();
        } else {
            wiz.last = wiz.current + 1;
            wiz.button_setup();
            job_chain_form.hide();
            msg_job.hide();
            msg_ev.show();
            grid_events.show();
        }
    }
    
    // job chain form
    var job_chain_form = new Ext.form.FieldSet({
        hidden: true, border: false,
        items: [
            new Baseliner.ComboSingle({ fieldLabel: _('Default'), name:'chain_default', value: params.rec.chain_default, data: [
                '-',
                'promote',
                'demote',
                'static'
            ]}),
            { xtype:'textarea', height: 180, anchor:'100%', fieldLabel:_('Chain Description'), name: 'rule_desc', value: params.rec.rule_desc }
        ]
    });
    // webservice-soap form
    var wsdl = Ext.isIE 
        ? new Ext.form.TextArea({ height: 300, anchor:'100%', fieldLabel:_('WSDL'), name: 'wsdl', value: params.rec.wsdl, hidden: params.rec.subtype!='soap' })
        : new Baseliner.AceEditor({ fieldLabel:_('WSDL'), anchor:'100%', height: 300, name:'wsdl', value: params.rec.wsdl, hidden: params.rec.subtype!='soap' });
    var subtype = new Baseliner.ComboSingle({ fieldLabel: _('Web Service Type'), name:'subtype', value: params.rec.subtype, data: [
                '-', 'soap' ]});
    var authtype = new Baseliner.ComboDouble({ fieldLabel: _('Authentication'), name:'authtype', value: params.rec.authtype||'required', 
            data: [ ['required',_('Auth Required')], ['none',_('No login needed')] ]});
    var webservice_form = new Ext.form.FieldSet({
        hidden: true, border: false, height: 400, anchor:'100%', items: [ subtype, wsdl, authtype ]
    });
    subtype.on('select', function(){
        if( subtype.getValue() == 'soap' ) {
            wsdl.show();
        } else {
            wsdl.hide();
        }
    });
    // other panes
    var msg_ev = new Ext.Container({ border:false, html:'<span id="boot"><p><h4>'+_('Select the Event') + ':</h4></p>' });
    var msg_job = new Ext.Container({ hidden: true, border:false, html:'<span id="boot"><p><h4>'+_('Job Chain Details') + ':</h4></p>' });
    // PAGE 1
    var form_events = new Baseliner.FormPanel({
        defaults: { anchor: '90%' },
        border: false,
        items: [
            { xtype:'textfield', fieldLabel:_('Name'), name:'rule_name', value: params.rec.rule_name },
            combo_type, msg_ev, msg_job, grid_events, job_chain_form, webservice_form
        ]
    });

    // PAGE 2
    var form_when = new Ext.FormPanel({
        border: false,
        items: [
            { xtype:'hidden', name:'rule_id', value: rule_id }, 
            {
                xtype: 'radiogroup',
                anchor: '50%',
                fieldLabel: _('Event Type'),
                defaults: {xtype: "radio",name: "rule_when"},
                value: params.rec.rule_when,
                items: [
                    {boxLabel: _('Pre Online'), inputValue: 'pre-online', checked: false },
                    {boxLabel: _('Post Online'), inputValue: 'post-online', checked: false },
                    {boxLabel: _('Post Offline'), inputValue: 'post-offline', checked: true }
                ]
            }
        ]
    });

    //------------ Card Navigation 
    var wiz = new Baseliner.Wizard({
        height: 450,
        done_handler: function(){
            var d = form_events.getValues();
            var rule_type = combo_type.getValue();
            d = Ext.apply( d, form_when.getForm().getValues() );
            if( rule_type == 'event' ) {
                if( check_sm_events.hasSelection() ) {
                    var rec = check_sm_events.getSelected();
                    d.rule_event = rec.data.key;
                } else {
                    Baseliner.error( _('Rule'), _('No events selected') );
                    return;
                }
            }
            if( d.rule_name.length < 1 ) {
                Baseliner.error( _('Rule'), _('Missing rule name') );
                return;
            }
            Baseliner.ajaxEval('/rule/save', d, function(res){
                if( res.success ) {
                    Baseliner.message(_('Rule'), _('Rule saved successfully') );
                    wiz.destroy();
                }
            }, function(res){
                Ext.Msg.show({
                    title: _('Rule'),
                    width: 800,
                    height: 600,
                    msg: res.msg,
                    buttons: Ext.Msg.OK,
                    icon: Ext.Msg.ERROR
                });
            });
            //wiz.ownerCt.close();
        },
        items: [
            form_events, form_when
        ]
    });

    if( params.rec.rule_type ) {
        reconfigure_on_type( params.rec.rule_type );
    }
    return wiz;
})
