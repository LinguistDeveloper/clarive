(function(params){
    var data = params.data || {};
    return [
        Baseliner.ci_box({ name: 'nature', role:'Nature', with_vars: 1, fieldLabel:_('Nature'), value: params.data.nature, force_set_value: true }) 
    ]
})

