(function(parms){
    return [
        { xtype: 'textfield', fieldLabel: _('Hostname or IP'), name:'hostname', allowBlank: false },
        { xtype: 'textfield', fieldLabel: _('Domain'), name:'domain', allowBlank: false },
        { xtype: 'textfield', fieldLabel: _('NetBIOS Name'), name:'netbios', allowBlank: false }
    ]
})

