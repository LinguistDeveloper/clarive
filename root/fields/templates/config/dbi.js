(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([ 
    	{ xtype:'textfield', name: 'dbi_connection', fieldLabel:_('DBI connection'), allowBlank: false, anchor:'100%', value: data.dbi_connection },
    	{ xtype:'textfield', name: 'display_field', fieldLabel:_('Display field'), anchor:'100%', allowBlank: false, value: data.display_field },
    	{ xtype:'textfield', name: 'name_field', fieldLabel:_('Name field'), anchor:'100%', allowBlank: false, value: data.name_field },
    	{ xtype:'textfield', name: 'value_field', fieldLabel:_('Value field'), anchor:'100%', allowBlank: false, value: data.value_field }
    ]);
    return ret;
})

