(function(params) {
    var data = params.data || {};

    var errorsCombo = new Baseliner.ComboSingle({
        fieldLabel: _('Errors'),
        name: 'errors',
        value: data.errors || 'fail',
        data: [
            'fail',
            'warn',
            'silent'
        ]
    });

    return [{
            xtype: 'textarea',
            fieldLabel: _('URL'),
            height: 80,
            name: 'url',
            value: data.url
        },
        new Baseliner.ComboSingle({
            fieldLabel: _('Method'),
            name: 'method',
            value: data.method || 'GET',
            data: [
                'GET',
                'PUT',
                'DELETE',
                'POST'
            ]
        }), {
            xtype: 'textfield',
            fieldLabel: _('User'),
            name: 'username',
            value: data.username
        }, {
            xtype: 'textfield',
            fieldLabel: _('Password'),
            name: 'password',
            value: data.password,
            inputType: 'password'
        }, {
            xtype: 'textfield',
            fieldLabel: _('Timeout'),
            name: 'timeout',
            value: (data.timeout != undefined ? data.timeout : '')
        },
        errorsCombo, {
            xtype: 'checkbox',
            name: 'accept_any_cert',
            checked: data.accept_any_cert == 'on' ? true : false,
            boxLabel: _('Accept any server certificate')
        }, {
            xtype: 'checkbox',
            name: 'auto_parse',
            checked: data.auto_parse == 'on' ? true : false,
            boxLabel: _('Automatically parse response')
        }, {
            xtype: 'tabpanel',
            activeTab: 0,
            fieldLabel: _('Data'),
            items: [
                new Baseliner.DataEditor({
                    name: 'args',
                    title: _('Form Arguments'),
                    hide_save: true,
                    hide_cancel: true,
                    height: 260,
                    data: data.args || {}
                }),
                new Baseliner.DataEditor({
                    name: 'headers',
                    title: _('Headers'),
                    hide_save: true,
                    hide_cancel: true,
                    height: 260,
                    data: data.headers || {}
                }), {
                    xtype: 'textarea',
                    name: 'body',
                    title: _('Body'),
                    height: 260,
                    value: data.body || ''
                }
            ]
        },
    ]
})
