(function(params){
    return [
        { xtype:'textfield', fieldLabel:_('Options'), name:'regex_options', value: params.rec.regex_options || 'xmsi', anchor:'100%' },
        { xtype:'textfield', fieldLabel:_('Timeout'), name:'timeout', value: params.rec.timeout || '10', anchor:'100%' },
        { xtype:'textfield', fieldLabel:_('Path Capture'), name:'path_capture', 
               value: params.rec.path_capture || params.rec.module_fallback || '', anchor:'100%' }, // module_fallback kept for backwardity
        { xtype:'textarea', fieldLabel:_('Grammar'), name:'grammar', 
            height: 400,
            value: params.rec.grammar, anchor:'100%', 
            style:'background-color: #000, color: #eee; font: 11px Consolas, Courier New, monotype' 
        }
        //{ xtype:'panel', fieldLabel: _('Grammar'), height: 500, items: new Baseliner.CodeMirror({
               //height: 500, value: params.rec.grammar, name:'grammar', editor: { onChange:function(){ alert(1) } } }) 
        //}
    ]
})
