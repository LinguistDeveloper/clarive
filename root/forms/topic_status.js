(function(params){
    var data = params.data || {};
    var oldstatus = new Baseliner.StatusBox({ name: 'old_status', fieldLabel: _('Old statuses'), value: data.old_status || ''  });
    var newstatus = new Baseliner.StatusBox({ name: 'new_status', fieldLabel: _('New status'), singleMode:true, value: data.new_status || ''  });

    return [
        { xtype:'textfield', fieldLabel: _('Topics'), name: 'topics', value: data.topics },
        oldstatus,
        newstatus,
        { xtype:'textfield', fieldLabel: _('User'), name: 'username', value: data.username }
    ]
})




