(function(params) {
    Cla.help_push({
        title: _('Send notification'),
        path: 'rules/palette/services/send-notification'
    });
    var data = params.data || {};
    var max_size = <% BaselinerX::Type::Model::ConfigStore->new->get('config.comm.email')->{max_attach_size} %>;
    max_size = (max_size / 1024) / 1024;

    return [
        new Baseliner.UserAndRoleBox({
            fieldLabel: _('TO'),
            name: 'to',
            allowBlank: false,
            value: data.to
        }),
        new Baseliner.UserAndRoleBox({
            fieldLabel: _('CC'),
            name: 'cc',
            allowBlank: true,
            value: data.cc
        }), {
            xtype: 'textfield',
            fieldLabel: _('Subject'),
            name: 'subject',
            anchor: '100%',
            allowBlank: false,
            value: data.subject
        },
        new Baseliner.HtmlEditor({
            fieldLabel: _('Body'),
            name: 'body',
            anchor: '100%',
            allowBlank: false,
            value: data.body
        }), {
            xtype: 'textfield',
            fieldLabel: _('Attachment path'),
            name: 'attach',
            anchor: '100%',
            allowBlank: true,
            value: data.attach
        }, {
            xtype: 'label',
            fieldLabel: ' ',
            text: _('*Note: Maximum size %1 MB', max_size.toFixed(2)),
            style: {
                'color': '#888888'
            },
        }, {
            xtype: 'textfield',
            fieldLabel: _('Output filename'),
            name: 'attach_filename',
            anchor: '100%',
            allowBlank: true,
            value: data.attach_filename
        }

    ]
})