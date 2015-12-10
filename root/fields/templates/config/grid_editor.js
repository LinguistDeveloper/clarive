(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([ 
        { xtype:'textfield', name:'columns', fieldLabel:_('Columns'), value: data.columns } 
    ]);
    return ret;
})
