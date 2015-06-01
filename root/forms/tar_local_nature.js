(function(params){
    var data = params.data || {};
    return [
        { xtype:'textarea', fieldLabel: _('Local Dir'), height: 80, name: 'source_dir', value: params.data.source_dir || '${job_dir}/${project}' },
        { xtype:'textarea', fieldLabel: _('Tar File Path'), height: 80, name: 'tarfile', value: params.data.tarfile || '${job_dir}/${job_name}_${project}.tar' },
        new Baseliner.ComboDouble({ 
            fieldLabel: _('Clean Path Mode'), name:'clean_path_mode', value: data.clean_path_mode || 'force', 
            data: [ 
              ['none',_('No Path Cleaning')], 
              ['force',_('Force Relative')]
            ]
        })
    ]
})

