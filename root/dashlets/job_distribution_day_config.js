(function(params){
    var common = Cla.dashlet_common(params);
    var data = params.data;
    return common.concat([
        new Baseliner.ComboDouble({ fieldLabel: _('Period to be shown. Last ...'), name:'period', value: data.period, data: [
            ['1D', _('Day')],
            ['7D', _('Week')],
            ['1M', _('Month')],
            ['3M', _('Quarter')],
            ['1Y', _('Year')]
          ] 
        }),
        new Baseliner.ComboDouble({ fieldLabel: _('Chart ty'), name:'type', value: data.type || 'area', data: [
            ['area', _('Area')],
            ['stack-area', _('Stacked area')],
            ['stack-area-step', _('Area step')],
            ['line', _('Line')],
            ['bar', _('Bar')], 
            ['stack-bar', _('Stacked bar')]
          ] 
        }),
        new Baseliner.ComboDouble({ fieldLabel: _('Do you want the data to be shown by bl?'), name:'joined', value: data.joined || '0', data: [
            ['1', _('No')],
            ['0', _('Yes')]
          ]
        }),
        Baseliner.ci_box({ name:'bls', fieldLabel:_('Which bls do you want to see'), allowBlank: true,
            'class':'bl', value: data.bls, force_set_value: true, singleMode: false })
    ])
})




