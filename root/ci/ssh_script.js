(function(params){
    return [
       Baseliner.ci_box({ name:'server', fieldLabel:_('SSH Destination'), role:'Agent', value: params.rec.server, force_set_value:true }),
       { xtype:'textfield', fieldLabel: _('Script'), name:'script', value: params.rec.script }
    ]
})
