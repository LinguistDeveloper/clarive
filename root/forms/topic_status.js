(function(params){
    var data = params.data || {};
    return [
        { xtype:'textfield', fieldLabel: _('Topics'), name: 'topics', value: data.topics },
        new Baseliner.ComboStatus({ name: 'new_status', fieldLabel: _('New Status'), value: data.new_status  })
    ]
})




