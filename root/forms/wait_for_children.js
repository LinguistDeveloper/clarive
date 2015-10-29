(function(params){
    var data = params.data || {};
    return [
        new Baseliner.ArrayGrid({
            fieldLabel: _('Children stash keys to export'),
            name: 'parallel_stash_keys',
            value: data.parallel_stash_keys,
            default_value:'variable_name_here'
        }),
        new Baseliner.ComboSingle({
            fieldLabel: _('Errors'),
            name:'errors',
            value: data.errors || 'fail',
            data: [
                'fail',
                'warn',
                'silent'
            ]
        })
    ]
});
