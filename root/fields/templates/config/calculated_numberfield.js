(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([ 
        { xtype:'hidden', name:'fieldletType', value: 'fieldlet.calculated_number' },
        { xtype:'textarea', name:'operation', fieldLabel:_('Operation'), allowBlank: false, value: data.operation},
		{ xtype:'textarea', name:'operation_fields', fieldLabel:_('Operation fields'), allowBlank: false, value: data.operation_fields} 
    ]);
    return ret;
})
