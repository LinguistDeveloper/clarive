(function(params) {
    Cla.help_push({
        title: _('Create a new topic'),
        path: 'rules/palette/job/create-topic'
    });
    var data = params.data || {};

    return [{
            xtype: 'textfield',
            name: "title",
            fieldLabel: _("Title"),
            allowBlank: false,
            value: data.title
        },
        new Baseliner.CategoryBox({
            name: 'category',
            fieldLabel: _('Category'),
            allowBlank: false,
            singleMode: true,
            value: data.category
        }),
        new Baseliner.StatusBox({
            name: 'status',
            fieldLabel: _('Status'),
            allowBlank: false,
            value: data.status,
            singleMode: true
        }),
        new Baseliner.UserBox({
            value: data.username,
            withVars: true
        }),
        new Baseliner.DataEditor({
            name: 'variables',
            title: _('Topic data. Type id_field in Key and string or variable (${variable}) in Value'),
            hide_save: true,
            hide_cancel: true,
            height: 560,
            data: data.variables || {},
            hide_type: true
        })
    ];
})
