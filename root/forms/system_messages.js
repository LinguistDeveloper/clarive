(function(params){
    var data = params.data || {};
    
    var user_box = new Baseliner.model.Users({
        fieldLabel: _('Username'), 
        store: new Baseliner.Topic.StoreUsers({ autoLoad: true }),
        singleMode: true,
    });

    return [
        { xtype:'textfield', allowBlank:false, fieldLabel: _('title'), name: 'title', value: data.title },
        { xtype:'textarea', allowBlank:false, fieldLabel: _('Text'), name: 'text', value: data.text },
        { xtype:'textfield', allowBlank:false, fieldLabel:_('Expires'), name:'expires', value:'24h' },
        user_box,
        new Baseliner.CLEditor({ name:'more', fieldLabel:_('More Info'), height:340 })
    ]
})

