(function(params) {
    var data = params.data || {};

    var rolesBox = new Cla.RoleBox({
        fieldLabel: _('Roles'),
        name: 'roles',
        allowBlank: true,
        value: data.roles
    });

    var statusesFromBox = new Baseliner.StatusBox({
        name: 'statuses_from',
        fieldLabel: _('From Status'),
        value: data.statuses_from || ''
    });
    var statusesToBox = new Baseliner.StatusBox({
        name: 'statuses_to',
        fieldLabel: _('To Status'),
        value: data.statuses_to || ''
    });

    var categoriesBox = new Baseliner.CategoryBox({
        name: 'categories',
        fieldLabel: _('Select Topic Categories'),
        value: data.categories || ''
    });

    var jobTypeCombo = new Baseliner.ComboDouble({
        fieldLabel: _('Deployment Type'),
        name: 'job_type',
        value: data.job_type || '',
        data: [
            ['', _('No Job')],
            ['promote', _('Promote')],
            ['demote', _('Demote')],
            ['static', _('Static')]
        ]
    });

    return [{
        xtype: 'fieldset',
        title: _('IF INPUT MATCH THESE...'),
        items: [
            categoriesBox,
            rolesBox,
            statusesFromBox
        ]
    }, {
        xtype: 'fieldset',
        title: _('THEN SET TOPIC STATUS TO...'),
        items: [
            statusesToBox,
            jobTypeCombo
        ]
    }]
})
