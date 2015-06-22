(function(params){
    var common = Cla.dashlet_common(params);
    var data = params.data;

    /*var limit = new Ext.ux.form.SpinnerField({ 
        value: data.limit,
        name: "limit",
        fieldLabel: _("Limit of records to animate")
    });*/


    return common.concat([
        { xtype:'textfield', fieldLabel: _('Background Color'), name:'background_color', value:data.background_color||'#fff' },
        new Baseliner.ComboDouble({ fieldLabel: _('Animation Start Mode'), name:'start_mode', value: data.start_mode || 'auto', data: [
            ['auto', _('Automatically')],
            ['manual', _('Manually')]
          ] 
        }),
        //limit
    ])
})





