(function(params) {
    return [{
            xtype: 'textfield',
            fieldLabel: _('Hostname or IP'),
            name: 'hostname',
            anchor: '100%',
            allowBlank: false
        },
        Baseliner.ci_box({
            name: 'proxy',
            fieldLabel: _('Proxy Server'),
            allowBlank: true,
            role: 'Server',
            value: params.rec.proxy,
            force_set_value: true,
            singleMode: true
        }), {
            xtype: 'textfield',
            fieldLabel: _('Proxy Timeout (s)'),
            name: 'proxy_timeout',
            anchor: '10%',
            allowBlank: true
        },
        new Baseliner.ComboSingle({
            name: 'os',
            data: ['unix', 'win', 'mvs'],
            fieldLabel: _('OS')
        }), {
            xtype: 'textfield',
            fieldLabel: _('OS Version'),
            name: 'osver',
            anchor: '100%',
            allowBlank: true
        },
        new Baseliner.ComboSingle({
            name: 'arch',
            data: ['x86_64', 'x86'],
            fieldLabel: _('Architecture')
        }),
        new Baseliner.CBox({
            fieldLabel: _('Connect by SSH'),
            name: 'connect_ssh',
            checked: params.rec.connect_ssh,
            default_value: true
        }),
        new Baseliner.CBox({
            fieldLabel: _('Connect by Clax'),
            name: 'connect_clax',
            checked: params.rec.connect_clax,
            default_value: true
        }),
        new Baseliner.CBox({
            fieldLabel: _('Connect by FTP'),
            name: 'connect_ftp',
            checked: params.rec.connect_ftp,
            default_value: false
        }),
        new Baseliner.CBox({
            fieldLabel: _('Connect by Worker'),
            name: 'connect_worker',
            checked: params.rec.connect_worker,
            default_value: false
        }),
        new Baseliner.CBox({
            fieldLabel: _('Connect by Balix'),
            name: 'connect_balix',
            checked: params.rec.connect_balix,
            default_value: false
        }), {
            xtype: 'textarea',
            fieldLabel: _('Remote Temp Dir'),
            name: 'remote_tmp',
            height: 50,
            anchor: '100%',
            allowBlank: true
        }, {
            xtype: 'textarea',
            fieldLabel: _('Remote Tar'),
            name: 'remote_tar',
            height: 50,
            anchor: '100%',
            allowBlank: true
        }, {
            xtype: 'textarea',
            fieldLabel: _('Remote Perl'),
            name: 'remote_perl',
            height: 50,
            anchor: '100%',
            allowBlank: true
        }
    ]
})