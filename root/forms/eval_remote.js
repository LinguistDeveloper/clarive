(function(params){
    var data = params.data || {};
    return [
        Baseliner.ci_box({ name: 'server', role:'Server', with_vars: 1, fieldLabel:_('Server'), value: params.data.server, force_set_value: true }),
        { xtype:'textfield', fieldLabel: _('User'), name: 'user', value: params.data.user },
        new Baseliner.MonoTextArea({ fieldLabel: _('Code'), height: 400, name: 'code', value: params.data.code })
    ]
})


