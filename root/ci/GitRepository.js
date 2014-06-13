(function(params){
    if( params==undefined ) params={};
    params = params.rec;
    return [
        { xtype: 'textfield', anchor: '100%', fieldLabel: _('Repository path'), name:'repo_dir', allowBlank: false, value: params.repo_dir },
        { xtype: 'textfield', anchor: '100%', fieldLabel: _('Relative path'), name:'rel_path', allowBlank: false, value: params.rel_path || '/' }
    ]
})

