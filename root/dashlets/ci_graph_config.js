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

    var include_cl = new Baseliner.CIClassCombo({ fieldLabel:_('Include Classes'), name:'include_cl', value: data.include_cl });
    // var exclude_cl = new Baseliner.CIClassCombo({ fieldLabel:_('Exclude Classes'), name:'exclude_cl', value: data.exclude_cl });

    var not_in_class = new Baseliner.CBox({
        fieldLabel: _('Exclude selected classes?'), 
        name: 'not_in_class',
        checked: data.not_in_class, 
        default_value: false
    });

    var graph_type = new Baseliner.ComboDouble({ 
        anchor: '100%', fieldLabel:_('Graph Type'), name:'graph_type', 
        value: data.graph_type==undefined ? 'st' : data.graph_type,
        data: [ ['st',_('Space Tree')], ['rg',_('Radial Graph')], ['d3g',_('D3 Force-Directed Graph')] ]
    });

    var toolbar_mode = new Baseliner.ComboDouble({ 
        anchor: '100%', fieldLabel:_('Show Toolbar?'), name:'toolbar_mode', 
        value: data.toolbar_mode==undefined ? 'hide' : data.toolbar_mode,
        data: [ ['hide',_('Hide Toolbar')], ['top',_('Show Toolbar on Top')], ['bottom',_('Show Toolbar on Bottom')] ]
    });

    var starting_mid = Baseliner.ci_box({ 
        name:'starting_mid', fieldLabel:_('CI as Graph Starting Point'), allowBlank: true,
        value: data.starting_mid, force_set_value: true,
        singleMode: true 
    });

    return common.concat([ 
        graph_type, 
        context_override,
        starting_mid,
        toolbar_mode,
        include_cl,
        not_in_class,
        { xtype:'textarea', height: '80px', anchor: '100%', fieldLabel: _('Advanced JSON/MongoDB condition for filter'), name: 'condition', value: data.condition }
    ])
})





