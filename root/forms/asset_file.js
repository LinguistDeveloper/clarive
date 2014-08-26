(function(params){
    var data = params.data || {};
    return [
        { xtype:'textfield', fieldLabel: _('File Path'), name: 'path', value: data.path },
        { xtype:'textfield', fieldLabel: _('Topic mid'), name: 'mid', value: data.mid },
	{ xtype:'textfield', fieldLabel: _('User'), name: 'username', value: data.username },
	{ xtype:'textfield', fieldLabel: _('Field Name'), name: 'field', value: data.field },
    ]
})

