(function(params) {
    var data = params.data || {};

    return [
        { xtype:'textfield', fieldLabel: _('Mid'), name: 'mid', value: data.mid },
    ];
})
