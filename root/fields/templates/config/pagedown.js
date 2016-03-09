(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([
        { xtype:'numberfield', name:'height', fieldLabel:_('Height'), fieldClass: "height-fieldlet-field", minValue:'1', value: data.height }
    ]);
    return ret;
})
