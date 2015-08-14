(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    var value_type = Baseliner.generic_list_fields(data);
    ret.push(value_type);

    ret.push([ 
    	{ xtype:'textfield', name:'release_field', fieldLabel: _('Release field'), value: data.release_field }
    ]);
    return ret;
})
