(function(params){
    return [
       Baseliner.ci_box({ name:'server', fieldLabel:_('Server'), role:'Server' }),
       { xtype:'textfield', fieldLabel: _('Port'), name:'port_num', emptyText: 22 },
       { xtype:'textarea', height: 180, anchor:'100%', fieldLabel: _('Private Key'), name:'private_key', allowBlank: true },
    ]
})
