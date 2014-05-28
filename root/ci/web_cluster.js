(function(params){
    var data = params.rec || {}; 
    
    return [
      { xtype: 'textfield', fieldLabel: _('URL'), anchor:'100%', name:'url', allowBlank: false, value: data.url },
    	Baseliner.ci_box({ name:'server', anchor:'100%', fieldLabel:_('Server'), role:'Server', allowBlank: false, force_set_value: true, value: params.rec.server }),
      { xtype: 'textfield', fieldLabel: _('Doc Root'), anchor:'100%', name:'doc_root', allowBlank: false, value: data.doc_root },
      { xtype: 'textfield', fieldLabel: _('User'), anchor:'100%', name:'user', allowBlank: true, value: data.user },
      Baseliner.ci_box({ name:'instances', anchor:'100%', fieldLabel:_('Instances'), isa:'web_instance', allowBlank: true, singleMode:false, force_set_value: true, value: data.instances })
    ]
})
