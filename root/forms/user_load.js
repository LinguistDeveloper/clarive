(function(params) {

    Cla.help_push({
        title: _('Load User'),
        path: 'rules/palette/services/load-user'
    });

    var data = params.data || {};
    var midOnlyCheckbox = new Baseliner.CBox({
        fieldLabel: _('Mid only?'),
        name: 'mid_only',
        checked: data.mid_only,
        default_value: false
    });

    return [
        new Baseliner.UserBox({
            value: data.username,
            withExtraValues: true
        }),
        midOnlyCheckbox
    ];
})