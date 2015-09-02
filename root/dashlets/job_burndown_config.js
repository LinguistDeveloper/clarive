(function(params){
    var common = params.common_options || Cla.dashlet_common(params);
    
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
                { xtype:'textfield', fieldLabel: _('Days Average'), name: 'days_avg', value: data.days_avg?data.days_avg:'1000D' }
              ]
            },
            { layout:'form', 
              columnWidth: .50, 
              bodyStyle: 'background:transparent;',
              items: [
                { xtype:'textfield', fieldLabel: _('Days Last'), name: 'days_last', value: data.days_last?data.days_last:'100D' }
              ]
            }
          ]
        }

    ])
})




