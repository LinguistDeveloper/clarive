(function(params) {
    var data = params.data || {};

    Cla.help_push({ title: _('Create CI'), path: 'rules/palette/services/create-ci' });

    var classname = new Baseliner.CIClassCombo({
        name: 'classname',
        allowBlank: false,
        fieldLabel: _('CI Class'),
        value: data.classname,
        singleMode: true
    });

    return [
        classname,
        new Baseliner.DataEditor({
            name: 'attributes',
            title: _('CI data. Type id_field in Key and string or variable (${variable}) in Value'),
            hide_save: true,
            hide_cancel: true,
            height: 560,
            data: data.attributes || {},
            hide_type: true
        })
    ];
})
