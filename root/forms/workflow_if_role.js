(function(params) {
    var data = params.data || {};

    var rolesBox = new Cla.RoleBox({
        fieldLabel: _('Roles'),
        name: 'roles',
        allowBlank: true,
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
