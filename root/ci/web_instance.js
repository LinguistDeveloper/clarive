(function(params){
    var data = params.rec || {}; 
    
    return [
      { xtype: 'textfield', fieldLabel: _('IP'), anchor:'100%', name:'ip', allowBlank: true, value: data.ip },
      { xtype: 'textfield', fieldLabel: _('Port'), anchor:'100%', name:'web_port', allowBlank: true, value: data.web_port },
      { xtype: 'textfield', fieldLabel: _('Executable'), anchor:'100%', name:'executable', allowBlank: true, value: data.executable },
      { xtype: 'textfield', fieldLabel: _('Install'), anchor:'100%', name:'install', allowBlank: true, value: data.install },
      { xtype: 'checkbox', colspan: 1, fieldLabel: _('Contingency'), name:'contingency', checked: false, allowBlank: false },
      { xtype: 'textfield', fieldLabel: _('Document root Dynamic File '), anchor:'100%', name:'doc_root_dynamic_fixed', allowBlank: true, value: data.doc_root_dynamic_fixed },
      { xtype: 'textfield', fieldLabel: _('Document root Static File '), anchor:'100%', name:'doc_root_static_fixed', allowBlank: true, value: data.doc_root_static_fixed }
    ]
})