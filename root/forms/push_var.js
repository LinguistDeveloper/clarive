(function(params) {
    var data = params.data || {};

    return [{
            xtype: 'textfield',
            fieldLabel: _('Variable'),
            name: 'variable',
            value: data.variable
        }, {
            xtype: 'textarea',
            fieldLabel: _('Value'),
            height: 300,
            name: 'value',
            value: data.value
        },
        new Baseliner.CBox({
            fieldLabel: _('Keep values unique?'),
            name: 'uniq',
            checked: data.uniq,
            default_value: true
        }),
    ]
})
