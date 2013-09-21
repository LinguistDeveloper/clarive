(function(params){
    return [
       Baseliner.ci_box({ name:'server', anchor:'100%', fieldLabel:_('Server'), role:'Server', force_set_value: true, value: params.rec.server }),
       { xtype:'textarea', height: 80, anchor:'100%', fieldLabel: _('Data Source'), name:'data_source', value: params.rec.data_source },
       { xtype:'textfield', fieldLabel: _('User'), anchor:'100%', name:'user', value: params.rec.user },
       { xtype:'textfield', inputType:'password', anchor:'100%', name:'password', fieldLabel: _('Password'), value: params.rec.password }
    ]
})


