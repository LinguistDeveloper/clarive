(function(params){
    return [
       { xtype:'textfield', fieldLabel: _('Password'), anchor: '100%', name:'password', inputType:'password', value: params.rec.realname },
       { xtype:'textfield', fieldLabel: _('Realname'), anchor: '100%', name:'realname', value: params.rec.realname },
       { xtype:'textfield', fieldLabel: _('API Key'), anchor: '100%', name:'api_key', value: params.rec.api_key },
       { xtype:'textfield', fieldLabel: _('Phone'), anchor: '30%', name:'phone', value: params.rec.phone }
    ]
})



