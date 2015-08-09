(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    var value_type = Baseliner.generic_list_fields(data);
    ret.push(value_type);

    var combo_datatable = new Baseliner.ComboDouble({
        name: 'datatable',
        editable: false,
        fieldLabel: _('Table format?'),
        emptyText: _('Select one'),
        data:[ 
            [ 'always', _('Always') ],
            [ 'never', _('Never') ],
        ],
        value: data.datatable,
    });

    ret.push([ 
        { xtype:'textfield', fieldLabel: _('List of columns to show in grid'), name: 'columns', value: data.columns },
    	{ xtype:'numberfield', name:'page_size', fieldLabel: _('Page size'), value: data.page_size },
        { xtype:'textfield', name:'parent_field', fieldLabel: _('Parent field'), value: data.parent_field },
        { xtype:'textfield', name:'filter_field', fieldLabel: _('Filter field'), value: data.filter_field },
    	{ xtype:'textfield', name:'filter_data', fieldLabel: _('Filter data'), value: data.filter_data },
        combo_datatable
    ]);
    return ret;
})
