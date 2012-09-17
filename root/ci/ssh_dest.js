(function(params){
    var to = params.rec.timeout || 30;
    return [
       Baseliner.ci_box({ name:'server', fieldLabel:_('SSH Server'), role:'Server', value: params.rec.server }),
       { xtype:'textfield', fieldLabel: _('User'), name:'user', value: params.rec.user },
       { xtype:'textfield', fieldLabel: _('Timeout'), name:'timeout', value: params.rec.timeout },
       { xtype:'textfield', fieldLabel: _('Path'), name:'home', value: params.rec.home }
    ]
})


