(function(params){
    return [
       Baseliner.ci_box({ name:'server', fieldLabel:_('Server'), role:'Server' }),
       { xtype:'textfield', fieldLabel: _('User'), name:'user', value: params.rec.user },
       { xtype:'textfield', fieldLabel: _('Port'), name:'port', value: params.rec.port },
       { xtype:'textfield', fieldLabel: _('Timeout (s)'), name:'timeout', value: params.rec.timeout },
       { xtype:'textarea', height: 180, anchor:'100%', fieldLabel: _('Private Key'), name:'private_key', allowBlank: true }
    ]
})
