(function(params){
    var data = params.data || {};

    var days_from_format_date = new Ext.form.DateField({
      fieldLabel: _('Shift in days from today to show in chart.'),
      name: 'days_from_format_date',
      value: data.days_from_format_date,
      format: 'Y-m-d',
      width: 165,
      hidden: true
    });
    days_from_format_date.hide();

    var days_from = new Ext.ux.form.SpinnerField({
        value: data.days_from,
        name: "days_from",
        anchor:'100%',
        fieldLabel: _("Shift in days before today to show in chart. 0 or blank means today"),
        hidden: true,
        maxValue: '0',
        height : 100,
        autoWidth: true
    });
    days_from.hide();

    if(data.rdoMethod === 'dateselection'){
      days_from_format_date.show();
    }else{
      days_from.show();
    };

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
                      { id: 'dateselection', boxLabel: _('Date'), name: 'rdoMethod', inputValue: 'dateselection', checked: data.rdoMethod === 'dateselection'},
                      { id: 'numberselection', boxLabel: _('Number'), name: 'rdoMethod', width: 20, inputValue: 'numberSelection', checked: data.rdoMethod === 'numberSelection' }

                  ],
                  listeners: {
                      'change': function(rg,checked){

                            if(checked.id == 'dateselection'){

                                days_from.hide();
                                days_from_format_date.setValue(days_from_format_date.originalValue);
                                days_from_format_date.show();
                                days_from.setValue('');

                            }else if (checked.id == 'numberselection'){

                                days_from.show();
                                days_from.setValue(days_from.originalValue);
                                days_from_format_date.hide();
                                days_from_format_date.setValue('');

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
                selector,
                days_from_format_date,
                days_from
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
