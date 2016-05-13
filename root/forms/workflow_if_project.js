(function(params) {
    var data = params.data || {};

    var projects = Cla.ci_box({
        name: 'projects',
        fieldLabel: _('Projects'),
        allowBlank: true,
        'class': 'project',
        value: data.projects,
        force_set_value: true,
        singleMode: false
    });

    return [{
        xtype: 'fieldset',
        title: _('IF INPUT MATCH...'),
        items: [
            projects
        ]
    }]
})