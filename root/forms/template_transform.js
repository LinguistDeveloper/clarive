(function(params){
    var data = params.data || {};
    
    var body;
    var engine = new Baseliner.ComboDouble({
        fieldLabel: _('Engine'), name:'engine', value: data.engine || 'mason', 
        data: [ 
          ['mason',_('Mason')],
          ['tt',_('Template Toolkit')]
        ]
    });
    
    var template_var = new Ext.form.TextField({ fieldLabel:_('Template Stash Var'), 
        name:'template_var', value: data.template_var });

    return [
        new Baseliner.MonoTextArea({ fieldLabel: _('Input File'), height: 50, name: 'input_file', value: data.input_file }),
        new Baseliner.MonoTextArea({ fieldLabel: _('Output File'), height: 50, name: 'output_file', value: data.output_file }),
        new Ext.form.TextField({ fieldLabel: _('Encoding'), name: 'encoding', value: data.encoding==undefined ? 'utf-8' : data.encoding }),
        //new Ext.form.TextField({ fieldLabel: _('File Encoding'), name: 'file_encoding', value: data.file_encoding==undefined ? 'utf-8' : data.file_encoding }),
        engine,
        template_var
    ]
})
