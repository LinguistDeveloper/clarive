(function(params) {
    Cla.help_push({
        title: _('IF From Status IS'),
        path: 'rules/palette/workflow/if-status-from'
    });

    var data = params.data || {};

    var statusesFromBox = new Baseliner.StatusBox({
        name: 'statuses_from',
        allowBlank: false,
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
