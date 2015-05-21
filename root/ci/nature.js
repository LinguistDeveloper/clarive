(function(params) {
    var parsers = new Baseliner.CIGrid({ title:_('Parser'), ci: { 'role': 'Parser' },
        value: params.rec.parsers, name: 'parsers' });
    
    /*
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
    
    var variables = new Baseliner.VariableForm({
        name: 'variables',
        title: _('Variables'),
        data: params.rec.variables
    });

    var tabs = new Ext.TabPanel({
        activeTab: 0,
        plugins: [ new Ext.ux.panel.DraggableTabs()], 
        fieldLabel: _('Configuration'),
        height: 430,
        items: [
            variables,
            { xtype:'panel', layout:'vbox', 
               layoutConfig:{ align:'stretch' },
               anchor: '100%', title:_('Paths'), items: [ include, exclude ] },
            parsers 
        ]
    });
    
    return [
        { xtype:'cbox', fieldLabel: _('Exclude unparsed items'), name: 'only_parsed', checked: params.rec.only_parsed },
        tabs
    ]; 
})
