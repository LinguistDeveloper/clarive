(function(params){
    var data = params.data || {};

    var common = params.common_options || Cla.dashlet_common(params);

    return common.concat([
        { xtype:'textfield', allowBlank: false, fieldLabel: _('URL'), name: 'url', value: data.url }
    ]);
})
