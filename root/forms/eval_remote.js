(function(params){
    var data = params.data || {};
    return [
        Baseliner.ci_box({ name: 'server', role:'Server', fieldLabel:_('Server'), value: params.data.server, force_set_value: true }),
        { xtype:'textfield', fieldLabel: _('User'), name: 'user', value: params.data.user },
        { xtype:'textarea', fieldLabel: _('Code'), height: 400, name: 'code', value: params.data.code }
    ]
})


