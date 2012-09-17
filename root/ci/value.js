(function(params){
    var f = params.form;
    return [
       Baseliner.ci_box({ name:'variable', fieldLabel:_('Variable'), allowBlank: true, singleMode: true,
           role:'Variable', value: params.rec.projects, singleMode: false }),
       Baseliner.ci_box({ name:'projects', fieldLabel:_('Projects'), allowBlank: true,
           role:'Project', value: params.rec.projects, singleMode: false }),
       { xtype:'textarea', fieldLabel: _('Value'), name:'value', allowBlank: true, value: params.rec.value, height: 200 }
    ]
})


