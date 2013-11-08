(function(params){
    var data = params.data || {};
    var variable = new Baseliner.MonoTextArea({ fieldLabel: _('Variable'), height: 80, name: 'variable', value: data.variable || '' });
    var values   = new Baseliner.MonoTextArea({ fieldLabel: _('Values'), height: 100, name: 'values', value: data.values || '' });
    return [
        variable, values
    ]
});

