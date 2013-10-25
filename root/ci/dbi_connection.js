(function(params){
    var data = params.rec;
    return [
       Baseliner.ci_box({ name:'server', anchor:'100%', fieldLabel:_('Server'), role:'Server', force_set_value: true, value: data.server }),
       new Baseliner.ComboSingleRemote({
            name: 'driver',
            field: 'driver',
            fields: [ 'driver' ],
            allowBlank: false,
            fieldLabel: _('Driver'),
            url: '/ci/dbi_connection/list_drivers',
            value: data.driver 
       }),
       { xtype:'textfield', fieldLabel: _('User'), anchor:'100%', name:'user', value: data.user },
       { xtype:'textfield', inputType:'password', anchor:'100%', name:'password', fieldLabel: _('Password'), value: data.password },
       { xtype:'textfield', anchor:'100%', name:'timeout', fieldLabel: _('Timeout'), value: data.timeout },
       { xtype:'textarea', height: 80, anchor:'100%', fieldLabel: _('Data Source'), name:'data_source', value: data.data_source },
       { xtype:'textfield', anchor:'100%', fieldLabel: _('Cmd. Line Connection'), name:'connect_str', value: data.connect_str },
       { xtype:'tabpanel', height: 300, fieldLabel: _('Configuration'), activeTab:0, items:[
           new Baseliner.DataEditor({ name:'parameters', title: _('Driver Parameters'), 
               hide_save: true, hide_cancel: true,
               data: data.parameters || { AutoCommit: 0, RaiseError: 1 } }),
           new Baseliner.DataEditor({ name:'envvars', title: _('Environment Variables'), 
               hide_save: true, hide_cancel: true,
               data: data.envvars || {} })
       ]}
    ]
})


