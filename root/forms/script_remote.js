(function(params){
    var data = params.data || {};
    return [
        Baseliner.ci_box({ name: 'server', role:'Baseliner::Role::HasAgent', fieldLabel:_('Server'), with_vars: 1, value: params.data.server, force_set_value: true }),
        { xtype:'textfield', fieldLabel: _('User'), name: 'user', value: params.data.user },
        new Baseliner.MonoTextArea({ fieldLabel: _('Path'), height: 80, name: 'path', value: params.data.path }),
        new Baseliner.ArrayGrid({ 
            fieldLabel:_('Arguments'), 
            name: 'args', 
            value: params.data.args,
            description:_('Command arguments'), 
            default_value:'.' 
        }), 
        new Baseliner.MonoTextArea({ fieldLabel: _('Home Directory'), height: 50, name: 'home', value: params.data.home }),
        new Baseliner.ComboSingle({ fieldLabel: _('Errors'), name:'errors', value: params.data.errors || 'fail', data: [
            'fail',
            'warn',
            'silent'
        ]}),
        new Baseliner.ErrorOutputTabs({ data: data }) 
    ]
})


