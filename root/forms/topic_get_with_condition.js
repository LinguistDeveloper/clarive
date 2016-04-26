(function(params){
    var data = params.data || {};


    var cstatus = new Baseliner.StatusBox({ name: 'statuses', fieldLabel: _('Select topics in statuses'), value: data.statuses || ''});
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });


     var store_values = new Ext.data.SimpleStore({
        fields: ['assigned_to', 'name'],
        data:[ 
            [ 'any', _('Any') ],
            [ 'current', _('Current') ],
        ]
    });


    var value_combo = new Ext.form.ComboBox({
        store: store_values,
        displayField: 'name',
        value: data.assigned_to,
        valueField: 'assigned_to',
        hiddenName: 'assigned_to',
        name: 'assigned_to',
        editable: false,
        mode: 'local',
        forceSelection: true,
        triggerAction: 'all', 
        fieldLabel: _('User assigned to topics'),
        autoLoad: true,
        anchor: '100%',
    });


    return [
        ccategory,
        cstatus,
        { xtype : "checkbox", name : "not_in_status", checked: data.not_in_status=='on' ? true : false, boxLabel : _('Exclude selected statuses?') },
        // { xtype:'textfield', fieldLabel: _('User assigned to topics'), name: 'assigned_to', value: data.assigned_to },
        value_combo,
        { xtype:'textfield', anchor:'100%', fieldLabel: _('Advanced JSON/MongoDB condition for filter'), name: 'condition', value: data.condition }
    ];
})
