(function(params){
    var data = params.data || {};
    var recursive = new Baseliner.CBox({ name: 'recursive', checked: params.data.recursive, fieldLabel: _("Recursive") });
    var local_path = new Baseliner.MonoTextArea({ fieldLabel: _('Local Path'), height: 80, name: 'local_path', 
        value: data.local_path!=undefined ? data.local_path : '${job_dir}/${project}',
        hidden: !( data.local_mode && data.local_mode=='local_files' )
    });
    var anchor_path = new Baseliner.MonoTextArea({ fieldLabel: _('Anchor Path'), height: 40, name: 'anchor_path', 
        value: data.anchor_path!=undefined ? data.anchor_path : '${job_dir}/${project}',
        hidden: !( data.rel_path && data.rel_path=='rel_path_anchor' )
    });
    var local_mode = new Baseliner.ComboDouble({ 
        fieldLabel: _('Local Mode'), name:'local_mode', value: data.local_mode || 'nature_items', 
        data: [ ['nature_items',_('Nature Items')], ['local_files',_('Local Files')] ]
    });
    local_mode.on('select', function(){
        var v = local_mode.getValue();
        if( v == 'local_files' ) {
            local_path.show();
        } else {
            local_path.hide();
        }
    });
    var rel_path = new Baseliner.ComboDouble({ 
        fieldLabel: _('Relative Path'), name:'rel_path', value: data.rel_path || 'file_only', 
        data: [ 
          ['file_only',_('File Only, no Path')], 
          ['rel_path_job',_('Keep Relative Path from job directory')],
          ['rel_path_anchor',_('Specify Anchor Path')] 
        ]
    });
    rel_path.on('select',function(){ 
        var v = rel_path.getValue();
        if( v == 'rel_path_anchor' ) {
            anchor_path.show();
        } else {
            anchor_path.hide();
        }
    });
    var backup_mode = new Baseliner.ComboDouble({ 
        fieldLabel: _('Backup Mode'), name:'backup_mode', value: data.backup_mode || 'backup', 
        data: [ 
          ['none',_('No Backup')], 
          ['backup',_('Backup Existing Files')],
          ['backup_fail',_('Backup Existing Files or Fail')]
        ]
    });
    var rollback_mode = new Baseliner.ComboDouble({ 
        fieldLabel: _('Rollback Mode'), name:'rollback_mode', value: data.rollback_mode || 'rollback', 
        data: [ 
          ['none',_('No Rollback')], 
          ['rollback',_('Rollback from local files if exist')],
          ['rollback_force',_('Must Rollback from local files')]
        ]
    });
    var exist_mode = new Baseliner.ComboDouble({ 
        fieldLabel: _('Exist Mode'), name:'exist_mode', value: data.exist_mode || 'skip', 
        data: [
          ['skip',_('Skip, if file already sent by any task in job chain')],  // add skip local (instead of global chain)
          ['reship',_('Reship, even file has already been shipped to node')]   // add copy from dir to dir remotely, and checksum mode 
        ]
    });
    return [
        Baseliner.ci_box({ name: 'server', role:'Baseliner::Role::HasAgent', fieldLabel:_('Server'), with_vars: 1, value: data.server, force_set_value: true }),
        { xtype:'textfield', fieldLabel: _('User'), name: 'user', value: data.user },
        recursive,
        local_mode,
        local_path,
        rel_path,
        anchor_path,
        { xtype:'textarea', fieldLabel: _('Remote Path'), height: 80, name: 'remote_path', value: data.remote_path },
        exist_mode,
        backup_mode,
        rollback_mode,
        { xtype:'textfield', fieldLabel: _('Chown'), name: 'chown', value: data.chown },
        { xtype:'textfield', fieldLabel: _('Chmod'), name: 'chmod', value: data.chmod },
        new Baseliner.CBox({ fieldLabel: _('Copy File Attributes'), name: 'copy_attrs', checked: data.copy_attrs, default_value: false }),
        { xtype:'tabpanel', fieldLabel: _('Filters'), height: 200, activeTab:0, items:[
            new Baseliner.ArrayGrid({ 
                title:_('Include Paths'), 
                name: 'include_path', 
                value: data.include_path,
                description:_('Include Path Regex'), 
                default_value:'.*' 
            }), 
            new Baseliner.ArrayGrid({ 
                title:_('Exclude Path'), 
                name: 'exclude_path', 
                value: data.exclude_path,
                description:_('Exclude Path Regex'), 
                default_value:'.*' 
            })
        ]}
    ]
})



