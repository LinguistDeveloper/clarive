(function(params){
    var data = params.data || {};
    return [
        Baseliner.ci_box({ name: 'natures', role:'Nature', with_vars: 1, fieldLabel:_('Natures'), value: data.natures, singleMode: false, force_set_value: true })
    ]
})




