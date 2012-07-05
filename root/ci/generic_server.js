(function(params){
    var data = params.rec.data;
    return [
        { xtype: 'textfield', fieldLabel: _('Hostname or IP'), name:'hostname', allowBlank: false, value: data.hostname }
    ]
})
