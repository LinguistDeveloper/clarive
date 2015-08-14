(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([ 
    	{ xtype:'checkbox', name:'default_value', fieldLabel:_('Checked'), value: data.default_value, checked: Baseliner.eval_boolean( data.default_value,false) } 
    ]);
    return ret;
})
