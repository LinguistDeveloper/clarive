(function(params){
    var common = Cla.dashlet_common(params);
    var data = params.data;

    /*var limit = new Ext.ux.form.SpinnerField({ 
        value: data.limit,
        name: "limit",
        fieldLabel: _("Limit of records to animate")
    });*/


    return common.concat([
        { xtype:'textfield', fieldLabel: _('Background Color'), name:'background_color', value:data.background_color||'#FFFFFF' },
        new Baseliner.ComboDouble({ fieldLabel: _('Animation Start Mode'), name:'start_mode', value: data.start_mode || 'auto', data: [
            ['auto', _('Automatically')],
            ['manual', _('Manually')]
          ] 
        }),
        { xtype:'datefield', fieldLabel: _('Date from'), anchor:'100%', format:'Y-m-d', name: 'start_date', value: data.start_date },
        { xtype:'datefield', fieldLabel: _('Date to'), anchor:'100%', format:'Y-m-d', name: 'end_date', value: data.end_date },
        { xtype:'textfield', fieldLabel: _('Maximum Node'), name:'max_node', value:data.max_node|| 0 },
        { xtype:'textfield', fieldLabel: _('Minimum Node Category'), name:'min_node', value:data.min_node|| 0 }
        //limit
    ])
})





