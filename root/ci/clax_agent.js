(function(params){
    return [
        Baseliner.ci_box({ name:'server', fieldLabel:_('Server'), allowBlank: true,
               role:'Server', value: params.rec.server, force_set_value: true, singleMode: true }),
        { xtype: 'textfield', fieldLabel: _('User'), name:'user', anchor:'50%' },
        { xtype: 'textfield', fieldLabel: _('Auth Username'), name:'auth_username', anchor:'50%' },
        { xtype: 'textfield', fieldLabel: _('Auth Password'), name:'auth_password', anchor:'50%' },
        { xtype: 'textfield', fieldLabel: _('Port'), name:'port', anchor:'10%', allowBlank: false }
    ]
})

