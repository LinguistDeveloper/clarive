(function(params){
    if( !params.rec ) params.rec = {};

    var grammar = new Ext.form.TextArea({ fieldLabel:_('Grammar'), name:'grammar', 
        height: 400,
        value: params.rec.grammar, anchor:'100%', 
        style:'font: 11px Consolas, Courier New, monotype' 
    });

    var grammar_class = new Baseliner.ComboSingleRemote({
        name: 'grammar_class',
        field: 'package',
        fields: [ 'package', 'ret' ],
        allowBlank: true,
        fieldLabel: _('Grammar Template'),
        url: '/ci/grammar/grammars',
        value: params.rec.grammar_class 
    });

    grammar_class.on('select', function(a,b,row){
       var ret = grammar_class.store.getAt(row).data.ret;
       var curr = grammar.getValue();
       if( Ext.isString(curr) && curr.length  > 0 ) {
           Baseliner.confirm( _loc('Replace current grammar with standard one?'), function(){
               grammar.setValue( ret );
           });
       } else {
           grammar.setValue( ret );
       }
    });

    var token_case = new Baseliner.ComboSingle({
        name: 'token_case',
        fieldLabel: _('Token Case'),
        data: [ 'case-sensitive', 'uppercase', 'lowercase' ],
        value: params.rec.token_case || 'case-sensitive'
    });
    
    return [
        { xtype:'textfield', fieldLabel:_('Options'), name:'regex_options', value: params.rec.regex_options || 'xmsi', anchor:'100%' },
        token_case,
        grammar_class,
        { xtype:'textfield', fieldLabel:_('Timeout'), name:'timeout', value: params.rec.timeout || '10', anchor:'100%' },
        { xtype:'textfield', fieldLabel:_('Path Capture'), name:'path_capture', 
               value: params.rec.path_capture || params.rec.module_fallback || '', anchor:'100%' }, // module_fallback kept for backwardity
        grammar
        //{ xtype:'panel', fieldLabel: _('Grammar'), height: 500, items: new Baseliner.CodeMirror({
               //height: 500, value: params.rec.grammar, name:'grammar', editor: { onChange:function(){ alert(1) } } }) 
        //}
    ]
})
