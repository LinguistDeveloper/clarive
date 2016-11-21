(function(params) {
    Cla.help_push({
        title: _('IF Role IS'),
        path: 'rules/palette/workflow/if-role'
    });

    var data = params.data || {};

    var rolesBox = new Cla.RoleBox({
        fieldLabel: _('Roles'),
        name: 'roles',
        allowBlank: false,
        value: data.roles
    });

    return [{
        xtype: 'fieldset',
        title: _('IF INPUT MATCH...'),
        items: [
            rolesBox
        ]
    }]
})
