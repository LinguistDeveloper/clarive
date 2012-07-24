(function(params){
    return [
       Baseliner.ci_box({ name:'server', fieldLabel:_('Server'), role:'Server' }),
       { xtype:'textfield', fieldLabel: _('Port'), name:'port' },
       { xtype:'textfield', fieldLabel: _('SID'), name:'sid' },
       { xtype:'textfield', fieldLabel: _('User'), name:'user' },
       { xtype:'textfield', inputType:'password', name:'password', fieldLabel: _('Password') }
    ]
})

