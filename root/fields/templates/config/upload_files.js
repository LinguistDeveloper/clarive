(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([ 
    	{ xtype:'hidden', name:'fieldletType', value: 'fieldlet.attach_file' },
    	{ xtype:'textfield', name:'checkout_dir', fieldLabel:_('Checkout directory'), value: data.checkout_dir },
    	{ xtype:'textfield', name:'height', fieldLabel:_('Height'), value: data.height },
    	{ xtype:'textfield', name:'field_order_html', fieldLabel:_('File Order HTML'), value: data.field_order_html },
    	{ xtype:'textfield', name:'extension', fieldLabel:_('Extension'), value: data.extension },
    ]);
    return ret;
})
