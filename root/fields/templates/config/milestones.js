(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);

    var default_value = "Milestone[slotname],textfield,250;Start Date[start_date],datefield,80;Planned Start Date[plan_start_date],datefield,80;End Date[end_date],datefield,80;Planned End Date[plan_end_date],datefield,80";

    ret.push([
        { xtype:'textarea',fieldLabel: _('Columns'), name: 'columns', allowBlank: false, value: data.columns || default_value },
        { xtype:'numberfield',fieldLabel: _('Height'), name: 'height', fieldClass: "x-fieldlet-type-height", minValue:'1', value: data.height || "300"}
    ]);
    return ret;
})
