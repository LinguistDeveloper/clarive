(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([ 
    	{ xtype:'textfield', name:'checkout_dir', fieldLabel:_('Checkout directory'), value: data.checkout_dir },
    	{ xtype:'textfield', name:'extension', fieldLabel:_('Extension'), value: data.extension },
        { xtype:'numberfield', name:'height', fieldLabel:_('Height'), value: data.height }
    ]);
    return ret;
})
