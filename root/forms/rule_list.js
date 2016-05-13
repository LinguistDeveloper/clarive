(function(params) {
    var data = params.data || {};
    return [
        new Cla.RuleBox({
            name: 'id_rule',
            value: data.id_rule,
            fieldLabel: _('Rule To Be Invoked'),
            baseParams: {
                rule_type: ['independent']
            }
        })
    ]
})
