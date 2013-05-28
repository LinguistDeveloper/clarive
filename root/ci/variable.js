(function(params){
    return [
       // name is now the variable name { xtype:'textfield', fieldLabel: _('Variable'), name:'variable', allowBlank: true, value: params.rec.variable }
       { xtype: 'textarea', fieldLabel: _('Description'), height: 200, name:'description', allowBlank: true, value: params.rec.description }
    ]
})

