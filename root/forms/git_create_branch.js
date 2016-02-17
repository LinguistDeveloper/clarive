(function(params){
    var data = params.data || {};

    var force = new Baseliner.CBox({
        fieldLabel: _('Move to new sha if branch exists?'), 
        name: 'force',
        checked: data.force, 
        default_value: false
    });

    return [
        { xtype:'textfield', fieldLabel: _('Repository mid'), name: 'repo', value: data.repo },
        { xtype:'textfield', fieldLabel: _('Sha or Ref'), name: 'sha', value: data.sha },
        { xtype:'textfield', fieldLabel: _('Branch Name'), name: 'branch', value: data.branch },
        force
    ]
})



