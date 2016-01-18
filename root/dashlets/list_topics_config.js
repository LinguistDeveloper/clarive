(function(params){
    var data = params.data || {};


    var cstatus = new Baseliner.StatusBox({ name: 'statuses', fieldLabel: _('Select topics in statuses'), value: data.statuses || ''});
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });

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
              columnWidth: 1, 
              bodyStyle: 'background:transparent;',
              items: [
                { xtype:'textfield', anchor:'100%', fieldLabel: _('List of fields to view in grid'), name: 'fields', value: data.fields },
                { xtype:'numberfield', fieldLabel: _('Maximum number of topics to list'), allowBlank: false, name: 'limit', value: data.limit || 100},
                { xtype:'textfield', fieldLabel: _('Sort By'), name: 'sort', value: data.sort },
                new Baseliner.ComboSingle({ forceSelection: true, allowBlank: false, fieldLabel: _('Sort Order'), editable: false, name: 'dir', value: data.dir || '', data: [
                    [_('DESC')],
                    [_('ASC')]
                  ] 
                }),
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
                ccategory,
                cstatus,
                { xtype : "checkbox", name : "not_in_status", checked: data.not_in_status=='on' ? true : false, boxLabel : _('Exclude selected statuses?') },
                // { xtype:'textfield', fieldLabel: _('User assigned to topics'), name: 'assigned_to', value: data.assigned_to },
                new Baseliner.ComboSingle({ forceSelection: false, allowBlank: true, fieldLabel: _('User assigned to topics'), editable: true, name: 'assigned_to', value: data.assigned_to || '', data: [
                    [''],
                    [_('Current')],
                    [_('Any')]
                  ] 
                }),
                { xtype:'textfield', anchor:'100%', fieldLabel: _('Advanced JSON/MongoDB condition for filter'), name: 'condition', value: data.condition }
              ]
            }
          ]
        }
    ]);
})
