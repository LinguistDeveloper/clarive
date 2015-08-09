(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.forEach(function(element) {
        if(element.name == 'id_field'){
            element.value = 'description';
            element.readOnly = true;
        }
    });
    return ret;
})
