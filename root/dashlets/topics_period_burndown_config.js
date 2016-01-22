(function(params){
    var data = params.data || {};
    var days_before = new Ext.ux.form.SpinnerField({ 
        value: data.days_before, 
        name: "days_before",
        hidden: true,
        autoWidth: true,
        anchor:'100%',
        fieldLabel: _("Shift in days before today to show in chart. 0 or blank means today")
    });

    var days_after = new Ext.ux.form.SpinnerField({ 
        value: data.days_after, 
        name: "days_after",
        hidden: true,
        autoWidth: true,
        anchor:'100%',
        fieldLabel: _("Shift in days after today to show in chart. 0 or blank means today")
    });

      var days_before_format_date = new Ext.form.DateField({
      fieldLabel: _('Shift in days from today to show in chart.'),
      name: 'days_before_format_date',
      value: data.days_before_format_date, 
      format: 'Y-m-d',
      width: 165,
      hidden: true
    });

      var days_after_format_date = new Ext.form.DateField({
      fieldLabel: _('Shift in days from today to show in chart.'),
      name: 'days_after_format_date',
      value: data.days_after_format_date, 
      format: 'Y-m-d',
      width: 165,
      hidden: true
    });

    var selector = new  Ext.Container({
          id: 'selection_method',
          layout: 'hbox',
          fieldLabel: _('Selection method to introduce the date'),
          value: data.selection_method,
          items: [
              {
                  xtype: 'radiogroup',
                  id: 'rdogrpMethod',
                  items: [
                      { id: 'dateselection', boxLabel: _('Date'), name: 'rdoMethod', inputValue: 'dateselection'},
                      { id: 'numberselection', boxLabel: 'Number', name: 'rdoMethod', width: 20, inputValue: 'numberSelection' }
                     
                  ],
                  listeners: {
                      'change': function(rg,checked){
                           
                            if(checked.id == 'dateselection'){
                                

                                days_before.hide();
                                days_after.hide();
                                days_before_format_date.show();
                                days_after_format_date.show();
                                  days_before.setValue('');
                                days_after.setValue('');
                                

                            }else if (checked.id == 'numberselection'){
                                
                                days_before_format_date.hide();
                                days_after_format_date.hide();
                                days_after.show();
                                days_before.show();
                                days_before_format_date.setValue('');
                                days_after_format_date.setValue('');


                            }
                       }
                   }
              }
          ]
        });
    


    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });
    var date_type =  new Baseliner.ComboDouble({ allowBlank: false, fieldLabel: _('Date to be shown'), name:'date_type', value: data.date_type || 'today', data: [
        ['today', _('Today')],
        ['yesterday', _('Yesterday')],
        ['date', _('Date')]
      ] 
    });

    var common = params.common_options || Cla.dashlet_common(params);

    return common.concat([
        {
            xtype: 'label',
            text: _('General control'),
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
                { xtype:'textfield', anchor:'100%',allowBlank: true, fieldLabel: _('Date field with scheduled start date'), name: 'date_field', value: data.date_field },
                new Baseliner.ComboDouble({ fieldLabel: _('Chart will be shown as ...'), name:'type', value: data.type || 'area', data: [
                    ['area', _('Area')],
                    ['stack-area-step', _('Area step')],
                    ['line', _('Line')],
                    ['bar', _('Bar')], 
                    ['scatter', _('Scatter')]
                  ] 
                }),
                new Baseliner.ComboDouble({ fieldLabel: _('Data grouped by'), name:'group', value: data.group, data: [
                    ['day', _('Day')],
                    ['week', _('Week')],
                    ['month', _('Month')],
                    ['quarter', _('Quarter')],
                    ['year', _('Year')]
                  ] 
                })
              ]
            },
            { layout:'form', 
              columnWidth: .5, 
              bodyStyle: 'background:transparent;',
              items: [
                selector,
                days_before,
                days_after,
                days_before_format_date,
                days_after_format_date
              ]
            }
          ]
        },
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
        }
    ]);
})
