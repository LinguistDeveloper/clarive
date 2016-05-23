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
        new Baseliner.ComboDouble({
            fieldLabel: _('Direction'),
            name: 'direction',
            allowBlank: false,
            value: params.data.direction,
            data: [
                ['local-to-remote', _('Local to remote')],
                ['remote-to-local', _('Remote to local')]
            ]
        }),
        new Baseliner.MonoTextArea({
            allowBlank: false,
            fieldLabel: _('Remote Path'),
            height: 80,
            name: 'remote_path',
            value: params.data.remote_path
        }),
        new Baseliner.MonoTextArea({
            allowBlank: false,
            fieldLabel: _('Local Path'),
            height: 80,
            name: 'local_path',
            value: params.data.local_path
        }),
        new Ext.form.Checkbox({
            fieldLabel: _('Delete extraneous files from destination'),
            name: 'delete_extraneous',
            checked: params.data.delete_extraneous === 'on' ? true : false
        }),
    ]
})
