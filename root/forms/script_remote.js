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
        { xtype:'tabpanel', fieldLabel: _('Output'), height: 180, activeTab:0, items:[
            new Baseliner.ArrayGrid({ 
                title:_('Error'), 
                name: 'output_error', 
                value: data.output_error,
                description:_('Regex'), 
                default_value:'.*' 
            }), 
            new Baseliner.ArrayGrid({ 
                title:_('Warn'), 
                name: 'output_warn', 
                value: data.output_warn,
                description:_('Regex'), 
                default_value:'.*' 
            }),
            new Baseliner.ArrayGrid({ 
                title:_('OK'), 
                name: 'output_ok', 
                value: data.output_ok,
                description:_('Regex'), 
                default_value:'.*' 
            }),
            new Baseliner.ArrayGrid({ 
                title:_('Capture'), 
                name: 'output_capture', 
                value: data.output_capture,
                description:_('Use Named Captures in Regex'), 
                default_value:'.*' 
            })
        ]}
    ]
})


