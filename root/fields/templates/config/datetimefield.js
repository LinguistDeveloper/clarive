(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([ 
        { xtype:'hidden', name:'fieldletType', value: 'fieldlet.datetime' },
        { xtype:'checkbox', name:'default_today', fieldLabel:_('Default today'), value: data.default_today, checked: data.default_today ? true : false }
    ]);
    return ret;
})
