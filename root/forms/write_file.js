(function(params){
    var data = params.data || {};
    
    var body;
    if( Ext.isIE ) {
        body = new Ext.form.TextArea({ fieldLabel:_('Contents'), anchor:'100%', height: 350, name:'body', value: data.body  });
    } else {
        body = new Baseliner.AceEditor({
            fieldLabel:_('Contents'), anchor:'100%', height: 350, name:'body', value: data.body
        });
    }
    var log_body = new Baseliner.ComboDouble({ 
        fieldLabel: _('Log Body'), name:'log_body', value: data.log_body || 'no', 
        data: [ 
          ['no',_("Don't print body to log")], 
          ['yes',_('Print body in log')]
        ]
    });

    return [
        new Baseliner.MonoTextArea({ fieldLabel: _('Path'), height: 50, name: 'filepath', value: data.filepath }),
        new Ext.form.TextField({ fieldLabel: _('File Encoding'), name: 'file_encoding', value: data.file_encoding==undefined ? 'utf-8' : data.file_encoding }),
        new Ext.form.TextField({ fieldLabel: _('Content Encoding'), name: 'body_encoding', value: data.body_encoding==undefined ? 'utf-8' : data.body_encoding }),
        log_body,
        body
    ]
})





