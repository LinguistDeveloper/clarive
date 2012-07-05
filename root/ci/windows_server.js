(function(params){
    var data = params.rec.data;
    return [
        { xtype: 'textfield', fieldLabel: _('Hostname or IP'), name:'hostname', allowBlank: false, value: data.domain },
        { xtype: 'textfield', fieldLabel: _('Domain'), name:'domain', allowBlank: false, value: data.domain },
        { xtype: 'textfield', fieldLabel: _('NetBIOS Name'), name:'netbios', allowBlank: false, value: data.domain }
    ]
})

