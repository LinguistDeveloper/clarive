(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);

    ret.push([ 
        { xtype:'numberfield', name:'height', fieldClass: "height-fieldlet-field", fieldLabel:_('Height'), minValue:'1', value: data.height }
    ]);
    return ret;
})
