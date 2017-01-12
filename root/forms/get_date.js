(function(params) {
    var data = params.data || {};

    Cla.help_push({
        title: _('Get date'),
        path: 'rules/palette/services/get-date'
    });

    return [{
            xtype: 'textfield',
            fieldLabel: _('Date (or blank for CURRENT date)'),
            name: 'date',
            anchor: '100%',
            allowBlank: true,
            value: data.date
        },
        new Baseliner.ComboDouble({
            name: 'format',
            fieldLabel: _('Date Format'),
            editable: true,
            forceSelection: false,
            value: data.format,
            data: [
                ['%Y-%m-%d %H:%M:%S', 'YYYY-MM-DD hh:mm:ss'],
                ['%Y/%m/%d %H:%M:%S', 'YYYY/MM/DD hh:mm:ss'],
                ['%Y-%m-%dT%H:%M:%S', 'YYYY-MM-DDThh:mm:ss'],
                ['%d-%m-%Y %H:%M:%S', 'DD-MM-YYYY hh:mm:ss'],
                ['%d/%m/%Y %H:%M:%S', 'DD/MM/YYYY hh:mm:ss'],
                ['%Y-%m-%d', 'YYYY-MM-DD'],
                ['%Y/%m/%d', 'YYYY/MM/DD'],
                ['%d-%m-%Y', 'DD-MM-YYYY'],
                ['%d/%m/%Y', 'DD/MM/YYYY']
            ]
        })
    ]
})
