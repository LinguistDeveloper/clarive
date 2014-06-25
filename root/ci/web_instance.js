(function(params){
    var data = params.rec || {}; 

    var bp = {};
    bp.class = 'web_instance';
    var store = new Baseliner.store.CI({ url:'/ci/web_instance/store', autoLoad:true, baseParams: bp });


    return [
      Baseliner.ci_box({name:'server', anchor:'100%', fieldLabel:_('Server'), role:'Server', allowBlank: false, force_set_value: true, value: data.server }),
      { xtype: 'textfield', fieldLabel: _('IP'), anchor:'100%', name:'ip', allowBlank: true, value: data.ip },
      { xtype: 'textfield', fieldLabel: _('Port'), anchor:'100%', name:'web_port', allowBlank: true, value: data.web_port },
      { xtype: 'textfield', fieldLabel: _('Stop script'), anchor:'100%', name:'stop_script', allowBlank: true, value: data.stop_script },
      { xtype: 'textfield', fieldLabel: _('Start script'), anchor:'100%', name:'start_script', allowBlank: true, value: data.start_script },
      { xtype: 'textfield', fieldLabel: _('Install'), anchor:'100%', name:'install', allowBlank: true, value: data.install },
      { xtype: 'cbox', colspan: 1, fieldLabel: _('Contingency'), name:'contingency', checked: false, allowBlank: false },
      { xtype: 'textfield', fieldLabel: _('Document root Dynamic File '), anchor:'100%', name:'doc_root_dynamic_fixed', allowBlank: true, value: data.doc_root_dynamic_fixed },
      { xtype: 'textfield', fieldLabel: _('Document root Static File '), anchor:'100%', name:'doc_root_static_fixed', allowBlank: true, value: data.doc_root_static_fixed },
      { xtype: 'textfield', fieldLabel: _('Server0'), anchor:'100%', name:'server0', allowBlank: true, value: data.server0 },
      { xtype: 'textfield', fieldLabel: _('Server1'), anchor:'100%', name:'server1', allowBlank: true, value: data.server1 },
      { xtype: 'textfield', fieldLabel: _('Server2'), anchor:'100%', name:'server2', allowBlank: true, value: data.server2 },
      { xtype: 'textfield', fieldLabel: _('Server3'), anchor:'100%', name:'server3', allowBlank: true, value: data.server3 },
      { xtype: 'textfield', fieldLabel: _('Server4'), anchor:'100%', name:'server4', allowBlank: true, value: data.server4 },
      { xtype: 'textfield', fieldLabel: _('Server5'), anchor:'100%', name:'server5', allowBlank: true, value: data.server5 },
      { xtype: 'textfield', fieldLabel: _('Server6'), anchor:'100%', name:'server6', allowBlank: true, value: data.server6 }
    ]
})
