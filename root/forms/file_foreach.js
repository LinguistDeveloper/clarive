(function(params){
    var data = params.data || {};
    var path_mode = new Baseliner.ComboDouble({ 
        fieldLabel: _('Path Mode'), name:'path_mode', value: data.path_mode || 'files_flat', 
        data: [ 
          ['files_flat',_('Files, non Recursive')], 
          ['files_recursive',_('Recursive Files')], 
          ['nature_items',_('Nature Items')]
        ]
    });
    var dir_mode = new Baseliner.ComboDouble({ 
        fieldLabel: _('Dir Mode'), name:'dir_mode', value: data.dir_mode || 'file_only', 
        data: [ 
          ['file_only',_('Files only')], 
          ['file_and_dir',_('Files and Directories')], 
          ['dir_only',_('Only Directories')]
        ]
    });
    return [
        { xtype:'textfield', fieldLabel: _('Variable'), name: 'varname', value: data.varname },
        new Baseliner.MonoTextArea({ fieldLabel: _('Path'), height: 80, name: 'path', value: params.data.path }),
        path_mode,
        dir_mode,
        { xtype:'tabpanel', fieldLabel: _('Filters'), height: 200, activeTab:0, items:[
            new Baseliner.ArrayGrid({ 
                title:_('Include Paths'), 
                name: 'include_path', 
                value: data.include_path,
                description:_('Include Path Regex'), 
                default_value:'.*' 
            }), 
            new Baseliner.ArrayGrid({ 
                title:_('Exclude Paths'), 
                name: 'exclude_path', 
                value: data.exclude_path,
                description:_('Exclude Path Regex'), 
                default_value:'.*' 
            })
        ]}
    ]
})



