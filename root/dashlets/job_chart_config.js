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
        new Baseliner.ComboDouble({ fieldLabel: _('Chart will be shown as ...'), name:'type', value: data.type || 'pie', data: [
            ['pie', _('Pie')],
            ['donut', _('Donut')],
            ['bar', _('Bar')]
          ] 
        }),
        Baseliner.ci_box({ name:'bls', fieldLabel:_('Which bls do you want to see'), allowBlank: true,
            'class':'bl', value: data.bls, force_set_value: true, singleMode: false })
    ])
})




