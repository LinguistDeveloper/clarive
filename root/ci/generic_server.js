(function(params){
    var data = params.rec;
    return [
        { xtype: 'textfield', fieldLabel: _('Hostname or IP'), name:'hostname', allowBlank: false, value: data.hostname }
    ]
})
