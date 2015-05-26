(function(params){
    var data = params.data || {};

    var days_from = new Ext.ux.form.SpinnerField({ 
        value: data.days_from, 
        name: "days_from",
        anchor:'100%',
        fieldLabel: _("Shift in days from today to show in chart. 0 or blank means today")
    });

    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });
    var date_type =  new Baseliner.ComboDouble({ allowBlank: false, fieldLabel: _('Date to be shown'), name:'date_type', value: data.date_type || 'today', data: [
        ['today', _('Today')],
        ['yesterday', _('Yesterday')],
        ['date', _('Date')]
      ] 
    });

    var common = Cla.dashlet_common(params);

    return common.concat([
        {
            xtype: 'label',
            text: _('Topics selection criteria'),
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
                ccategory
              ]
            }
          ]
        },
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
              columnWidth: .5, 
              bodyStyle: 'background:transparent;',
              items: [
                { xtype:'textfield', anchor:'100%',allowBlank: false, fieldLabel: _('Date field with scheduled start date'), name: 'date_field', value: data.date_field },
                new Baseliner.ComboDouble({ fieldLabel: _('Chart will be shown as ...'), name:'type', value: data.type || 'area', data: [
                    ['area', _('Area')],
                    ['stack-area-step', _('Area step')],
                    ['line', _('Line')],
                    ['bar', _('Bar')], 
                    ['scatter', _('Scatter')]
                  ] 
                })              
              ]
            },
            { layout:'form', 
              columnWidth: .5, 
              bodyStyle: 'background:transparent;',
              items: [
                days_from
              ]
            }
          ]
        }
    ]);
})
