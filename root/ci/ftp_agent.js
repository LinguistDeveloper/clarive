(function(params){
    return [
       Baseliner.ci_box({ name:'server', fieldLabel:_('Server'), role:'Server', force_set_value:true, value: params.rec.server }),
       { xtype:'textfield', fieldLabel: _('Home'), name:'home' },
       { xtype:'textfield', fieldLabel: _('User'), name:'user' },
       { xtype:'textfield', inputType:'password', name:'password', fieldLabel: _('Password') }
    ]
})


