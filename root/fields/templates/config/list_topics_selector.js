(function(params) {
    var data = params.data || {};

    var value_type = Baseliner.generic_list_fields(data);
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });
    var cstatus = new Baseliner.StatusBox({ name: 'statuses', fieldLabel: _('Select topics in statuses'), value: data.statuses || ''});

    var comboDatatable = new Baseliner.ComboDouble({
        name: 'datatable',
        editable: false,
        fieldLabel: _('Table format?'),
        data:[
            [ 'always', _('Always') ],
            [ 'paging', _('Only if paging') ],
            [ 'never', _('Never') ],
        ],
        value: /paging|always|never/.test(data.datatable) ? data.datatable : 'paging'
    });

    var logicField = new Baseliner.LogicField(params, data);

    var comboPaging = new Baseliner.ComboSingle({
        name: 'paging_datatable',
        fieldLabel: _('Grid Page Size'),
        data:[10,20,25,50,100] ,
        value: data.paging_datatable || 10
    });

    var customColumnVariableBox = {
        header: _('Variable'),
        width: 220,
        dataIndex: 'variable',
        editor: Baseliner.ci_box({
            role: 'Variable',
            disabled: true,
            filter: Ext.util.JSON.encode({var_type: ['combo', 'array']})
        }),
        renderer: function(value, metadata, rec, rowIndex) {
            var selectedValue, storeValue;
            if (!value) {
                return;
            }

            // When the value is selected it is removed from the store,
            // that is why check the store after making sure nothing is selected
            if (this.editor.usedRecords.items.length) {
                selectedValue = this.editor.usedRecords.items[0].json;
            } else {
                storeValue = this.editor.getStore().query('mid', value);
                if (storeValue.items.length) {
                    selectedValue = storeValue.items[0].data;
                }
            }

            return selectedValue.name;
        }
    };

    var columnIdTextfield = {
        header: _('Id Column'),
        dataIndex: 'id_column',
        editor: new Ext.form.TextField({
            vtype: 'idField',
            allowBlank: false
        })
    };

    var columnDisplayTextfield = {
        header: _('Display Column'),
        dataIndex: 'display_column',
        editor: {
            xtype: 'textfield'
        }
    };

    var columnTypeCombo = {
        dataIndex: 'column_type',
        header: _('Column Type'),
        editor: new Baseliner.ComboDouble({
            default_value: 'text',
            forceSelection: true,
            editable: false,
            autoSelect: true,
            enableKeyEvents: true,
            data: [
                ['text', _('Text')],
                ['variable', _('Variable')]
            ],
            listeners: {
                select: function(combo) {
                    if (this.value == 'variable') {
                        columnVariableBox.editor.allowBlank = false;
                        columnVariableBox.editor.enable();
                    } else {
                        customColumnVariableBox.editor.allowBlank = true;
                        customColumnVariableBox.editor.setValue('');
                        customColumnVariableBox.editor.disable();
                    }
                },
		specialkey: function(combo, e) {
			return false;
		}
            }
        }),
        default_value: 'text',
        renderer: function(value) {
            var storeValue;
            if (!value) {
                return;
            }
            storeValue = this.editor.getStore().query('item', value);
            return storeValue.items[0].data.display_name;
        }
    };

    var customColumnsGrid = new Baseliner.GridEditor({
        fieldLabel: _('Custom Columns'),
        name: 'custom_columns',
        records: data.custom_columns || [],
        align: 'center',
        allowBlank: true,
        enableColumnMove: false,
        allowCSV: false,
        columns: [
            columnIdTextfield,
            columnDisplayTextfield,
            columnTypeCombo,
            columnVariableBox
        ],
        viewConfig: {
            forceFit: true,
        }
    });

    customColumnsGrid.editor.on('afteredit', function() {
        columnVariableBox.editor.allowBlank = true;
        columnVariableBox.editor.disable();
    });

    customColumnsGrid.editor.on('show', function() {
        if(customColumnTypeCombo.editor.getValue() == 'text'){
            customColumnVariableBox.editor.disable();
            customColumnVariableBox.editor.allowBlank = true;
        }else{
            customColumnVariableBox.editor.enable();
            customColumnVariableBox.editor.allowBlank = false;
        }
    });

    customColumnsGrid.editor.on('validateedit', function(editor, record, row, rowIndex) {
	var isValid = true;
        var values;
        if (record.id_column) {
            values = customColumnsGrid.getStore().data.items;
            Ext.each(values, function(value) {
                if (value.data.id_column == record.id_column) {
                    Ext.Msg.show({
                        title: _('Information'),
                        msg: _('Id column already exists'),
                        buttons: Ext.Msg.OK,
                        icon: Ext.Msg.INFO
                    });

                    customColumnVariableBox.editor.reset();
                    customColumnVariableBox.editor.disable();
                    isValid = false;
                }
            })
        }

	return isValid;
    });

    Cla.help_push({ title:_('Topic Selector'), path:'rules/palette/fieldlets/topic-selector' });

    return Baseliner.generic_fields(data).concat(
        ccategory,
        cstatus,
        { xtype : 'checkbox', name : 'not_in_status', checked: data.not_in_status=='on' ? true : false, boxLabel : _('Exclude selected statuses?') },
        value_type,
    [{
            xtype: 'textfield',
            fieldLabel: _('List of columns to show in grid'),
            name: 'columns',
            value: data.columns
        }, {
            xtype: 'numberfield',
            fieldLabel: _('Height of grid in edit mode'),
            name: 'height',
            fieldClass: 'x-fieldlet-type-height',
            minValue: '1',
            value: data.height || 250
        }, {
            xtype: 'numberfield',
            name: 'page_size',
            fieldLabel: _('Page size'),
            value: data.page_size || 20
        }, {
            xtype: 'textfield',
            name: 'parent_field',
            fieldLabel: _('Parent field'),
            value: data.parent_field
        },
        logicField,
        comboPaging,
        comboDatatable, {
            xtype: 'textfield',
            fieldLabel: _('Sort By'),
            name: 'sort',
            value: data.sort
        },
        new Baseliner.ComboDouble({
            forceSelection: true,
            allowBlank: false,
            fieldLabel: _('Sort Order'),
            editable: false,
            name: 'dir',
            value: data.dir || '',
            data: [
                ['DESC', _('DESC')],
                ['ASC', _('ASC')]
            ]
        }),
        customColumnsGrid
    ]);
})
