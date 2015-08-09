(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([ 
    	{ xtype:'numberfield',fieldLabel: _('HTML field order'), name: 'field_order_html', value: data.field_order_html },
    	{ xtype:'numberfield', name:'height', fieldLabel:_('Height'), value: data.height }
    ]);
    return ret;
})
