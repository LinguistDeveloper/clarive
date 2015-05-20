(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    var value_type = Baseliner.generic_list_fields(data);
    ret.push(value_type);

    ret.push([ 
    	{ xtype:'hidden', name:'fieldletType', value: 'fieldlet.system.list_topics' },
    	{ xtype:'numberfield', name:'page_size', fieldLabel: _('Page size'), value: data.page_size },
    	{ xtype:'textfield', name:'parent_field', fieldLabel: _('Parent field'), value: data.parent_field }
    ]);
    return ret;
})
