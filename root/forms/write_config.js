(function(params){
    var data = params.data || {};
    
    var input_type = new Baseliner.ComboDouble({ 
        fieldLabel: _('Input Type'), name:'input_type', value: data.input_type || 'var', 
        data: [ 
          ['var',_('From Stash Variable')], 
          ['data',_('From Data Editor')]
        ]
    });
    input_type.on('select', function(){
        if( input_type.getValue()=='var' ) {
            varname.show();
            tabpanel.hideTabStripItem( config_data );
        } else {
            varname.hide();
            tabpanel.unhideTabStripItem( config_data );
        }
    });
    var varname = new Ext.form.TextField({ 
        hidden: (params.data.input_type=='data' ? true : false), 
        fieldLabel: _('Input Stash Variable'), 
        name: 'varname', value: params.data.varname||'config_data' 
    });
    var file_type = new Baseliner.ComboDouble({ 
        fieldLabel: _('Type'), name:'type', value: data.type || 'yaml', 
        data: [ 
          ['yaml',_('YAML')], 
          ['general',_('General')], 
          ['json',_('JSON')], 
          ['ini',_('Ini')], 
          ['xml',_('XML')]
        ]
    });
    var opts = new Baseliner.DataEditor({ 
           name:'opts', title: _('Options'), 
           hide_save: true, hide_cancel: true,
           data: data.opts || {} 
    });
    var config_data = new Baseliner.DataEditor({ 
           name:'config_data', title: _('Config Data'), 
           hide_save: true, hide_cancel: true,
           data: data.config_data || {} 
    });
    var tabpanel = new Ext.TabPanel({ activeTab: 0, height: 300, fieldLabel: _('Arguments'), items: [ config_data, opts ] });
    tabpanel.on('afterrender', function(){
        if( params.data.input_type=='data' ) tabpanel.unhideTabStripItem( config_data );
        else tabpanel.hideTabStripItem( config_data );
    });
    
    return [ 
        input_type, 
        varname,
        new Baseliner.MonoTextArea({ fieldLabel: _('File Path'), height: 80, name: 'config_file', value: params.data.config_file }),
        { xtype:'textfield', fieldLabel: _('File Encoding'), name: 'encoding', value: params.data.encoding||'utf8' },
        file_type, 
        tabpanel
    ];
})


