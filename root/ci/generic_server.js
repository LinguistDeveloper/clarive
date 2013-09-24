(function(params){
    return [
        { xtype: 'textfield', fieldLabel: _('Hostname or IP'), name:'hostname', anchor:'100%', allowBlank: false },
        new Baseliner.CBox({ fieldLabel: _('Connect by Worker'), name: 'connect_worker', checked: params.rec.connect_worker, default_value: true }),
        new Baseliner.CBox({ fieldLabel: _('Connect by Balix'), name: 'connect_balix', checked: params.rec.connect_balix, default_value: true }),
        new Baseliner.CBox({ fieldLabel: _('Connect by SSH'), name: 'connect_ssh', checked: params.rec.connect_ssh, default_value: true })
    ]
})
