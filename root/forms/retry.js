(function(params){
    var data = params.data || {};

    return [ {
            xtype:'textfield',
            vtype:'integer',
            fieldLabel: _('Attempts'),
            name: 'attempts',
            allowBlank: false,
            value: data.attempts || 1,
            anchor: '50%'
        }, {
            xtype:'textfield',
            vtype:'integer',
            fieldLabel: _('Pause (s)'),
            name: 'pause',
            allowBlank: false,
            value: data.pause || 0,
            anchor: '50%'
        }
    ];
})

