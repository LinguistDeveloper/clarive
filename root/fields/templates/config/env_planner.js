(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);

    ret.push([
        { xtype:'numberfield',fieldLabel: _('Height'), name: 'height', value: data.height }
    ]);

    // TODO add a selection of available BLs ??
    return ret;
})

