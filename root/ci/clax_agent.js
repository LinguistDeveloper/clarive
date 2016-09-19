(function(params) {

    var basicAuthEnabled = new Baseliner.CBox({
        fieldLabel: _('Enabled'),
        name: 'basic_auth_enabled',
        value: Baseliner.eval_boolean(params.rec.basic_auth_enabled),
        listeners: {
            check: function(field, checked) {
                if (checked) {
                    basicAuthUsername.enable();
                    basicAuthPassword.enable();
                }
                else {
                    basicAuthUsername.disable();
                    basicAuthPassword.disable();
                }
            }
        }
    });

    var basicAuthUsername = new Ext.form.TextField({
        fieldLabel: _('Username'),
        allowBlank: false,
        name: 'basic_auth_username',
        value: params.rec.basic_auth_username,
        anchor: '50%',
        disabled: basicAuthEnabled.checked ? false : true
    });

    var basicAuthPassword = new Ext.form.TextField({
        fieldLabel: _('Password'),
        allowBlank: false,
        name: 'basic_auth_password',
        value: params.rec.basic_auth_password,
        anchor: '50%',
        disabled: basicAuthEnabled.checked ? false : true
    });

    var sslEnabled = new Baseliner.CBox({
        fieldLabel: _('Enabled'),
        name: 'ssl_enabled',
        value: Baseliner.eval_boolean(params.rec.ssl_enabled),
        listeners: {
            check: function(field, checked) {
                if (checked) {
                    sslCA.enable();
                    sslCert.enable();
                    sslKey.enable();
                    sslVerify.enable();
                }
                else {
                    sslCA.disable();
                    sslCert.disable();
                    sslKey.disable();
                    sslVerify.disable();
                }
            }
        }
    });

    var sslVerify = new Baseliner.CBox({
        fieldLabel: _('Verify'),
        name: 'ssl_verify',
        value: params.rec.ssl_verify,
        disabled: sslEnabled.checked ? false : true
    });
    var sslCA = new Ext.form.TextField({
        fieldLabel: _('CA File'),
        name: 'ssl_ca',
        value: params.rec.ssl_ca,
        anchor: '100%',
        disabled: sslEnabled.checked ? false : true
    });
    var sslCert = new Ext.form.TextField({
        fieldLabel: _('Certificate File'),
        name: 'ssl_cert',
        value: params.rec.ssl_cert,
        allowBlank: false,
        anchor: '100%',
        disabled: sslEnabled.checked ? false : true
    });
    var sslKey = new Ext.form.TextField({
        fieldLabel: _('Private Key File'),
        name: 'ssl_key',
        value: params.rec.ssl_key,
        allowBlank: false,
        anchor: '100%',
        disabled: sslEnabled.checked ? false : true
    });

    return [
        Baseliner.ci_box({
            name: 'server',
            fieldLabel: _('Server'),
            allowBlank: false,
            role: 'Server',
            value: params.rec.server,
            force_set_value: true,
            singleMode: true
        }), {
            xtype: 'textfield',
            fieldLabel: _('Port'),
            name: 'port',
            value: params.rec.port || 11801,
            anchor: '15%',
            type: 'int',
            vtype: 'port',
            maxLength: 5
        }, {
            xtype: 'fieldset',
            title: _('Basic Authentication'),
            items: [
                basicAuthEnabled,
                basicAuthUsername,
                basicAuthPassword
            ]
        }, {
            xtype: 'fieldset',
            title: _('SSL'),
            items: [
                sslEnabled,
                sslVerify,
                sslCA,
                sslCert,
                sslKey,
            ]
        }
    ]
})
