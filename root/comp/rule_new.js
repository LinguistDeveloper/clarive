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
        fields: [ 'type', 'name', 'description', 'key' ],
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
                  [ 'loop', _('Loop') ]
               ],
               editable: false, forceSelection: true, triggerAction: 'all',
               allowBlank: false
    });
    combo_type.on('select', function(){
        var v = combo_type.getValue();
        store_events.load({ params: { event_type: v } });
    });
    // PAGE 1
    var form_events = new Ext.FormPanel({
        defaults: { anchor: '90%' },
        border: false,
        items: [
            { xtype:'textfield', fieldLabel:_('Name'), name:'rule_name', value: params.rec.rule_name },
            combo_type,
            { border:false, html:'<span id="boot"><p><h4>'+_('Select the Event') + ':</h4></p>' },
            grid_events
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
    var card = new Baseliner.Wizard({
        height: 450,
        done_handler: function(){
            var d = form_events.getForm().getValues();
            d = Ext.apply( d, form_when.getForm().getValues() );
            if( check_sm_events.hasSelection() ) {
                var rec = check_sm_events.getSelected();
                d.rule_event = rec.data.key;
            }
            Baseliner.ajaxEval('/rule/save', d, function(res){
                if( res.success ) {
                    Baseliner.message(_('Rule'), _('Regla guardada con éxito') );
                    card.destroy();
                } else {
                    Baseliner.error(_('Rule'), res.msg );
                }
            });
            //card.ownerCt.close();
        },
        items: [
            form_events, form_when
        ]
    });
    return card;
})
