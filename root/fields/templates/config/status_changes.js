(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.forEach(function(element) {
        // if(element.name == 'id_field'){
        //     element.value = 'status_new';
        //     element.readOnly = true;
        // }
        if(element.name == 'section'){
            element.value = 'details';
            element.readOnly = true;
        }
        if(element.name == 'hidden') { element.hide() };
        if(element.name == 'allowBlank') { element.hide() };
    });
    ret.push([ 
        { xtype:'hidden', name:'fieldletType', value: 'fieldlet.status_changes' } 
    ]);
    return ret;
})
