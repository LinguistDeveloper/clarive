(function(params) {

    Cla.help_push({ title:_('Change topic status'), path:'rules/palette/job/change-status' });

    var data = params.data || {};

    var old_status = new Baseliner.StatusBox({
        name: 'old_status',
        fieldLabel: _('Old Statuses'),
        value: data.old_status
    });
    var new_status = new Baseliner.StatusBox({
        name: 'new_status',
        fieldLabel: _('New Status'),
        allowBlank: false,
        singleMode: true,
        value: data.new_status
    });

    return [{
            xtype: 'textfield',
            fieldLabel: _('Topics'),
            name: 'topics',
            allowBlank: false,
            value: data.topics
        },
        old_status,
        new_status, {
            xtype: 'textfield',
            fieldLabel: _('User'),
            name: 'username',
            value: data.username
        }
    ]
})
