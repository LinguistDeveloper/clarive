(function(params){
    var f = params.form;
    return [
       { xtype:'textfield', fieldLabel: _('Directory'), name:'dir', allowBlank: true, anchor: '100%' },
       { xtype:'textfield', fieldLabel: _('Path'), name:'path', allowBlank: true, anchor: '100%' },
       { xtype:'textfield', fieldLabel: _('Directory?'), name:'is_dir', allowBlank: true, anchor: '100%'}
    ]
})

