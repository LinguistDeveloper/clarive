(function(params){
    var data = params.rec || {};
    var defaults = { driver:'MySQL' };
    return [
        new Baseliner.ComboDouble({ fieldLabel: _('Engine Package'), name:'engine_package', value: data.engine_package, data: [
            ['Baseliner::Parser::Engine::C', 'C'],
            ['Baseliner::Parser::Engine::NET', '.NET'],
            ['Baseliner::Parser::Engine::JSP', 'JSP'],
            ['Baseliner::Parser::Engine::SQL', 'SQL Statements'],
            ['Baseliner::Parser::Engine::SQLT', 'SQL Schema']
        ] 
        }),
        new Baseliner.DataEditor({
            name: 'engine_options', value: data.engine_options || defaults, fieldLabel: _('Options'), height: 400
        })
    ]
})

