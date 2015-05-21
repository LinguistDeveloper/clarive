(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);

    var default_value = "End Date[end_date],datefield"

    ret.push([ 
    	{ xtype:'hidden', name:'fieldletType', value: 'fieldlet.scheduler' },
    	{ xtype:'textarea',fieldLabel: _('Columns'), name: 'columns', allowBlank: false, value: data.columns || default_value },
    	{ xtype:'numberfield',fieldLabel: _('HTML field order'), name: 'field_order_html', value: data.field_order_html },
    	{ xtype:'textfield',fieldLabel: _('Width'), name: 'width', value: data.width },
    	{ xtype:'textfield',fieldLabel: _('Height'), name: 'height', value: data.height }
    ]);
    return ret;
})