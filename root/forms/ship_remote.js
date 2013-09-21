(function(params){
    var data = params.data || {};
    return [
        Baseliner.ci_box({ name: 'server', role:'Server', fieldLabel:_('Server'), with_vars: 1, value: params.data.server, force_set_value: true }),
        { xtype:'textfield', fieldLabel: _('User'), name: 'user', value: params.data.user },
        { xtype:'textarea', fieldLabel: _('Local Path'), height: 80, name: 'local_path', value: params.data.local_path },
        { xtype:'textarea', fieldLabel: _('Remote Path'), height: 80, name: 'remote_path', value: params.data.remote_path },
        { xtype:'textarea', fieldLabel: _('Chown'), height: 80, name: 'chown', value: params.data.chown },
        { xtype:'textarea', fieldLabel: _('Chmod'), height: 80, name: 'chmod', value: params.data.chmod }
    ]
})



