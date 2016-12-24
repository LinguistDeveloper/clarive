(function(params){
    var data = params.data || {};

    var code;
    if( Ext.isIE ) {
        code = new Ext.form.TextArea({ fieldLabel:_('Code'), anchor:'100%', height: 500, name:'code', value: params.data.code });
        /*
         * Codemirror has height-width problems
        var editor;
        code.on('afterrender', function(){
            code.el.setHeight( 500 );
            editor = CodeMirror.fromTextArea( code.getEl().dom , Ext.apply({
               lineNumbers: true,
               tabMode: "indent",
               smartIndent: true,
               indentUnit: 4,
               tabSize: 4,
               electricChars: false,  // allow editor to reindent according to certain chars
               matchBrackets: true,
            }, Cla.AceEditor ));
            var hlLine = editor.setLineClass(0, "activeline");
            //editor.setSize( '100%', code.getEl().getHeight() );
            editor.setOption('mode', 'perl');
            editor.setOption('theme', 'light');
            editor.focus();
        });
        */
    } else {
        code = new Cla.AceEditor({
            fieldLabel:_('Code'), anchor:'100%', height: 500, name:'code', value: params.data.code
        });
    }

    return [
        code
    ]
})




