(function(params){
    var common = Cla.dashlet_common(params);
    var data = params.data;
    return common.concat([
        {
            xtype: 'label',
            text: _('Chart options'),
            style: {
                // 'margin': '10px',
                'font-size': '12px',
                'font-weight': 'bold'
            }
        },
        { xtype:'panel', 
          hideBorders: true, 
          layout:'column', 
          bodyStyle: 'margin: 3px; padding: 3px 3px;background:transparent;',
          items:[
            { layout:'form', 
              columnWidth: .50, 
              bodyStyle: 'background:transparent;',
              items: [
                    new Baseliner.ComboDouble({ fieldLabel: _('Period to be shown. Last ...'), name:'period', value: data.period, data: [
                        ['1D', _('Day')],
                        ['7D', _('Week')],
                        ['1M', _('Month')],
                        ['3M', _('Quarter')],
                        ['1Y', _('Year')]
                      ] 
                    }),
                    new Baseliner.ComboDouble({ fieldLabel: _('Chart will be shown as ...'), name:'type', value: data.type || 'donut', data: [
                        ['pie', _('Pie')],
                        ['donut', _('Donut')],
                        ['bar', _('Bar')]
                      ] 
                    })
              ]
            },
            { layout:'form', 
              columnWidth: .50, 
              bodyStyle: 'background:transparent;',
              items: [
                    Baseliner.ci_box({ name:'bls', fieldLabel:_('Which bls do you want to see'), allowBlank: true,
                        'class':'bl', value: data.bls, force_set_value: true, singleMode: false })
              ]
            }
          ]
        }

    ])
})




