(function(params) {
    var data = params.data || {};

    var conditionContainerCounter = 0;
    var conditionContainer = new Ext.Container();

    var availableOptions = [{
        name: 'ignore_case',
        label: _('Ignore case'),
    },{
        name: 'numeric',
        label: _('Numeric'),
    }];

    var availableConditions = [{
        name: 'is_true',
        label: _('IS TRUE')
    }, {
        name: 'is_false',
        label: _('IS FALSE')
    }, {
        name: 'is_empty',
        label: _('IS EMPTY')
    }, {
        name: 'not_empty',
        label: _('NOT EMPTY')
    }, {
        name: 'eq',
        label: _('EQUALS') + ' =',
        operator_b: true,
        options: {
            ignore_case: true,
            numeric: true
        }
    }, {
        name: 'not_eq',
        label: _('NOT EQUALS') + ' !=',
        operator_b: true,
        options: {
            ignore_case: true,
            numeric: true
        }
    }, {
        name: 'gt',
        label: _('GREATER THAN') + ' >',
        operator_b: true
    }, {
        name: 'ge',
        label: _('GREATER THAN OR EQUALS TO') + ' >=',
        operator_b: true
    }, {
        name: 'lt',
        label: _('LESS THAN') + ' <',
        operator_b: true
    }, {
        name: 'le',
        label: _('LESS THAN OR EQUALS TO') + ' <=',
        operator_b: true
    }, {
        name: 'like',
        label: _('LIKE (regular expression)'),
        operator_b: true,
        options: {
            ignore_case: true
        }
    }, {
        name: 'not_like',
        label: _('NOT LIKE (regular expression)'),
        operator_b: true,
        options: {
            ignore_case: true
        }
    }, {
        name: 'in',
        label: _('IN'),
        operator_b: true,
        options: {
            ignore_case: true
        }
    }, {
        name: 'not_in',
        label: _('NOT IN'),
        operator_b: true,
        options: {
            ignore_case: true
        }
    }, {
        name: 'has',
        label: _('HAS'),
        operator_b: true,
        options: {
            ignore_case: true
        }
    }, {
        name: 'not_has',
        label: _('NOT HAS'),
        operator_b: true,
        options: {
            ignore_case: true
        }
    }];

    var availableConditionsWithOperatorB = {};
    var availableConditionsWithOptions = {};
    var availableConditionsComboData = [];
    for (var i = 0; i < availableConditions.length; i++) {
        availableConditionsComboData.push([availableConditions[i].name, availableConditions[i].label]);

        if (availableConditions[i].operator_b) {
            availableConditionsWithOperatorB[availableConditions[i].name] = true;
        }

        if (availableConditions[i].options) {
            availableConditionsWithOptions[availableConditions[i].name] = availableConditions[i].options;
        }
    }

    function buildOptionsGroup(availableOptions, enabledOptions, data, namePrefix) {
        var i;
        var items = [];
        var option;

        for (i = 0; i < availableOptions.length; i++) {
            option = availableOptions[i];

            if (enabledOptions[option.name]) {
                items.push({
                    boxLabel: option.label,
                    name: namePrefix + option.name,
                    checked: data[namePrefix + option.name] == 'on'
                });
            }
        }

        return new Ext.form.CheckboxGroup({
            fieldLabel: _('Options'),
            columns: 1,
            items: items
        });
    }

    function layoutOperatorOptions(fieldset, operator, data, namePrefix) {
        var conditionOptionsCheckboxGroup = fieldset.findByType('checkboxgroup');
        if (conditionOptionsCheckboxGroup.length) {
            fieldset.remove(conditionOptionsCheckboxGroup[0], true);
            fieldset.doLayout();
        }

        if (availableConditionsWithOptions[operator]) {
            conditionOptionsCheckboxGroup = buildOptionsGroup(availableOptions, availableConditionsWithOptions[operator], data, namePrefix);

            fieldset.insert(2, conditionOptionsCheckboxGroup);
            fieldset.doLayout();
        }
    }

    function addCondition(params, counter) {
        if (!params) params = {}

        var operandATextField = new Ext.form.TextField({
            name: 'operand_a[' + counter + ']',
            fieldLabel: _('Stash Variable'),
            allowBlank: false,
            value: params.operand_a
        });

        var operatorCombo = new Baseliner.ComboDouble({
            fieldLabel: _('Operator'),
            name: 'operator[' + counter + ']',
            value: params.operator || 'is_true',
            data: availableConditionsComboData,
            listeners: {
                select: function(combo) {
                    var val = combo.getValue();

                    if (availableConditionsWithOperatorB[val]) {
                        operandBTextField.show();
                    } else {
                        operandBTextField.hide();
                    }

                    layoutOperatorOptions(fieldset, combo.getValue(), data, 'options[' + counter + '].');
                }
            }
        });

        var operandBTextField = new Ext.form.TextField({
            name: 'operand_b[' + counter + ']',
            fieldLabel: _('Value'),
            value: params.operand_b,
            hidden: !availableConditionsWithOperatorB[operatorCombo.getValue()]
        });

        var removeConditionButton = new Ext.Button({
            text: _('Remove'),
            listeners: {
                click: function(button) {
                    conditionContainer.remove(this.findParentByType('fieldset'));
                    conditionContainer.doLayout();
                }
            }
        });

        var fieldset = new Ext.form.FieldSet({
            xtype: 'fieldset',
            title: _('Condition'),
            items: [
                operandATextField,
                operatorCombo,
                operandBTextField,
                removeConditionButton
            ]
        });

        layoutOperatorOptions(fieldset, params.operator, data, 'options[' + counter + '].');

        conditionContainer.add(fieldset);
        conditionContainer.doLayout();
    }

    var addConditionButton = new Ext.Button({
        text: _('Add condition'),
        listeners: {
            click: function() {
                addCondition({}, ++conditionContainerCounter);
            }
        }
    });

    var whenCombo = new Baseliner.ComboDouble({
        fieldLabel: _('When'),
        name: 'when',
        value: data.when,
        data: [
            ['any', _('Any')],
            ['all', _('All')],
            ['none', _('None')]
        ]
    });

    var conditions = [];
    var re = /operand_a\[(\d+)\]/g;
    for (key in data) {
        var i = 0;
        var match = re.exec(key);

        if (match && match[1]) {
            i = match[1];
            conditions[i] = {};
            conditions[i].operand_a = data[key];
            conditions[i].operator = data['operator[' + i + ']'];
            conditions[i].options = {
                ignore_case: !!data['options[' + i + '].ignore_case']
            };
            conditions[i].operand_b = data['operand_b[' + i + ']'];
        }
    }

    if (conditions.length) {
        for (var i = 0; i < conditions.length; i++) {
            if (conditions[i]) {
                addCondition(conditions[i], ++conditionContainerCounter);
            }
        }
    } else {
        addCondition({}, 0);
    }

    return [
        whenCombo,
        conditionContainer,
        addConditionButton
    ]
})
