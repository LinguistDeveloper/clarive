(function(params){
    var data = params.data || {};
    var local_path = new Baseliner.MonoTextArea({ fieldLabel: _('Local Path'), height: 80, name: 'local_path', 
        value: data.local_path!=undefined ? data.local_path : '${job_dir}/${project}',
        hidden: !( data.local_mode && data.local_mode=='local_files' )
    });
    var anchor_path = new Baseliner.MonoTextArea({ fieldLabel: _('Anchor Path'), height: 40, name: 'anchor_path', 
        value: data.anchor_path!=undefined ? data.anchor_path : '${job_dir}/${project}',
        hidden: !( data.rel_path && data.rel_path=='rel_path_anchor' )
    });
    var local_mode = new Baseliner.ComboDouble({ 
        fieldLabel: _('Local Mode'), name:'local_mode', value: data.local_mode || 'local_files', 
        data: [ ['local_files',_('Local Files')], ['nature_items',_('Nature Items')] ]
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
    return [
        Baseliner.ci_box({ name: 'server', role:'Baseliner::Role::HasAgent', fieldLabel:_('Server'), with_vars: 1, value: data.server, force_set_value: true }),
        { xtype:'textfield', fieldLabel: _('User'), name: 'user', value: data.user },
        local_mode,
        local_path,
        rel_path,
        anchor_path,
        { xtype:'textarea', fieldLabel: _('Remote Path'), height: 80, name: 'remote_path', value: data.remote_path },
        { xtype:'textfield', fieldLabel: _('Chown'), name: 'chown', value: data.chown },
        { xtype:'textfield', fieldLabel: _('Chmod'), name: 'chmod', value: data.chmod }
    ]
})



