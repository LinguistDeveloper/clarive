(function(params){
    var data = params.data || {};
    var variable = new Baseliner.MonoTextArea({ fieldLabel: _('Variable'), height: 80, name: 'variable', value: data.variable || '' });
    var value    = new Baseliner.MonoTextArea({ fieldLabel: _('Value'), height: 100, name: 'value', value: data.value || '' });
    return [
        variable, value
    ]
});
