(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);

    var default_value = "Milestone[slotname],textfield,200;End Date[end_date],datefield"

    ret.push([ 
    	{ xtype:'textarea',fieldLabel: _('Columns'), name: 'columns', allowBlank: false, value: data.columns || default_value },
        { xtype:'numberfield', name:'height', fieldLabel:_('Height'), value: data.height }
    ]);
    return ret;
})
