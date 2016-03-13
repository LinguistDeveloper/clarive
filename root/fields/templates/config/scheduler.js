(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);

    ret.push([ 
        { xtype:'numberfield', name:'height', fieldClass: "x-fieldlet-type-height", fieldLabel:_('Height'), minValue:'1', value: data.height || "300"}
    ]);
    return ret;
})
