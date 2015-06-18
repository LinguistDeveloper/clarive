(function(params){
    var data = params.data || {};
    return [
        Baseliner.ci_box({ name: 'nature', role:'Nature', fieldLabel:_('Nature'), with_vars: 1, value: params.data.nature, force_set_value: true }),
        { xtype:'textfield', fieldLabel: _('Cut Path'), name: 'cut_path', value: params.data.cut_path || '/' }
    ]
})



