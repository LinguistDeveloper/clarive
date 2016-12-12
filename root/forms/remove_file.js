(function(params) {
    var data = params.data || {};
    Cla.help_push({
        title: _('Remove Files'),
        path: 'rules/palette/services/remove-files'
    });

    var asset_mid = new Ext.form.TextField({
        fieldLabel: _('Asset mids'),
        name: 'asset_mid',
        value: data.remove == 'asset_mid' ? data.asset_mid : '',
        hidden: (data.remove == 'fields')
    });

    var fields = new Ext.form.TextField({
        fieldLabel: _('Fields'),
        name: 'fields',
        value: data.remove == 'fields' ? data.fields : '',
        hidden: !(data.remove && data.remove == 'fields')
    });

    var remove = new Ext.form.RadioGroup({
        name: 'remove',
        defaults: {
            xtype: "radio",
            name: "remove",
        },
        fieldLabel: _('Remove by'),
        items: [{
            boxLabel: _('Asset mids'),
            inputValue: 'asset_mid',
            checked: !(data.remove == 'fields'),
        }, {
            boxLabel: _('Fields'),
            inputValue: 'fields',
            checked: data.remove == 'fields' ? true : false
        }],
        listeners: {
            change: function(radiogroup, radio) {
                if (radio.inputValue == 'fields') {
                    fields.show();
                    asset_mid.hide();
                } else {
                    fields.hide();
                    asset_mid.show();
                }
            }
        }
    });
    return [
        remove,
        asset_mid,
        fields, {
            allowBlank: false,
            xtype: 'textfield',
            fieldLabel: _('Topic mid'),
            name: 'topic_mid',
            value: data.topic_mid
        }, {
            xtype: 'textfield',
            fieldLabel: _('User'),
            name: 'username',
            value: data.username
        }
    ]
})
