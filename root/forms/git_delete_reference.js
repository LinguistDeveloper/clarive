(function(params) {
    var data = params.data || {};

    return [
        Baseliner.ci_box({
            name: 'repo',
            role: 'Baseliner::Role::CI::Repository',
            fieldLabel: _('Repository'),
            with_vars: 1,
            value: data.repo,
            singleMode: false,
            force_set_value: true,
            allowBlank: false
        }),
        new Baseliner.ComboDouble({
            name: 'type',
            fieldLabel: _('Type'),
            value: data.type,
            data: [
                ['any', _('Any')],
                ['branch', _('Branch')],
                ['tag', _('Tag')]
            ]
        }), {
            xtype: 'textfield',
            fieldLabel: _('Sha or Ref'),
            name: 'sha',
            value: data.sha,
            allowBlank: false
        }
    ]
})
