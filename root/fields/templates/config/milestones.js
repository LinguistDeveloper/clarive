(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);

    var default_value = "Start Date[start_date],datefield,80;Planned Start Date[plan_start_date],datefield,80;Real Start Date[real_start_date],datefield,80;End Date[end_date],datefield,80";

    ret.push([ 
    	{ xtype:'textarea',fieldLabel: _('Columns'), name: 'columns', allowBlank: false, value: data.columns || default_value }
    ]);
    return ret;
})
