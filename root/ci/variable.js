(function(params){
    return [
       { xtype:'textfield', fieldLabel: _('Variable'), name:'variable', allowBlank: true, value: params.rec.variable },
       { xtype:'textarea', fieldLabel: _('Value'), name:'value', allowBlank: true, value: params.rec.value, height: 200 },
       Baseliner.ci_box({ name:'projects', fieldLabel:_('Projects'), allowBlank: true,
           role:'Project', value: params.rec.projects, singleMode: false })
    ]
})

