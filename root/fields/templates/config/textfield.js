(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([ 
    	{ xtype:'textfield',fieldLabel: _('Default value'), name: 'default_value', value: data.default_value },
        { xtype:'numberfield', anchor:'100%', fieldLabel: _('Max length'), name: 'maxLength', value: data.maxLength }
    ]);
    return ret;
})

