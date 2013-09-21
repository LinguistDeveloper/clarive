(function(params){
    var data = params.data || {};
    return [
        { xtype:'textfield', fieldLabel: _('Filename'), name: 'filename', value: params.data.filename },
        { xtype:'textfield', fieldLabel: _('File Path'), name: 'file', value: params.data.file },
        { xtype:'textarea', fieldLabel: _('Message'), height: 100, name: 'message', value: params.data.message }
    ]
})



