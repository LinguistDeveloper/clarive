(function(params){
    if( !params ) params={ rec: {} };
    var data = params.rec;
    var ta = Baseliner.cols_templates['textarea'];
    var pw = Baseliner.cols_templates['password'];
    var cb = Baseliner.cols_templates['combo_dbl'];
    var tf = Baseliner.cols_templates['textfield'];
    var project = Baseliner.ci_box({ fieldLabel:_('Projects'), name:'projects', singleMode: false, role:'Project', value: data.projects, force_set_value: true }) 
    var dbms = new Baseliner.ComboDouble({ 
        fieldLabel: _('DBMS'), name:'items_mode', value: data.items_mode || 'all_files', 
        data: [ ['all_files',_('All files')], ['only_job_items',_('Job Items')] ]
    });

    var grid = new Baseliner.GridEditor({
            fieldLabel: _('Data'),
            height: 300,
            name: 'dests',
            records: data.dests,
            preventMark: false,        
            columns: [
                Ext.apply({ dataIndex:'user', header:_('User') }, ta() ), 
                Ext.apply({ dataIndex:'password', header:_('Password') }, pw() ), 
                Ext.apply({ dataIndex:'server', header: _('Server') }, ta() ),
                Ext.apply({ dataIndex:'port', header: _('Port') }, ta() ),
                Ext.apply({ dataIndex: 'service_name', header:_('Service Name') }, ta() ),
                Ext.apply({ dataIndex:'scheme', header:_('Scheme') }, ta() ),
                Ext.apply({ dataIndex:'rdbms', header:_('Type') }, cb({ default_value:'Oracle', data: [ ['Oracle',_('Oracle')], ['MySQL',_('MySQL')], ['Sybase',_('Sybase')] ]}) ),
                Ext.apply({ dataIndex: 'connect_string', header:'Conection String' }, tf() )
            ],
            viewConfig: { forceFit: true }
        });
    var tables = new Baseliner.GridEditor({
            fieldLabel: _('Tables'),
            height: 300,
            name: 'tables',
            records: data.tables,
            preventMark: false,        
            columns: [
                Ext.apply({ dataIndex:'table', header: _('Table') }, ta() )
            ],
            viewConfig: { forceFit: true }
        });
    /*
    new Baseliner.Window({ 
        layout:'form', items: grid, width: 800, height: 400 
    }).show();
    */
    return [ project, grid, tables ];
})
