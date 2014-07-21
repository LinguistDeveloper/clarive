(function(params){
    var data = params.data || {};
    var job_type = new Baseliner.ComboDouble({ 
        fieldLabel: _('Job type'), name:'job_type', value: data.job_type || 'static', 
        data: [ ['static',_('Static')], ['promote',_('Promote')], ['demote',_('Demote')] ]
    });
    var combo_bl = Baseliner.combo_baseline({ value: data.bl });
    return [
        job_type,
        combo_bl,
        { xtype:'textfield', fieldLabel: _('Changesets'), name: 'changesets', value: data.changesets },
        { xtype:'textfield', fieldLabel: _('Username'), name: 'username', value: data.username },
        { xtype:'textarea', fieldLabel: _('Comments'), height: 80, name: 'comments', value: data.comments }
    ]
})



