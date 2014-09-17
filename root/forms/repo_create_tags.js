(function(params){
    var data = params.data || {};
    return [
        new Baseliner.ComboDouble({ 
            fieldLabel: _('Existing Tags'), name:'existing', value: data.existing || 'detect', 
            data: [ 
              ['detect',_("Don't replace existing tags")], 
              ['replace',_('Reset all tags')]
            ]
        }),
        { xtype:'textarea', height: 50, fieldLabel:_('Commit or Ref'), name:'ref', value: data.ref || '' },
        { xtype:'textarea', height: 30, fieldLabel:_('Tag Filter'), name:'tag_filter', value: data.tag_filter || '' },
        { xtype:'label', height: 30, fieldLabel:'&nbsp;', style:{ 'font-size': '10px' }, text: _('Tags separated by commas') }
    ]
});
