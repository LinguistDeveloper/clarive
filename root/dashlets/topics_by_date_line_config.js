(function(params){
    var data = params.data || {};


    var cstatus = new Baseliner.StatusBox({ name: 'statuses', fieldLabel: _('Select topics in statuses'), value: data.statuses || ''});
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });

    var common = params.common_options || Cla.dashlet_common(params);

    var days_from = new Ext.ux.form.SpinnerField({ 
        value: data.days_from, 
        name: "days_from",
        anchor:'100%',
        fieldLabel: _("Shift in days from today to start timeline. 0 or blank means one day")
    });

    var days_until = new Ext.ux.form.SpinnerField({ 
        value: data.days_until, 
        name: "days_until",
        anchor:'100%',
        fieldLabel: _("Shift in days from today to end timeline. 0 or blank means today")
    });

    // var spinner = Ext.create('Ext.field.Spinner', {
    //     label: 'Spinner Field',
    //     minValue: 0,
    //     maxValue: 100,
    //     increment: 2,
    //     cycle: true,
    //     name: _('Days from now to filter data')
    // });

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
              columnWidth: .70, 
              bodyStyle: 'background:transparent;',
              items: [
                ccategory,
                cstatus,
                { xtype : "checkbox", name : "not_in_status", checked: data.not_in_status=='on' ? true : false, boxLabel : _('Exclude selected statuses?') },
                { xtype:'textfield', anchor:'100%', fieldLabel: _('Advanced JSON/MongoDB condition for filter'), name: 'condition', value: data.condition }
              ]
            },
            { layout:'form', 
              columnWidth: .30, 
              bodyStyle: 'background:transparent;',
              items: [
                days_from,
                days_until
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
                { xtype:'textfield', anchor:'100%', fieldLabel: _('Date field in topics to use as X axis'), name: 'date_field', value: data.date_field },
                new Baseliner.ComboDouble({ fieldLabel: _('Data grouped by'), name:'group', value: data.group, data: [
                    ['day', _('Day')],
                    ['week', _('Week')],
                    ['month', _('Month')],
                    ['quarter', _('Quarter')],
                    ['year', _('Year')]
                  ] 
                }),
                ]
            },
            { layout:'form', 
              columnWidth: .5, 
              bodyStyle: 'background:transparent;',
              items: [
                new Baseliner.ComboDouble({ anchor: '100%', fieldLabel: _('Chart will be shown as ...'), name:'type', value: data.type || 'area', data: [
                    ['area', _('Area')],
                    ['stack-area', _('Stacked area')],
                    ['stack-area-step', _('Area step')],
                    ['line', _('Line')],
                    ['bar', _('Bar')], 
                    ['stack-bar', _('Stacked bar')],
                    ['scatter', _('Scatter')]
                  ] 
                })
              ]
            }
          ]
        }
    ]);
})
