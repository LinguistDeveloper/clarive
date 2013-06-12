(function(params){
    return [
        { xtype:'textfield', fieldLabel:_('Project Name (Environmentname)'), value: params.rec.project_name, name:'project_name',  anchor:'100%' },
        { xtype:'textfield', fieldLabel:_('Project Mask'), value: params.rec.project_mask, name:'project_mask',  anchor:'100%' },
        { xtype:'textfield', fieldLabel:_('Viewpath'), value: params.rec.viewpath, name:'viewpath',  anchor:'100%' },
        { xtype:'textfield', fieldLabel:_('Viewname'), value: params.rec.viewname, name:'viewname',  anchor:'100%' },
        { xtype:'textfield', fieldLabel:_('DB Connection'), value: params.rec.db_connection, name:'db_connection', readOnly: true, anchor:'100%' }
    ]
})
