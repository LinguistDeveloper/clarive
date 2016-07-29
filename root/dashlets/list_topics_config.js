(function(params){
    var data = params.data || {};
    var cstatus = new Baseliner.StatusBox({ name: 'statuses', fieldLabel: _('Select topics in statuses'), value: data.statuses || ''});
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });
    var common = params.common_options || Cla.dashlet_common(params);
    var store_values = new Ext.data.SimpleStore({
        fields: ['assigned_to', 'name'],
        data:[
            [ 'any', _('Any') ],
            [ 'current', _('Current') ],
        ]
    });

    var value_combo = new Ext.form.ComboBox({
        store: store_values,
        displayField: 'name',
        value: data.assigned_to,
        valueField: 'assigned_to',
        hiddenName: 'assigned_to',
        name: 'assigned_to',
        editable: false,
        mode: 'local',
        forceSelection: true,
        triggerAction: 'all',
        fieldLabel: _('User assigned to topics'),
        autoLoad: true,
        anchor: '100%',
    });

    return common.concat([
        {
            xtype: 'label',
            text: _('General control'),
            style: {
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
                { xtype:'textarea', anchor:'100%', fieldLabel: _('List of fields to view in grid'), name: 'fields', value: data.fields },
                { xtype:'numberfield', fieldLabel: _('Maximum number of topics to list'), allowBlank: false, name: 'limit', value: data.limit || 100},
                { xtype:'textfield', fieldLabel: _('Sort By'), name: 'sort', value: data.sort },
                new Baseliner.ComboDouble({ forceSelection: true, allowBlank: false, fieldLabel: _('Sort Order'), editable: false, name: 'dir', value: data.dir || '', data: [
                    ['desc', _('DESC')],
                    ['asc', _('ASC')]
                  ]
                }),
                { xtype : "checkbox", name : "show_totals", checked: data.show_totals=='on' ? true : false, boxLabel : _('Show totals row?') }
              ]
            }
          ]
        },
        {
            xtype: 'label',
            text: _('Topics selection criteria'),
            style: {
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
                ccategory,
                cstatus,
                { xtype : "checkbox", name : "not_in_status", checked: data.not_in_status=='on' ? true : false, boxLabel : _('Exclude selected statuses?') },
                value_combo,
                { xtype:'textfield', vtype: 'json', anchor:'100%', fieldLabel: _('Advanced JSON/MongoDB condition for filter'), name: 'condition', value: data.condition }
              ]
            }
          ]
        }
    ]);
})
