(function(params) {
    if (params == undefined) params = {};

    return [
        Baseliner.ci_box({
            name: 'repo',
            fieldLabel: _('Repository'),
            allowBlank: false,
            role: 'Repository',
            value: params.rec.repo,
            force_set_value: true
        }),
        Baseliner.ci_box({
            name: 'rev',
            fieldLabel: _('Revision'),
            allowBlank: false,
            role: 'Revision',
            value: params.rec.rev,
            force_set_value: true
        }), {
            xtype: 'textfield',
            anchor: '100%',
            fieldLabel: _('File'),
            name: 'file',
            allowBlank: false,
            value: params.file
        }, {
            xtype: 'textfield',
            anchor: '100%',
            fieldLabel: _('Line'),
            name: 'line',
            allowBlank: false,
            value: params.line
        }
    ]
})
