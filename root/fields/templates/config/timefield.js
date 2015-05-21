(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([ 
    	{ xtype:'hidden', name:'fieldletType', value: 'fieldlet.datetime' },
    	{ xtype:'textfield',fieldLabel: _('Time format'), name: 'format', value: data.format }
    ]);
    return ret;
})
