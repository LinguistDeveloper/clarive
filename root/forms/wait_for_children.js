(function(params){
    var data = params.data || {};
    return [
        //{ xtype:'textfield', allowBlank:false, fieldLabel: _('Result stash variable'), name: 'parallel_data_key', value: data.parallel_data_key },
        new Baseliner.ArrayGrid({
            fieldLabel: _('Children stash keys to export'),
            name: 'parallel_stash_keys',
            value: data.parallel_stash_keys,
            default_value:'variable_name_here'
        })
    ]
})



