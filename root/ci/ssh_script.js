(function(params){
    return [
       Baseliner.ci_box({ name:'server', fieldLabel:_('SSH Destination'), role:'Agent', value: params.rec.data.server }),
       { xtype:'textfield', fieldLabel: _('Script'), name:'script', value: params.rec.data.script }
    ]
})
