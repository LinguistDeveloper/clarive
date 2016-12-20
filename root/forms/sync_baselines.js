(function(params) {
    var data = params.data || {};

    return [
        Baseliner.ci_box({
            name: 'bls',
            fieldLabel: _('BLs'),
            allowBlank: true,
            'class': 'bl',
            value: data.bls,
            force_set_value: true,
            singleMode: false
        })
    ];
})
