(function(params) {
    Cla.help_push({
        title: _('IF Project IS'),
        path: 'rules/palette/workflow/if-project'
    });

    var data = params.data || {};

    var projects = Cla.ci_box({
        name: 'projects',
        fieldLabel: _('Projects'),
        allowBlank: false,
        class: 'BaselinerX::CI::project',
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