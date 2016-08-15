(function(params){
    var data = params.data || {};
    return [
        Baseliner.ci_box({ name:'template', fieldLabel:_('Template'), allowBlank: false, role:'Template' }),
    ]
});
