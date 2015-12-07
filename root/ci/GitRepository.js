(function(params){
    if( params==undefined ) params={};
    params = params.rec;

    var include = new Baseliner.ArrayGrid({ 
        title:_('Include'), 
        name: 'include', 
        flex:1,
        value: params.include,
        description:_('Element pattern regex to include')
    });
    
    var exclude = new Baseliner.ArrayGrid({ 
        title:_('Exclude'), 
        name: 'exclude', 
        flex:1,
        value: params.exclude,
        description:_('Element pattern regex to exclude')
    });

    var tabs = new Ext.TabPanel({
        activeTab: 0,
        plugins: [ new Ext.ux.panel.DraggableTabs()], 
        fieldLabel: _('Configuration'),
        height: 430,
        items: [
            { xtype:'panel', layout:'vbox', 
               layoutConfig:{ align:'stretch' },
               anchor: '100%', title:_('Branches'), items: [ include, exclude ] },
        ]
    });

    return [
        { xtype: 'textfield', anchor: '100%', fieldLabel: _('Repository path'), name:'repo_dir', allowBlank: false, value: params.repo_dir },
        { xtype: 'textfield', anchor: '100%', fieldLabel: _('Relative path'), name:'rel_path', allowBlank: false, value: params.rel_path || '/' },
        new Baseliner.ComboDouble({
            name: 'revision_mode',
            fieldLabel: _('Revision Mode'),
            anchor: '40%',
            data: [ ['diff',_('Diff with Environment')], ['show',_('Individual Commits')] ],  // patch?
            value: params.revision_mode || 'diff'
        }),
        new Baseliner.ComboDouble({
            name: 'tags_mode',
            fieldLabel: _('Tags Mode'),
            anchor: '40%',
            data: [ ['bl',_('Only environment')], ['project',_('Project + environment')] ],  // patch?
            value: params.tags_mode || 'bl'
        }),
        tabs
    ]
})

