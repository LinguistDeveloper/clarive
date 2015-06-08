(function(params){
    var data = params.data || {};
    return [
        { xtype:'textfield', fieldLabel:_('User'), name:'user', value: data.user || 'myuser' }
    ]
});

