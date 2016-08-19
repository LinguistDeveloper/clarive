(function(params){
    Cla.help_push({ title:_('Sleep for a number of seconds'), path:'rules/palette/job/sleep' });
    var data = params.data || {};
    return [
        { xtype:'textfield', fieldLabel: _('Seconds'), name: 'seconds', value: params.data.seconds }
    ]
})
