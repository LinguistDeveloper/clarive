(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([ 
		{ xtype:'textfield',fieldLabel: _('Time format'), name: 'format', value: data.format || 'H:i'}
    ]);
    return ret;
})