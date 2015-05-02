(function(params){
    var common = Cla.dashlet_common(params);
    var data = params.data;
    return common.concat([
        {
            xtype: 'radiogroup',
            name: 'period',
            anchor:'75%',
            fieldLabel: _('Period'),
            defaults: {xtype: "radio",name: "period"},
            items: [
                {boxLabel: _('Day'), inputValue: '1D', checked: data.period  == '1D'},
                {boxLabel: _('Week'), inputValue: '7D', checked: data.period == '7D'},
                {boxLabel: _('Month'), inputValue: '1M', checked: data.period == undefined || data.period == '1M'},
                {boxLabel: _('Quarter'), inputValue: '3M', checked: data.period == '3M'},
                {boxLabel: _('Year'), inputValue: '1Y', checked: data.period == '1Y'}
            ]
        },
        {
            xtype: 'radiogroup',
            name: 'type',
            anchor:'50%',
            fieldLabel: _('Type'),
            defaults: {xtype: "radio",name: "type"},
            items: [
                {boxLabel: _('Donut'), inputValue: 'donut', checked: data.type == undefined || data.type  == 'donut'},
                {boxLabel: _('Pie'), inputValue: 'pie', checked: data.type == 'pie'}
            ]
        }
    ])
})




