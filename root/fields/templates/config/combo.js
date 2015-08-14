(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([ 
    	{ xtype:'textfield',fieldLabel: _('Options'), name: 'options', value: data.options }
    ]);
    return ret;
})
