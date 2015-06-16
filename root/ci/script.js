(function(params){
    return [
       { xtype:'textarea', height: 80, anchor:'100%', fieldLabel: _('Script Path'), name:'path', value: params.rec.script },
        new Baseliner.ArrayGrid({ 
            fieldLabel:_('Arguments'), 
            name: 'args', 
            value: params.rec.args,
            description:_('Command arguments'), 
            default_value:'.' 
        }), 
       Baseliner.ci_box({ name:'server', fieldLabel:_('Server'), role:'Server', value: params.rec.server, force_set_value:true, singleMode: false }),
       Baseliner.ci_box({ name:'agent', fieldLabel:_('Agent'), role:'Agent', value: params.rec.agent, force_set_value:true, singleMode: false })
    ]
})
