(function(params){
    var data = params.data || {};
    return [
        Baseliner.ci_box({ name: 'natures', role:'Nature', fieldLabel:_('Natures'), value: data.natures, singleMode: false, force_set_value: true })
    ]
})




