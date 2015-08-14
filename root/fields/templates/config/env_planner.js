(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);

    ret.push([ 
    	{ xtype:'numberfield',fieldLabel: _('HTML field order'), name: 'field_order_html', value: data.field_order_html },
    	{ xtype:'textfield',fieldLabel: _('Width'), name: 'width', value: data.width },
    	{ xtype:'textfield',fieldLabel: _('Height'), name: 'height', value: data.height }
    ]);

    // TODO add a selection of available BLs ??
    return ret;
})

