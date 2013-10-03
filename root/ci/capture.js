(function(params){
    return [
        { xtype:'textfield', fieldLabel:_('Options'), name:'regex_options', value: params.rec.regex_options || 'xmsi', anchor:'100%' },
        { xtype:'textfield', fieldLabel:_('Timeout'), name:'timeout', value: params.rec.timeout || '10', anchor:'100%' },
        new Baseliner.ComboSingle({ fieldLabel: _('Parse Type'), name:'parse_type', data: ['Source', 'Path'] }), 
        { xtype:'textarea', fieldLabel:_('Regex'), name:'regex', 
            height: 400,
            value: params.rec.regex, anchor:'100%', 
            style:'font: 11px Consolas, Courier New, monotype' 
        }
    ]
})

