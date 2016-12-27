(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([
        { xtype:'checkbox', name:'default_today', fieldLabel:_('Default today'), value: data.default_today, checked: data.default_today ? true : false },
        { xtype:'checkbox', name:'show_time', fieldLabel:_('Show Time?'), value: data.show_time, checked: data.show_time ? true : false }
    ]);
    return ret;
})
