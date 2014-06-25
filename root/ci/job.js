(function(params){
    if( !params.rec ) params.rec = {};

    var changesets = new Baseliner.CIGrid({ 
        fieldLabel:_('Changesets'), ci: { 'role': 'Topic' },
        anchor:'100%',
        value: params.rec.changesets, name: 'changesets' });
    
    return [
        { xtype:'cbox', name: 'rollback', fieldLabel:_('Rollback?'), checked: params.rec.rollback == '1' ? true : false },
        { xtype:'textfield', name: 'job_key', fieldLabel:_('Job Key'), anchor:'100%', value: params.rec.job_key },
        { xtype:'textfield', name: 'id_job', fieldLabel:_('Job ID'), anchor:'100%', value: params.rec.id_job },
        changesets
    ]
})

