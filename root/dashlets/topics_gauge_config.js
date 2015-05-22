(function(params){
    var data = params.data || {};


    var cstatus = new Baseliner.StatusBox({ name: 'statuses', fieldLabel: _('Use these statuses'), value: data.statuses || ''});
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Use these categories'), value: data.categories || ''  });

    var common = Cla.dashlet_common(params);

    var days_from = new Ext.ux.form.SpinnerField({ 
        value: data.days_from, 
        anchor: '100%',
        name: "days_from",
        fieldLabel: _("Shift in days from today to start timeline. 0 or blank means one day")
    });

    var days_until = new Ext.ux.form.SpinnerField({ 
        value: data.days_until, 
        anchor: '100%',
        name: "days_until",
        fieldLabel: _("Shift in days from today to end timeline. 0 or blank means today")
    });

    var green = new Ext.ux.form.SpinnerField({ 
        value: data.green,
        anchor: '100%',
        name: "green",
        fieldLabel: _("Switch to YELLOW when value reaches")
    });

    var yellow = new Ext.ux.form.SpinnerField({ 
        value: data.yellow, 
        anchor: '100%',
        name: "yellow",
        fieldLabel: _("Switch to RED when value reaches")
    });

    var start = new Ext.ux.form.SpinnerField({ 
        value: data.start || 0,
        allowBlank: false,
        anchor: '100%',
        name: "start",
        fieldLabel: _("START value for gauge"),
        emptyText: 'Default = 0 (see reverse)'
    });

    var end = new Ext.ux.form.SpinnerField({ 
        value: data.end, 
        anchor: '100%',
        name: "end",
        fieldLabel: _("END value for gauge"),
        emptyText: 'Default = max returned value or YELLOW + 20% (see reverse)'
    });

    return common.concat([
        {
            xtype: 'label',
            text: _('General gauge'),
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
                    green,
                    yellow,
                    {
                      xtype: 'label',
                      text: _('* Gauge start color is GREEN'),
                      style: {
                          // 'margin': '10px',
                          'color': '#888888'
                      }
                    },
                    {
                        xtype: 'checkbox',
                        name: "reverse",
                        fieldLabel: _("Reverse gauge"),
                        checked: data.reverse == undefined ? false : data.reverse,
                        allowBlank: 1
                    },
                    {
                      xtype: 'label',
                      text: _('(* default color = RED, switch away from yellow means GREEN)'),
                      style: {
                          // 'margin': '10px',
                          'color': '#888888'
                      }
                    }
              ]
            },
            { layout:'form', 
              columnWidth: .50, 
              bodyStyle: 'background:transparent;',
              items: [
                    start,
                    end,
                    new Baseliner.ComboDouble({ fieldLabel: _('Which data you want to collect'), name:'result_type', value: data.result_type || 'avg', data: [
                        ['avg', _('Average')],
                        ['min', _('Minimum')],
                        ['max', _('Maximum')],
                        ['count', _('Count')],
                        ['sum', _('Total sum')]
                      ] 
                    })

              ]
            }
          ]
        },
        {
            xtype: 'label',
            text: _('Topic selection criteria'),
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
                ccategory,
                cstatus,
                { xtype : "checkbox", name : "not_in_status", checked: data.not_in_status=='on' ? true : false, boxLabel : _('Exclude statuses above') },
                { xtype:'textfield', fieldLabel: _('Advanced JSON/MongoDB condition for filter'), name: 'condition', value: data.condition, anchor: '100%' }
              ]
            },
            { layout:'form', 
              columnWidth: .50, 
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
            text: _('Data collection'),
            style: {
                // 'margin': '10px',
                'font-size': '12px',
                'font-weight': 'bold'
            }
        },
        { xtype:'panel', 
          hideBorders: true, 
          layout:'column', 
          bodyStyle: 'margin: 3px; padding: 5px 3px;background:transparent;',
          items:[
            { layout:'form', 
              columnWidth: .50, 
              bodyStyle: 'background:transparent;',
              items: [
                { xtype:'textfield', anchor: '100%', fieldLabel: _('Date field in topics to use as start'), name: 'date_field_start', value: data.date_field_start },
                { xtype:'textfield', anchor: '100%', fieldLabel: _('Date field in topics to use as end'), name: 'date_field_end', value: data.date_field_end },
                new Baseliner.ComboDouble({ anchor: '100%',fieldLabel: _('The result will be shown in'), name:'units', value: data.units || 'day', data: [
                    ['minute', _('Minutes')],
                    ['hour', _('Hours')],
                    ['day', _('Days')],
                    ['month', _('Months')]
                  ] 
                }),
                {
                    xtype: 'checkbox',
                    name: "end_remaining",
                    fieldLabel: _("Use END date as remaining"),
                    checked: data.end_remaining == undefined ? false : data.end_remaining,
                    allowBlank: 1
                }
              ]
            },
            { layout:'form', 
              columnWidth: .50, 
              bodyStyle: 'background:transparent;',
              items: [
                { xtype:'textfield', anchor: '100%',fieldLabel: _('Numeric field in topics to use as data (leave dates blank)'), name: 'numeric_field', value: data.numeric_field },
                new Baseliner.ComboDouble({ anchor: '100%',fieldLabel: _('The field data units are'), name:'input_units', value: data.input_units || 'day', data: [
                    ['second', _('Seconds')],
                    ['minute', _('Minutes')],
                    ['hour', _('Hours')],
                    ['day', _('Days')],
                    ['number',_('Number')]
                  ] 
                })
              ]
            }
          ]
        },
    ]);
})
