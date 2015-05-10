(function(params){
    var common = Cla.dashlet_common(params);
    var data = params.data;
    return common.concat([
        new Baseliner.ComboDouble({ fieldLabel: _('Data grouped by'), name:'group', value: data.group, data: [
            ['day', _('Day')],
            ['week', _('Week')],
            ['month', _('Month')],
            ['quarter', _('Quarter')],
            ['year', _('Year')]
          ] 
        }),
        new Baseliner.ComboDouble({ fieldLabel: _('Chart type'), name:'type', value: data.type || 'area', data: [
            ['area', _('Area')],
            ['stack-area', _('Stacked area')],
            ['stack-area-step', _('Area step')],
            ['line', _('Line')],
            ['bar', _('Bar')], 
            ['stack-bar', _('Stacked bar')]
          ] 
        }),
        Baseliner.ci_box({ name:'bls', fieldLabel:_('Which bls you want to see'), allowBlank: true,
            'class':'bl', value: data.bls, force_set_value: true, singleMode: false })
    ])
})




