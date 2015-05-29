(function(params){
    var data = params.data || {};
    return [
        { xtype: 'textfield', fieldLabel: _('Date (or blank for CURRENT date)'), name:'date', anchor:'100%', allowBlank: true, value: data.date },
    ]
})
