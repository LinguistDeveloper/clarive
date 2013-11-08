(function(params){
    var data = params.data || {};
    return [
        new Baseliner.UserAndRoleBox({ fieldLabel: _('Approvers'), name:'approvers', allowBlank: false, value: data.approvers })
    ]
})
