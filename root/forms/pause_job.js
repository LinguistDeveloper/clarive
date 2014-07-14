(function(params){
    var data = params.data || {};
    var no_fail = new Baseliner.CBox({ name: 'no_fail', checked: params.data.no_fail, fieldLabel: _("Don't Fail On Timeout") });
    return [
        new Baseliner.MonoTextArea({ fieldLabel: _('Reason'), height: 60, name: 'reason', value: params.data.reason }),
        no_fail,
        new Baseliner.MonoTextArea({ fieldLabel: _('Details'), height: 400, name: 'details', value: params.data.details })
    ]
})



