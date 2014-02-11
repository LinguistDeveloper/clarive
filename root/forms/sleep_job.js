(function(params){
    var data = params.data || {};
    return [
        { xtype:'textfield', fieldLabel: _('Seconds'), name: 'seconds', value: params.data.seconds }
    ]
})