(function(params){
    var data = params.data || {};

    var force = new Baseliner.CBox({
        fieldLabel: _('Move to new sha if branch exists?'), 
        name: 'force',
        checked: data.force, 
        default_value: false
    });

    return [
        Baseliner.ci_box({ name: 'repo', role:'Baseliner::Role::CI::Repository', fieldLabel:_('Repository'), with_vars: 1, value: data.repo, force_set_value: true }),
        // { xtype:'textfield', fieldLabel: _('Repository mid'), name: 'repo', value: data.repo },
        { xtype:'textfield', fieldLabel: _('Sha or Ref'), name: 'sha', value: data.sha },
        { xtype:'textfield', fieldLabel: _('Branch Name'), name: 'branch', value: data.branch },
        force
    ]
})



