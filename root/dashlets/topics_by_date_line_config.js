(function(params){
    var data = params.data || {};


    var cstatus = new Baseliner.StatusBox({ name: 'statuses', fieldLabel: _('Select topics in statuses'), value: data.statuses || ''});
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });

    var common = Cla.dashlet_common(params);

    return common.concat([
        cstatus,
        { xtype : "checkbox", name : "not_in_status", checked: data.not_in_status=='on' ? true : false, boxLabel : _('Exclude selected statuses?') },
        ccategory,
        { xtype:'textfield', fieldLabel: _('Advanced JSON/MongoDB condition for filter'), name: 'condition', value: data.condition },
        { xtype:'textfield', fieldLabel: _('Date field in topics to use as X axis'), name: 'date_field', value: data.date_field },
        new Baseliner.ComboDouble({ fieldLabel: _('Data grouped by'), name:'group', value: data.group, data: [
            ['day', _('Day')],
            ['week', _('Week')],
            ['month', _('Month')],
            ['quarter', _('Quarter')],
            ['year', _('Year')]
          ] 
        }),
        new Baseliner.ComboDouble({ fieldLabel: _('Chart will be shown as ...'), name:'type', value: data.type || 'area', data: [
            ['area', _('Area')],
            ['stack-area', _('Stacked area')],
            ['stack-area-step', _('Area step')],
            ['line', _('Line')],
            ['bar', _('Bar')], 
            ['stack-bar', _('Stacked bar')]
          ] 
        })
    ]);
})
