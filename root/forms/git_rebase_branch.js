(function(params) {
    var data = params.data || {};

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
            fieldLabel: _('Branch'),
            name: 'branch',
            value: data.branch,
            allowBlank: false
        }, {
            xtype: 'textfield',
            fieldLabel: _('Upstream Branch'),
            name: 'upstream',
            value: data.upstream,
            allowBlank: false
        }
    ]
})
