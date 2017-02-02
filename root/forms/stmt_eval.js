(function(params){
    var data = params.data || {},
        code;

    if( Ext.isIE ) {
        code = new Ext.form.TextArea({
            fieldLabel: _('Code'),
            anchor: '100% -10',
            name: 'code',
            value: data.code
        });
    } else {
        code = new Cla.AceEditor({
            fieldLabel: _('Code'),
            anchor: '100% -10',
            name: 'code',
            value: data.code
        });
    }

    return [
        code
    ]
})




