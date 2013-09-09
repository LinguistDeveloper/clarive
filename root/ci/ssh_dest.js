(function(params){
    var to = params.rec.timeout || 30;
    return [
       Baseliner.ci_box({ name:'server', fieldLabel:_('SSH Server'), role:'Server', value: params.rec.server, force_set_value:true }),
       { xtype:'textfield', fieldLabel: _('User'), name:'user', anchor:'50%', value: params.rec.user },
       { xtype:'textfield', fieldLabel: _('Port'), name:'port', value: params.rec.port },
       { xtype:'textfield', fieldLabel: _('Timeout (s)'), name:'timeout', value: params.rec.timeout },
       { xtype:'textfield', fieldLabel: _('Path'), name:'home', anchor:'100%', value: params.rec.home }
    ]
})


