(function(params) {
    Cla.help_push({
        title: _('Change topic status'),
        path: 'rules/palette/job/change-status'
    });

    var data = params.data || {};

    var oldStatusBox = new Baseliner.StatusBox({
        name: 'old_status',
        fieldLabel: _('Old Statuses'),
        value: data.old_status,
        withExtraValues: true
    });
    var newStatusBox = new Baseliner.StatusBox({
        name: 'new_status',
        fieldLabel: _('New Status'),
        allowBlank: false,
        singleMode: true,
        value: data.new_status,
        withExtraValues: true
    });

    return [{
            xtype: 'textfield',
            fieldLabel: _('Topics'),
            name: 'topics',
            allowBlank: false,
            value: data.topics
        },
        oldStatusBox,
        newStatusBox,
        new Baseliner.UserBox({
            value: data.username,
            withVars: true,
            withExtraValues: true
        }),
    ]
})
