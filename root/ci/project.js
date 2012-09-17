(function(params){
    return [
       { xtype:'textarea', fieldLabel: _('Description'), name:'description', allowBlank: true, value: params.rec.description, height: 150 },
       Baseliner.ci_box({ name:'repositories', fieldLabel:_('Repository'), allowBlank: true,
           role:'Repository', value: params.rec.repository, singleMode: false })
    ]
})
