(function(params){
    var data = params.data || {};


    var cstatus = new Baseliner.StatusBox({ name: 'statuses', fieldLabel: _('Select topics in statuses'), value: data.statuses || ''});
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });

    var common = Cla.dashlet_common(params);

    var days_from = new Ext.ux.form.SpinnerField({ 
        value: data.days_from, 
        name: "days_from",
        fieldLabel: _("Shift in days from today to start timeline. 0 or blank means one day")
    });

    var days_until = new Ext.ux.form.SpinnerField({ 
        value: data.days_until, 
        name: "days_until",
        fieldLabel: _("Shift in days from today to end timeline. 0 or blank means today")
    });
    var green = new Ext.ux.form.SpinnerField({ 
        value: data.green, 
        name: "green",
        fieldLabel: _("Maximum value to show green"),
        anchor: "15%"
    });

    var yellow = new Ext.ux.form.SpinnerField({ 
        value: data.yellow, 
        name: "yellow",
        fieldLabel: _("Maximum value to show yellow"),
        anchor: "15%"
    });

    return common.concat([
        cstatus,
        { xtype : "checkbox", name : "not_in_status", checked: data.not_in_status=='on' ? true : false, boxLabel : _('Exclude selected statuses?') },
        ccategory,
        { xtype:'textfield', fieldLabel: _('Advanced JSON/MongoDB condition for filter'), name: 'condition', value: data.condition },
        new Baseliner.ComboDouble({ fieldLabel: _('The result will be shown in ...'), name:'units', value: data.units || 'day', data: [
            ['minute', _('Minutes')],
            ['hour', _('Hours')],
            ['day', _('Days')],
            ['month', _('Months')]
          ] 
        }),
        { xtype:'textfield', fieldLabel: _('Date field in topics to use as start'), name: 'date_field_start', value: data.date_field_start },
        { xtype:'textfield', fieldLabel: _('Date field in topics to use as end'), name: 'date_field_end', value: data.date_field_end },
        { xtype:'textfield', fieldLabel: _('Numeric field in topics to use as data (leave dates blank)'), name: 'numeric_field', value: data.numeric_field },
        days_from,
        days_until,
        green,
        yellow
    ]);
})
