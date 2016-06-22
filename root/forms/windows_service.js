(function(params) {
    var data = params.data || {};

    var errors = new Baseliner.ComboDouble({
        fieldLabel: _('Errors'),
        name: 'errors',
        value: data.errors || 'fail',
        data: [
            ['fail', _('fail')],
            ['warn', _loc('warn')],
            ['silent', _loc('silent')]
        ]
    });

    var action = new Baseliner.ComboDouble({
        fieldLabel: _('Action'),
        name: 'action',
        value: data.action || 'start',
        data: [
            ['start', _loc('start')],
            ['restart', _loc('restart')],
            ['stop', _loc('stop')],
        ]
    });

    return [
        Baseliner.ci_box({
            allowBlank: false,
            name: 'server',
            role: 'Baseliner::Role::HasAgent',
            fieldLabel: _('Server'),
            with_vars: 1,
            value: data.server,
            force_set_value: true
        }),
        {xtype: 'textfield', fieldLabel: _('Service'), name: 'service', allowBlank: false, value: data.service},
        action,
        errors,
    ]
})
