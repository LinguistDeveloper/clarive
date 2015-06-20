(function(params){
    var data = params.data || {};
    return [
        { xtype:'textfield', fieldLabel: _('Server'), name: 'server_ip', value: params.data.server_ip },
        { xtype:'textfield', fieldLabel: _('LDAP user'), name: 'ldap_user', value: params.data.ldap_user },
        { xtype:'textfield', inputType:'password', fieldLabel: _('Password'), name: 'password', value: params.data.password },
        { xtype:'numberfield', fieldLabel: _('LDAP port'), name: 'ldap_port', value: params.data.ldap_port },
        { xtype:'textfield', fieldLabel: _('LDAP base'), name: 'ldap_base', value: params.data.ldap_base },
        { xtype:'textfield', fieldLabel: _('Filter'), name: 'filter', value: params.data.filter },
    ]
})