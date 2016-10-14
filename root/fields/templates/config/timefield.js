(function(params) {
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([{
        xtype: 'textfield',
        fieldLabel: _('Time format'),
        name: 'format',
        value: data.format || Cla.constants.SERVER_TIME_FORMAT
    }]);
    return ret;
})