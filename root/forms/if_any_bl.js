(function(params) {
    var data = params.data || {};
    Cla.help_push({
        title: _('IF ANY bl THEN'),
        path: 'rules/palette/control/if-bl'
    });

    return [
        Baseliner.ci_box({
            name: 'bls',
            hiddenName: 'bls',
            allowBlank: false,
            class: 'BaselinerX::CI::bl',
            with_vars: 1,
            fieldLabel: _('Environment'),
            value: data.bls,
            singleMode: false,
            force_set_value: true
        })
    ]
})
