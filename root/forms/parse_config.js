(function(params){
    var data = params.data || {};
    
    var file_type = new Baseliner.ComboDouble({ 
        fieldLabel: _('Type'), name:'type', value: data.type || 'yaml', 
        data: [ 
          ['yaml',_('YAML')], 
          ['general',_('General')], 
          ['json',_('JSON')], 
          ['ini',_('Ini')],
          ['props',_('Properties')],
          ['xml',_('XML')]
        ]
    });
    var opts = new Baseliner.DataEditor({ 
           name:'opts', title: _('Options'), 
           hide_save: true, hide_cancel: true,
           data: data.opts || {} 
    });
    
    return [ 
        
        new Baseliner.MonoTextArea({ fieldLabel: _('File Path'), height: 80, name: 'config_file', value: params.data.config_file }),
        { xtype:'textfield', fieldLabel: _('File Encoding'), name: 'encoding', value: params.data.encoding||'utf8' },
        file_type, 
       { xtype: 'tabpanel', activeTab: 0, height: 300, fieldLabel: _('Arguments'), items: [ opts ] }
    ];
})

