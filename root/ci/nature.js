(function(params) {
    var loaders = new Baseliner.CIGrid({ title:_('Loader'), ci: { 'role': 'Loader' },
        value: params.rec.loaders, name: 'loaders' });
    
    var fields = new Baseliner.DataEditor({ title:_('Fields') });
    var rules = new Baseliner.DataEditor({ title:_('Rules') });
    var outputs = new Baseliner.DataEditor({ title:_('Build') });
    var deploy = new Baseliner.DataEditor({ title:_('Deploy') });
    
    var tabs = new Ext.TabPanel({
        activeTab: 0,
        fieldLabel: _('Configuration'),
        height: 400,
        items: [
            loaders,
            fields,
            rules,
            outputs,
            deploy
        ]
    });
    return [
        tabs
    ]; 
})
