(function(params){
    var data = params.data || {};
    return [
        Baseliner.ci_box({ name: 'user', role:'User', with_vars: 1, fieldLabel:_('User'), value: data.user, force_set_value: true })
    ]
})

