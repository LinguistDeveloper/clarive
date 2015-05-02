(function(params){
    var data = params.data || {};


    var cstatus = new Baseliner.StatusBox({ name: 'statuses', fieldLabel: _('Statuses'), value: data.statuses || ''});
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Categories'), value: data.categories || ''  });

    var common = Cla.dashlet_common(params);

    return common.concat([
        cstatus,
        { xtype : "checkbox", name : "not_in_status", checked: data.not_in_status=='on' ? true : false, boxLabel : _('Not in statuses') },
        ccategory,
        { xtype:'textfield', fieldLabel: _('Condition'), name: 'condition', value: data.condition },
        { xtype:'numberfield', fieldLabel: _('Others threshold'), name: 'group_threshold', value: data.group_threshold },
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
    ]);
})
