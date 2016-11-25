(function(params) {
    var data = params.data || {};

    var ret = Baseliner.generic_fields(data);
    var value_type = Baseliner.generic_list_fields(data);
    Cla.help_push({
        title: _('CI Combo'),
        path: 'rules/palette/fieldlets/ci-combo'
    });
    ret.push(value_type);
    var ci_role_field = new Ext.form.Field({
        name: 'ci_role',
        xtype: "textfield",
        value: data.ci_role || ''
    });
    ci_role_field.hide();

    var ci_class_field = new Ext.form.Field({
        name: 'ci_class',
        xtype: "textfield",
        value: data.ci_class || ''
    });
    ci_class_field.hide();

    var default_store = new Baseliner.store.CI();
    default_store.baseParams.class = ci_class_field.value || {};

    var default_box = new Baseliner.DefaultBox({
        name: 'default_value',
        value: data.default_value,
        store: default_store
    });

    var logicField = Baseliner.LogicField(params, data);

    var firstRoleChange = false;
    var role_box_multiselect = new Baseliner.CIRoleCombo({
        value: data.var_ci_role || 'Baseliner::Role::CI',
        name: 'var_ci_role',
        deal_combo_change: function(obj) {
            ci_role_field.setValue('');
            if (firstRoleChange) {
                ci_class_box.clearValue();
                default_box.clearValue();
            }
            if (data.var_ci_role.length === obj.usedRecords.items.length) firstRoleChange = true;
            var selected = [];
            for (var i = 0; i < obj.usedRecords.items.length; i++) {
                var temp = obj.usedRecords.items[i].data.role;
                selected.push(temp);
            }
            ci_role_field.setValue(selected);

            ci_class_box.store.baseParams = Ext.apply({
                start: 0,
                limit: Cla.constants.PAGE_SIZE,
                role: ci_role_field.value
            });
            ci_class_box.lastQuery = null;
        },
        listeners: {
            focus: function(combo, record, index) {
                handle_box = true;
            }
        }
    });
    var firstClassChange = false;
    var ci_class_box = new Baseliner.CIClassCombo({
        value: data.ci_class_box,
        singleMode: true,
        name: 'ci_class_box',
        displayField: 'name',
        valueField: 'name',
        pageSize: Cla.constants.PAGE_SIZE,
        deal_combo_change: function(obj) {
            ci_class_field.setValue('');
            var className = obj.usedRecords.items[0] ? obj.usedRecords.items[0].data.classname : '';
            ci_class_field.setValue(className);

            if (className) {
                default_box.enable();
                if (firstClassChange) Cla.enableDefaultBox(default_box);
                default_store.baseParams.class = ci_class_field.value;
                default_box.lastQuery = null;
                ci_role_field.setValue('');
                firstClassChange = true;

            } else {
                Cla.disableDefaultBox(default_box);
            }
        },
        listeners: {
            'removeitem': function(obj) {
                return this.deal_combo_change(obj);
            },
            'additem': function(obj) {
                return this.deal_combo_change(obj);
            }
        }
    });

    if (!ci_role_field.value && !ci_class_field.value || ci_role_field.value && !ci_class_field.value) {
        role_box_multiselect.allowBlank = false;
        ci_class_box.disable();
        Cla.disableDefaultBox(default_box);
    } else if (ci_class_field.value) {

        role_box_multiselect.allowBlank = false;
        ci_class_box.allowBlank = false;
        ci_class_box.enable();
    }

    var store_display_mode = new Ext.data.SimpleStore({
        fields: ['display_mode', 'name'],
        data: [
            ['collection', _('Name')],
            ['bl', _('Baseline')],
            ['class', _('Class')],
            ['moniker', _('Moniker')]
        ]
    });

    var display_mode = new Ext.form.ComboBox({
        store: store_display_mode,
        displayField: 'name',
        value: data.display_mode || 'collection',
        valueField: 'display_mode',
        hiddenName: 'display_mode',
        name: 'display_mode',
        editable: false,
        mode: 'local',
        allowBlank: false,
        forceSelection: true,
        triggerAction: 'all',
        fieldLabel: _('Description'),
        autoLoad: true
    });

    ret.push([
        {
            xtype: 'container',
            layout: 'hbox',
            fieldLabel: _('Selection method'),
            items: [{
                xtype: 'radiogroup',
                items: [{
                    boxLabel: _('Role selection'),
                    name: 'rdoMethod',
                    inputValue: 'roleSelection',
                    width: 20,
                    checked: !ci_role_field.value && !ci_class_field.value || ci_role_field.value && !ci_class_field.value
                }, {
                    boxLabel: 'Class selection',
                    name: 'rdoMethod',
                    width: 20,
                    inputValue: 'classSelection',
                    checked: ci_class_field.value
                }],
                listeners: {
                    'change': function(rg, checked) {
                        ci_class_box.clearValue();
                        default_box.clearValue();

                        if (checked.inputValue == 'roleSelection') {
                            ci_class_box.allowBlank = false;
                            role_box_multiselect.allowBlank = false;
                            ci_class_box.clearInvalid();
                            default_box.disable();
                            ci_class_box.disable();

                        } else {
                            ci_class_box.allowBlank = false;
                            role_box_multiselect.allowBlank = false;
                            ci_class_box.enable();

                        }
                    }
                }
            }]
        },
        role_box_multiselect,
        ci_class_box,
        ci_role_field,
        ci_class_field,
        default_box,
        logicField,
        display_mode, {
            xtype: 'numberfield',
            name: 'height',
            fieldLabel: _('Height'),
            value: data.height
        }
    ]);

    return ret;
})
