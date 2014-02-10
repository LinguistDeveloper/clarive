(function(params){
    var data = params.data || {};
    var fail_mode = new Baseliner.ComboDouble({ 
        fieldLabel: _('Fail Mode'), name:'fail_mode', value: data.fail_mode || 'skip', 
        data: [
          ['skip',_('Skip if no matches')], 
          ['warn',_('Warning if no match')],
          ['fail',_('Fail if no match')]
        ]
    });
    return [
        Baseliner.ci_box({ name: 'parsers', role:'Parser', fieldLabel:_('Parsers'), with_vars: 1, value: data.parsers, singleMode: false, force_set_value: true }),
        new Baseliner.MonoTextArea({ fieldLabel: _('File Path'), height: 80, name: 'path', value: params.data.path }),
        fail_mode
    ]
})
