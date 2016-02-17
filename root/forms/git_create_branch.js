(function(params){
    var data = params.data || {};

    return [
        { xtype:'textfield', fieldLabel: _('Repository mid'), name: 'repo', value: data.repo },
        { xtype:'textfield', fieldLabel: _('Sha or Ref'), name: 'sha', value: data.sha },
        { xtype:'textfield', fieldLabel: _('Branch Name'), name: 'branch', value: data.branch }
    ]
})



