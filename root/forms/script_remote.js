(function(params){
    var data = params.data || {};
    return [
        Baseliner.ci_box({ name: 'server', role:'Server', fieldLabel:_('Server'), with_vars: 1, value: params.data.server, force_set_value: true }),
        { xtype:'textfield', fieldLabel: _('User'), name: 'user', value: params.data.user },
        { xtype:'textarea', fieldLabel: _('Path'), height: 80, name: 'path', value: params.data.path },
        new Baseliner.ArrayGrid({ 
            fieldLabel:_('Arguments'), 
            name: 'args', 
            value: params.data.args,
            description:_('Command arguments'), 
            default_value:'.' 
        }), 
        new Baseliner.ComboSingle({ fieldLabel: _('Errors'), name:'errors', value: params.data.errors || 'fail', data: [
            'fail',
            'warn',
            'silent'
        ]}),
        { xtype:'textarea', fieldLabel: _('Home Directory'), height: 80, name: 'home', value: params.data.home }
        //{ xtype:'textarea', fieldLabel: _('Stdin'), height: 120, name: 'stdin', value: params.data.stdin }
    ]
})


