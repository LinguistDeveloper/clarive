(function(params){
    var data = params.data || {};


    var cstatus = new Baseliner.StatusBox({ name: 'statuses', fieldLabel: _('Select topics in statuses'), value: data.statuses || ''});
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });


    return [
        ccategory,
        cstatus,
        { xtype : "checkbox", name : "not_in_status", checked: data.not_in_status=='on' ? true : false, boxLabel : _('Exclude selected statuses?') },
        // { xtype:'textfield', fieldLabel: _('User assigned to topics'), name: 'assigned_to', value: data.assigned_to },
        new Baseliner.ComboSingle({ forceSelection: false, allowBlank: true, fieldLabel: _('User assigned to topics'), editable: true, name: 'assigned_to', value: data.assigned_to || '', data: [
            [''],
            [_('Current')],
            [_('Any')]
          ] 
        }),
        { xtype:'textfield', anchor:'100%', fieldLabel: _('Advanced JSON/MongoDB condition for filter'), name: 'condition', value: data.condition }
    ];
})
