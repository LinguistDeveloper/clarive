(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([ 
        { xtype:'hidden', name:'fieldletType', value: 'fieldlet.download_all_files' } 
    ]);
    return ret;
})