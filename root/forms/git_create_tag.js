(function(params){
    var data = params.data || {};

    return [
        { xtype:'textfield', fieldLabel: _('Repository mid'), name: 'repo', value: data.repo },
        { xtype:'textfield', fieldLabel: _('Sha'), name: 'sha', value: data.sha },
        { xtype:'textfield', fieldLabel: _('Tag Name'), name: 'tag', value: data.tag }
    ]
})



