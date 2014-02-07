(function(params){
    return [
        Baseliner.ci_box({ name:'server', fieldLabel:_('Server'), allowBlank: true,
               role:'Server', value: params.rec.server, force_set_value: true, singleMode: true }),
        { xtype: 'textfield', fieldLabel: _('User'), name:'user', anchor:'100%' },
        { xtype: 'textfield', fieldLabel: _('Port'), name:'port', anchor:'100%', allowBlank: false },
        { xtype: 'textarea', fieldLabel: _('Key'), name:'key', height: 50, anchor:'100%', allowBlank: true },
        { xtype: 'textarea', fieldLabel: _('Chunk Size'), name:'chunk_size', height: 50, anchor:'100%', allowBlank: true }
    ]
})

