(function(params) {
    var data = params.data || {};

    return [
        Baseliner.ci_box({
            name: 'server',
            role: 'Baseliner::Role::HasAgent',
            fieldLabel: _('Server'),
            with_vars: 1,
            value: params.data.server,
            force_set_value: true,
            allowBlank: false
        }), {
            xtype: 'textfield',
            fieldLabel: _('User'),
            name: 'user',
            value: params.data.user
        },
        new Baseliner.MonoTextArea({
            allowBlank: false,
            fieldLabel: _('Remote Path'),
            height: 80,
            name: 'remote_path',
            value: params.data.remote_path
        })
    ]
})
