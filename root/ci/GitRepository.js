(function(params){
    if( params==undefined ) params={};
    params = params.rec;
    return [
        { xtype: 'textfield', anchor: '100%', fieldLabel: _('Repository path'), name:'repo_dir', allowBlank: false, value: params.repo_dir },
        { xtype: 'textfield', anchor: '100%', fieldLabel: _('Relative path'), name:'rel_path', allowBlank: false, value: params.rel_path || '/' },
        new Baseliner.ComboDouble({
            name: 'revision_mode',
            fieldLabel: _('Revision Mode'),
            anchor: '40%',
            data: [ ['diff',_('Diff with Environment')], ['show',_('Individual Commits')] ],  // patch?
            value: params.revision_mode || 'diff'
        })
    ]
})

