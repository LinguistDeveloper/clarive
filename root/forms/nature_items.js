(function(params){
    var data = params.data || {};
    return [
         { xtype : "checkbox",
            name : "commit_items",
            checked: data.commit_items=='on' ? true : false,
            fieldLabel : _('Commit Items?')
         }
    ]
})

