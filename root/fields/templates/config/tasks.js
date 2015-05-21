(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    var value_type = Baseliner.generic_list_fields(data);
    ret.push(value_type);

    ret.push([ 
    	{ xtype:'hidden', name:'fieldletType', value: 'fieldlet.system.tasks' }
    ]);
    return ret;
})