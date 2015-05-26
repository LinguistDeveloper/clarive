(function(params){
    var common = Cla.dashlet_common(params);
    var data = params.data;
    var days = new Ext.ux.form.SpinnerField({ 
        value: data.days, 
        name: "days",
        fieldLabel: _("Number of days before today to list jobs")
    });

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
                  Baseliner.ci_box({ name:'bls', fieldLabel:_('Which bls do you want to see'), allowBlank: true,'class':'bl', valueField: 'name', value: data.bls, force_set_value: true, singleMode: false })
              ]
            },
            { layout:'form', 
              columnWidth: .50, 
              bodyStyle: 'background:transparent;',
              items: [
                  days
              ]
            }
          ]
        }
    ])
})




