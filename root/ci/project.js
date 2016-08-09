(function(params) {
    var data_value = params.rec.data || {};

    var variables = new Baseliner.VariableForm({
        show_btn_copy: true,
        name: 'variables',
        fieldLabel: _('Variables'),
        height: 300,
        data: params.rec.variables,
        deferredRender: false,
        renderHidden: false
    });

    return {
        fields: [
            Baseliner.ci_box({
                name: 'bls',
                fieldLabel: _('Environments'),
                allowBlank: true,
                baseParams: {
                    nin: {
                        bl: ['*']
                    }
                },
                role: 'Internal',
                'class': 'bl',
                value: params.rec.bls,
                force_set_value: true,
                singleMode: false
            }),
            Baseliner.ci_box({
                name: 'parent_project',
                fieldLabel: _('Parent Project'),
                allowBlank: true,
                role: 'Project',
                value: params.rec.parent_project,
                force_set_value: true,
                singleMode: true
            }),
            Baseliner.ci_box({
                name: 'repositories',
                fieldLabel: _('Repositories'),
                allowBlank: true,
                role: 'Repository',
                value: params.rec.repositories,
                singleMode: false,
                force_set_value: params.rec.repositories ? true : false
            }),
            variables
        ]
    }
})