(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.forEach(function(element) {
        if(element.name == 'id_field'){
            element.value = 'status_new';
            element.readOnly = true;
        }
        if(element.name == 'section'){
            element.value = 'details';
            element.readOnly = true;
        }
        if(element.name == 'allowBlank'){
            element.checked = true;
            element.disabled = true;
        }
    });
    ret.push([ 
        { xtype:'hidden', name:'fieldletType', value: 'fieldlet.system.status_new' } 
    ]);
    return ret;
})
