(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    
    ret.push([ 
        { xtype:'textfield', name:'branch', fieldLabel: _('Branch'), value: data.branch },
        { xtype:'numberfield', name:'height', fieldLabel: _('Height'), fieldClass: "x-fieldlet-type-height", minValue:'1', value: data.height }
    ]);
    return ret;
})
