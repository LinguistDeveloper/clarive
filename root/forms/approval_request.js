(function(params){
    var data = params.data || {};
	return [
        new Baseliner.ComboUsers({ fieldlabel: _('Approver'), value: data.users })
    ]
})
