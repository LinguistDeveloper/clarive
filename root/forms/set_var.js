(function(params){
    var data = params.data || {};
    return [
        { xtype:'textarea', fieldLabel: _('Variable'), height: 80, name: 'variable', value: params.data.variable },
        { xtype:'textarea', fieldLabel: _('Value'), height: 300, name: 'value', value: params.data.value }
    ]
})

