(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    var value_type = Baseliner.generic_list_fields(data, { filter_name: 'Roles' });
    ret.push(value_type);

    return ret;
})
