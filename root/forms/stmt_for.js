(function(params){
    var data = params.data || {};
    
    var code;
    if( Ext.isIE ) {
        code = new Ext.form.TextArea({ fieldLabel:_('Code'), anchor:'100%', height: 500, name:'code', value: data.code });
    } else {
        code = new Baseliner.AceEditor({
            fieldLabel:_('Code'), anchor:'100%', height: 500, name:'code', value: data.code
        });
    }
    
    return [
        { xtype:'textfield',name:'varname',fieldLabel:_('Stash Variable'), value: data.varname },
        code
    ]
})





