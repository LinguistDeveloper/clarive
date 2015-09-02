(function(params){
    var common = params.common_options || Cla.dashlet_common(params);

    var data = params.data;
    return common.concat([
        {
            xtype: 'label',
            text: _('Baseline list'),
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
              columnWidth: 1, 
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




