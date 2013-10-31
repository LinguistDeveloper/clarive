(function(params){
    var data = params.data || {};
    return [
        Baseliner.ci_box({ name: 'user', classname:'user', with_vars: 1, fieldLabel:_('User'), value: data.user, singleMode: false, force_set_value: true })
    ]
})

