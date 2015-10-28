(function(params){
    var data = params.data || {};
    var common = params.common_options || Cla.dashlet_common(params);

    var context_override = new Baseliner.ComboDouble({ 
        anchor: '100%', 
        fieldLabel:_('Override CI with current context?'), 
        name:'context_override', 
        value: data.context_override==undefined ? 'context' : data.context_override,
        data: [ 
            ['context',_('Yes, override with current topic or project')],
            ['force_ci',_('No, use the CI always')]
        ]
    });

    var graph_type = new Baseliner.ComboDouble({ 
        anchor: '100%', fieldLabel:_('Graph Type'), name:'graph_type', 
        value: data.graph_type==undefined ? 'st' : data.graph_type,
        data: [ ['st',_('Space Tree')], ['rg',_('Radial Graph')], ['d3g',_('D3 Force-Directed Graph')] ]
    });

    var starting_mid = Baseliner.ci_box({ 
        name:'starting_mid', fieldLabel:_('CI as Graph Starting Point'), allowBlank: true,
        value: data.starting_mid, force_set_value: true,
        singleMode: true 
    });

    return common.concat([ 
        graph_type, 
        context_override,
        starting_mid
    ])
})





