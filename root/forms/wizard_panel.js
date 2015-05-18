(function(params){
    return [
        { xtype:'textfield', name:'title', value: params.data.title, fieldLabel: _('Title') },
        { xtype:'textfield', name:'path', value: params.data.path, fieldLabel: _('Path') },
        { xtype:'textarea', name:'note', height:120, value: params.data.note, fieldLabel: _('Description') }
    ]
});
