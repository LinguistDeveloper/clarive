(function(params) {
    var parsers = new Baseliner.CIGrid({ title:_('Parser'), ci: { 'role': 'Parser' },
        value: params.rec.parsers, name: 'parsers' });
    
    /*
    var fields = new Baseliner.DataEditor({ title:_('Fields') });
    var rules = new Baseliner.DataEditor({ title:_('Rules') });
    var outputs = new Baseliner.DataEditor({ title:_('Build') });
    var deploy = new Baseliner.DataEditor({ title:_('Deploy') });
    */
    
    var include = new Baseliner.ArrayGrid({ 
        title:_('Include'), 
        name: 'include', 
        flex:1,
        value: params.rec.include,
        description:_('Element pattern regex to include'), 
        default_value:'\\.ext$' }); 
    
    var exclude = new Baseliner.ArrayGrid({ 
        title:_('Exclude'), 
        name: 'exclude', 
        flex:1,
        value: params.rec.exclude,
        description:_('Element pattern regex to exclude'), 
        default_value:'\\.ext$' }); 

    var tabs = new Ext.TabPanel({
        activeTab: 0,
        fieldLabel: _('Configuration'),
        height: 400,
        items: [
            { xtype:'panel', layout:'vbox', 
               layoutConfig:{ align:'stretch' },
               anchor: '100%', title:_('Paths'), items: [ include, exclude ] },
            parsers
        ]
    });
    return [
        tabs
    ]; 
})
