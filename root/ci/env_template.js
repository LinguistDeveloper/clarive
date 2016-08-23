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
            variables
        ]
    }
})