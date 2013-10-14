(function(params){
    var data = params.data || {};
    
    var code = new Ext.form.TextArea({ fieldLabel:_('Code'), anchor:'100%', height: 500, name:'code', value: params.data.code });

    return [
        { xtype:'textfield',name:'varname',fieldLabel:_('Stash Variable'), value: params.data.varname },
        code
    ]
})





