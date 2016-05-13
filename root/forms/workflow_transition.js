(function(params) {
    var data = params.data || {};

    var statusesToBox = new Baseliner.StatusBox({
        name: 'statuses_to',
        fieldLabel: _('To Status'),
        value: data.statuses_to || ''
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
        title: _('SET TOPIC STATUS TO...'),
        items: [
            statusesToBox,
            jobTypeCombo
        ]
    }]
})
