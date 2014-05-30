(function(params){
    var data = params.data || {};
    return [
        { xtype:'textfield', fieldLabel: _('Topics'), name: 'topics', value: data.topics },
        { xtype:'textfield', fieldLabel: _('Old status'), name: 'old_status', value: data.old_status },
        { xtype:'textfield', fieldLabel: _('New status'), name: 'new_status', value: data.new_status }
        //{ xtype:'textfield', fieldLabel: _('User'), name: 'username', value: data.username }
    ]
})




