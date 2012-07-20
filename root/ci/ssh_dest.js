(function(params){

    return [
       Baseliner.ci_box({ name:'server', fieldLabel:_('SSH Server'), role:'Server', value: params.rec.data.server }),
       { xtype:'textfield', fieldLabel: _('Path'), name:'home', value: params.rec.data.home }
    ]
})


