(function(params){
    var data = params.data || {};
    return [
        Baseliner.ci_box({ name: 'nature', role:'Nature', fieldLabel:_('Nature'), value: params.data.nature, force_set_value: true })
    ]
})



