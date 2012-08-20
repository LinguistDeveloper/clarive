    //var row = params.row || {};
    // paths data
    var store_from = new Ext.data.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        url: '/filedist/from_paths',
        fields: [ 
            {  name: 'path' }
        ]
    });
    var combo_from = new Ext.form.ComboBox({
        disabled: true,
        name: 'from', 
        hiddenName: 'from',
        valueField: 'path',
        displayField:'path', 
        fieldLabel: _('From Path'), 
        mode: 'remote', 
        store: store_from, 
        value: params.from,
        typeAhead: false,
        minChars: 1,
        editable: true,
        forceSelection: true,
        triggerAction: 'all',
        allowBlank: false,
        width: 300
    });
