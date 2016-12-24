(function(params){
    var data = params.data || {};

    var expr = new Cla.AceEditor({
            fieldLabel:_('Expression'), anchor:'100%', height: 500, name:'expr', value: params.data.expr
        });

    return [
        { xtype:'textfield', fieldLabel: _('Variable'), name: 'variable', value: params.data.variable },
        expr
    ]
})
