(function(params){
    var common = Cla.dashlet_common(params);
    var data = params.data;
    return common.concat([
        Baseliner.ci_box({ name:'bls', fieldLabel:_('Which bls do you want to see'), allowBlank: true,
            'class':'bl', value: data.bls, force_set_value: true, singleMode: false })
    ])
})




