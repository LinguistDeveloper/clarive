(function(params){
    var data = params.data || {};
    var realm = new Baseliner.ComboDouble({ 
        fieldLabel: _('Realm'), name:'realm', value: data.realm,
        data: [ 
          //['global',_('Global')],
          ['project',_('Project')],
          ['subproject',_('Subproject')],
          ['both',_('Both')]
        ]
    });
    var prj = Baseliner.ci_box({ name: 'project', hidden: true, role:'Project', fieldLabel:_('Projects'), value: data.project, singleMode: false, force_set_value: true });
    if( data.realm != 'global' )  prj.show();
    realm.on('select', function(){ 
        if( realm.get_save_data() != 'global' )  prj.show(); else prj.hide();
    });
        
    var collapse = new Baseliner.ComboDouble({ 
        fieldLabel: _('Collapse'), name:'collapse', value: data.collapse,
        data: [ 
          ['expanded',_('Expanded')],
          ['collapsed',_('Collapsed')]
        ]
    });
    return [
        realm,
        prj,
        new Baseliner.model.SelectBaseline({ value: data.bl, name:'bl', hiddenField:'bl' }),
        new Baseliner.UserAndRoleBox({ fieldLabel: _('Permissions'), name:'permissions', allowBlank: true, value: data.permissions }),
        collapse,
        { xtype:'textfield', fieldLabel: _('Icon'), name: 'icon', value: data.icon }
    ]
})

