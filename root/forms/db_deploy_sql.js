(function(params){
    var transactional = new Baseliner.CBox({ name: 'transactional', checked: params.data.transactional, fieldLabel: _("Transactional") });
    
    var split_mode = new Baseliner.ComboSingle({ fieldLabel: _('Split Mode'), name:'split_mode', value: params.data.split_mode || 'auto', data: [
            'auto',
            'manual',
            'none'
        ]});
    split_mode.on('select', function(){
        if( split_mode.getValue() == 'manual' )
            split.show();
        else 
            split.hide();
    });
    var split = new Ext.form.TextField({ anchor:'100%', fieldLabel: _('Split'), hidden: true, name:'split', value: params.data.split || ';' });
    return [
       Baseliner.ci_box({ name:'db', anchor:'100%', fieldLabel:_('Database'), with_vars: 1, role:'DatabaseConnection', force_set_value: true, value: params.data.db }),
        new Baseliner.ComboSingle({ fieldLabel: _('Error Mode'), name:'error_mode', value: params.data.error_mode || 'fail', data: [
            'fail',
            'ignore',
            'warn',
            'silent'
        ]}),
        transactional,
       //{ xtype:'textarea', height: 180, anchor:'100%', fieldLabel: _('Options'), name:'options', value: params.data.options },
        new Baseliner.ComboSingle({ fieldLabel: _('Mode'), name:'mode', value: params.data.mode || 'direct', data: [
            'direct',
            'block',
            'execute'
        ]}),
        split_mode,
        split,
        new Baseliner.ComboSingle({ fieldLabel: _('Comment'), name:'comment', value: params.data.comment || 'strip', data: [
            'strip',
            'keep'
        ]}),
        new Baseliner.ComboSingle({ fieldLabel: _('Exists Action'), name:'exists_action', value: params.data.exists_action || 'drop', data: [
            'drop',
            'skip',
            'fail',
            'ignore'
        ]}),
        { xtype:'tabpanel', fieldLabel: _('Filters'), height: 200, activeTab:0, items:[
            new Baseliner.ArrayGrid({ 
                title:_('Include Paths'), 
                name: 'include_path', 
                value: params.data.include_path,
                description:_('Include Path Regex'), 
                default_value:'.*' 
            }), 
            new Baseliner.ArrayGrid({ 
                title:_('Exclude Path'), 
                name: 'exclude_path', 
                value: params.data.exclude_path,
                description:_('Exclude Path Regex'), 
                default_value:'.*' 
            }),
            new Baseliner.ArrayGrid({ 
                title:_('Include Content'), 
                name: 'include_content', 
                value: params.data.include_content,
                description:_('Include Content Regex'), 
                default_value:'.*' 
            }), 
            new Baseliner.ArrayGrid({ 
                title:_('Exclude Content'), 
                name: 'exclude_content', 
                value: params.data.exclude_content,
                description:_('Exclude Content Regex'), 
                default_value:'.*' 
            })
        ]}
    ]
})



