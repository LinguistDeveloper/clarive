(function(params){
    var data = params.data || {};
    return [
        { xtype:'textfield', fieldLabel: _('Title'), name: 'title', value: data.title },
        { xtype:'textfield', fieldLabel: _('Revision'), name: 'rev', value: data.rev },
        { xtype:'textfield', fieldLabel: _('Field'), name: 'field', value: data.field },
        { xtype:'textfield', fieldLabel: _('User'), name: 'username', value: data.username }
    ]
})




