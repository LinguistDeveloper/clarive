(function(params){
    return [
       Baseliner.ci_box({ name:'server', fieldLabel:_('Server'), role:'Server',
        value: params.rec.server, force_set_value:true, allowBlank: false }),
       { xtype:'textfield', fieldLabel: _('User'), name:'user', value: params.rec.user },
       { xtype:'textfield', fieldLabel: _('Port'), name:'port_num', vtype: 'port', maxLength: 5, value: params.rec.port_num },
       { xtype:'textfield', fieldLabel: _('Timeout (s)'), name:'timeout', value: params.rec.timeout },
       { xtype:'textfield', anchor:'100%', fieldLabel: _('Private Key Filename'), name:'private_key', allowBlank: true }
    ]
})
