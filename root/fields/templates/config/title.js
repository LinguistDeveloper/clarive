(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.forEach(function(element) {
        if(element.name == 'id_field'){
            element.value = 'title';
            element.readOnly = true;
        }
        if(element.name == 'section'){
            element.value = 'head';
            element.readOnly = true;
        }
        if(element.name == 'hidden') { element.hide() };
        if(element.name == 'allowBlank'){
            element.checked = true;
            element.disabled = true;
        }
    });
    return ret;
})
