(function(params) {
    Cla.help_push({
        title: _('Release Combo'),
        path: 'rules/palette/fieldlets/release-combo'
    })
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    var ccategory = new Baseliner.CategoryBox({
        name: 'categories',
        fieldLabel: _('Select topics in categories'),
        value: data.categories || '',
        baseParams: {
            is_release: 1
        }
    });
    var cstatus = new Baseliner.StatusBox({
        name: 'statuses',
        fieldLabel: _('Select topics in statuses'),
        value: data.statuses || ''
    });

    var value_type = Baseliner.generic_list_fields(data, {
        list_type: 'single'
    });

    var logicField = Baseliner.LogicField(params, data);

    ret.push([
        ccategory,
        cstatus, {
            xtype: "checkbox",
            name: "not_in_status",
            checked: data.not_in_status == 'on' ? true : false,
            boxLabel: _('Exclude selected statuses?')
        },
        value_type
    ]);
    ret.push([{
            xtype: 'textfield',
            name: 'release_field',
            fieldLabel: _('Release field'),
            value: data.release_field
        },
        logicField
    ]);
    return ret;
})