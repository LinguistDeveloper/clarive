(function(params) {
    var data = params.data || {};

    var forceCheckBox = new Baseliner.CBox({
        fieldLabel: _('Move to new sha if branch exists?'),
        name: 'force',
        checked: data.force,
        default_value: false
    });

    return [
        Baseliner.ci_box({
            name: 'repo',
            role: 'Baseliner::Role::CI::Repository',
            fieldLabel: _('Repository'),
            with_vars: 1,
            value: data.repo,
            singleMode: false,
            force_set_value: true,
            allowBlank: false
        }), {
            xtype: 'textfield',
            fieldLabel: _('Sha or Ref'),
            name: 'sha',
            value: data.sha,
            allowBlank: false
        }, {
            xtype: 'textfield',
            fieldLabel: _('Branch Name'),
            name: 'branch',
            value: data.branch,
            allowBlank: false
        },
        forceCheckBox
    ]
})
