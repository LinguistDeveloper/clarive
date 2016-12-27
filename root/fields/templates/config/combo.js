(function(params) {
    Cla.help_push({ title:_('Combo'), path:'rules/palette/fieldlets/combo' });
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([{
        xtype: 'textfield',
        fieldLabel: _('Options'),
        name: 'options',
        value: data.options
    }, {
        xtype: 'textfield',
        fieldLabel: _('Default Value'),
        name: 'default_value',
        value: data.default_value
    }]);
    return ret;
})