(function(params) {
    var data = params.data || {};
    Cla.help_push({
        title: _('If last trap action'),
        path: 'rules/palette/control/if-last-trap-action'
    });

    return new Baseliner.ComboDouble({
        fieldLabel: _('Job Last Trap Action'),
        name: 'job_trap_action',
        value: data.job_trap_action || 'skip',
        data: [
            ['skip', _('Skip')],
            ['retry', _('Retry')],
        ]
    });
})