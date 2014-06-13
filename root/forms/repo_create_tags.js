(function(params){
    return [
        new Baseliner.ComboDouble({ 
            fieldLabel: _('Existing Tags'), name:'existing', value: 'detect', 
            data: [ 
              ['detect',_("Don't replace existing tags")], 
              ['replace',_('Reset all tags')]
            ]
        }),
        { xtype:'textarea', height: 50, fieldLabel:_('Commit or Ref'), name:'ref', value:'' }
    ]
});
