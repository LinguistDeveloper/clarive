(function(params){
    if( !params.rec ) params.rec = {};
    return [
        new Baseliner.ComboSingle({ fieldLabel: _('Engine Package'), name:'engine_package', data: [
            'Baseliner::Parser::Engine::C',
            'Baseliner::Parser::Engine::JSP',
            'Baseliner::Parser::Engine::SQL',
        ] 
        }), 
    ]
})

