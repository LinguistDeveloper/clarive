(function(params) {
    var data = params.data || {};

    var statusesFromBox = new Baseliner.StatusBox({
        name: 'statuses_from',
        fieldLabel: _('From Status'),
        value: data.statuses_from || ''
    });

    return [{
        xtype: 'fieldset',
        title: _('IF INPUT MATCH...'),
        items: [
            statusesFromBox
        ]
    }]
})
