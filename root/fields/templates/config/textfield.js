(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([ 
    	{ xtype:'hidden', name:'fieldletType', value: 'fieldlet.text' },
    	{ xtype:'textfield',fieldLabel: _('Default value'), name: 'default_value', value: data.default_value }
    ]);
    return ret;
})

