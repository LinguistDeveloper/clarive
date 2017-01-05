(function(params) {
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([{
        xtype: 'numberfield',
        name: 'height',
        fieldLabel: _('Height'),
        fieldClass: "x-fieldlet-type-height",
        minValue: '1',
        value: data.height || "300"
    }, {
        xtype: 'textfield',
        allowBlank: false,
        name: 'columns',
        fieldLabel: _('Columns'),
        value: data.columns || _("Title")
    }]);
    return ret;
})
