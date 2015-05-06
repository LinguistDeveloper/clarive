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
        { xtype:'numberfield', fieldLabel: _('Minimum % to group series in Others group'), name: 'group_threshold', value: data.group_threshold || 5}
    ]);
})
