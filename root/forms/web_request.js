(function(params){
    var data = params.data || {};
    return [
        { xtype:'textarea', fieldLabel: _('URL'), height: 80, name: 'url', value: params.data.url },
        new Baseliner.ComboSingle({ fieldLabel: _('Method'), name:'method', value: params.data.method || 'GET', data: [
            'GET',
            'PUT',
            'DELETE',
            'POST'
        ]}),
        { xtype:'textfield', fieldLabel: _('User'), name: 'username', value: params.data.username },
        { xtype:'textfield', fieldLabel: _('Password'), name: 'password', value: params.data.password, inputType:'password' },
           new Baseliner.DataEditor({ name:'args', fieldLabel: _('Form Arguments'), 
               hide_save: true, hide_cancel: true, height: 260, data: data.args || {} }),
    ]
})


