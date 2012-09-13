(function(params){
    return [
       { xtype:'textarea', fieldLabel: _('Description'), name:'description', height: 150 },
       Baseliner.ci_box({ name:'repository', fieldLabel:_('Repository'), role:'Repository', value: params.rec.repository, singleMode: false }),
    ]
})
