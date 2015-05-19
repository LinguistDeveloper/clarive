(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.forEach(function(element) {
        if(element.name == 'id_field'){
            element.value = 'moniker';
            element.readOnly = true;
        }
    });
    ret.push([ 
        { xtype:'hidden', name:'fieldletType', value: 'fieldlet.system.moniker' } 
    ]);
    return ret;
})
