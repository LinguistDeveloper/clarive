(function(params){
    return [
       { xtype:'textfield', fieldLabel: _('Password'), anchor: '100%', name:'password', inputType:'password', value: params.rec.realname },
       { xtype:'textfield', fieldLabel: _('Realname'), anchor: '100%', name:'realname', value: params.rec.realname },
       { xtype:'textfield', fieldLabel: _('Alias'), anchor: '100%', name:'alias', value: params.rec.alias },
       { xtype:'textfield', fieldLabel: _('Email'), anchor: '100%', name:'email', value: params.rec.email },
       { xtype:'textfield', fieldLabel: _('API Key'), anchor: '100%', name:'api_key', value: params.rec.api_key },
       { xtype:'textfield', fieldLabel: _('Phone'), anchor: '50%', name:'phone', value: params.rec.phone }
    ]
})



