(function(params){
    var data = params.data || {};
    
    var store_origin =new Ext.data.SimpleStore({
        fields: ['origin', 'name'],
        data:[ 
            [ 'custom', _('Custom') ],
            [ 'system', _('System') ]
        ]
    });
    

    var store_sections =new Ext.data.SimpleStore({
        fields: ['section', 'name'],
        data:[ 
            [ 'head', _('Head') ],
            [ 'body', _('Body') ],
            [ 'details', _('Details') ]
        ]
    });

    var combo_origin = new Ext.form.ComboBox({
        store: store_origin,
        displayField: 'name',
        value: data.origin,
        valueField: 'origin',
        hiddenName: 'origin',
        name: 'origin',
        editable: false,
        mode: 'local',
        forceSelection: true,
        triggerAction: 'all', 
        fieldLabel: _('Origin'),
        emptyText: _('select origin...'),
        autoLoad: true
    });

    var combo_section = new Ext.form.ComboBox({
        store: store_sections,
        displayField: 'name',
        value: data.section,
        valueField: 'section',
        hiddenName: 'section',
        name: 'section',
        editable: false,
        mode: 'local',
        forceSelection: true,
        triggerAction: 'all', 
        fieldLabel: _('Section'),
        emptyText: _('select section...'),
        autoLoad: true
    });

    return [
        { xtype:'textfield', fieldLabel: _('Label'), name: 'label', allowBlank: false, value: data.label },
        { xtype:'textfield', fieldLabel: _('Field ID'), name: 'field_id', allowBlank: false, value: data.field_id },
        { xtype:'numberfield', fieldLabel: _('Field order'), name: 'field_order', allowBlank: false, value: data.field_order },
        combo_origin,
        combo_section,
        //{ xtype:'checkbox', name:'checked', fieldLabel:_('Checked by default'), value: data.checked },
        { xtype:'checkbox', name:'hide_html', fieldLabel:_('Hide html'), value: data.hide_html, checked: data.hide_html ? true : false },
        { xtype:'checkbox', name:'hide_js', fieldLabel:_('Hide js'), value: data.hide_js, checked: data.hide_js ? true : false }
    ]
})