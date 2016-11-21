(function(params) {
    var data = params.data || {};

    var singleCheckbox = new Baseliner.CBox({
        fieldLabel: _('Single?'),
        name: 'single',
        checked: data.single,
        default_value: false
    });

    var midsOnlyCheckbox = new Baseliner.CBox({
        fieldLabel: _('Mids only?'),
        name: 'mids_only',
        checked: data.mids_only,
        default_value: false
    });

    var classCombo = new Baseliner.CIClassCombo({
        name: 'classname',
        allowBlank: false,
        fieldLabel: _('CI Class'),
        value: data.classname,
        singleMode: true
    });

    //var roleCombo = new Baseliner.CIRoleCombo({
        //name: 'role',
        //allowBlank: false,
        //fieldLabel: _('CI Role'),
        //value: data.role,
        //singleMode: true
    //});

    var queryTypeCombo = new Baseliner.ComboSingle({
        fieldLabel: _('Query type'),
        name: 'query_type',
        value: data.query_type || 'children',
        data: [
            'children',
            'parents',
            'related'
        ]
    });

    return [{
            xtype: 'textfield',
            fieldLabel: _('Mid'),
            name: 'mid',
            value: data.mid,
            allowBlank: false
        },
        queryTypeCombo,
        classCombo, {
            xtype: 'numberfield',
            fieldLabel: _('Depth'),
            name: 'depth',
            value: data.depth || 1
        },
        midsOnlyCheckbox,
        singleCheckbox
    ]
})
