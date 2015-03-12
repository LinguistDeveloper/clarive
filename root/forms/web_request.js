(function(params){
    var data = params.data || {};
    return [
        { xtype:'textarea', fieldLabel: _('URL'), height: 80, name: 'url', value: data.url },
        new Baseliner.ComboSingle({ fieldLabel: _('Method'), name:'method', value: data.method || 'GET', data: [
            'GET',
            'PUT',
            'DELETE',
            'POST'
        ]}),
        { xtype:'textfield', fieldLabel: _('Encoding'), name: 'encoding', value: (data.encoding ? data.encoding : 'utf-8' )  },
        { xtype:'textfield', fieldLabel: _('Timeout'), name: 'timeout', value: (data.timeout!=undefined ? data.timeout : 0 )  },
        { xtype:'textfield', fieldLabel: _('User'), name: 'username', value: data.username },
        { xtype:'textfield', fieldLabel: _('Password'), name: 'password', value: data.password, inputType:'password' },
        { xtype : "checkbox", name : "accept_any_cert", checked: data.accept_any_cert=='on' ? true : false, boxLabel : _('Accept any server certificate') },
        { xtype:'tabpanel', activeTab:0, fieldLabel:_('Data'),  items:[
           new Baseliner.DataEditor({ name:'args', title: _('Form Arguments'), 
               hide_save: true, hide_cancel: true, height: 260, data: data.args || {} }),
           new Baseliner.DataEditor({ name:'headers', title: _('Headers'), 
               hide_save: true, hide_cancel: true, height: 260, data: data.headers || {} }),
           { xtype:'textarea', name:'body', title:_('Body'), height: 260, value: data.body||'' }
        ]},
    ]
})


