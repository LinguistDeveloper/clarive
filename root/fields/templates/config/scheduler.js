(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);

    var default_value = "End Date[end_date],datefield"

    ret.push([ 
    	{ xtype:'textarea',fieldLabel: _('Columns'), name: 'columns', allowBlank: false, value: data.columns || default_value }
    ]);
    return ret;
})
