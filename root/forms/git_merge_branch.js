(function(params) {
    var data = params.data || {};

    var noFFCheckbox = new Baseliner.CBox({
        fieldLabel: _('No Fast-Forward?'),
        name: 'no_ff',
        checked: data.no_ff,
        default_value: true
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
            fieldLabel: _('Topic Branch'),
            name: 'topic_branch',
            value: data.topic_branch,
            allowBlank: false
        }, {
            xtype: 'textfield',
            fieldLabel: _('Into Branch'),
            name: 'into_branch',
            value: data.into_branch,
            allowBlank: false
        }, {
            xtype: 'textfield',
            fieldLabel: _('Message'),
            name: 'message',
            value: data.message,
            allowBlank: true
        },
        noFFCheckbox
    ]
})
