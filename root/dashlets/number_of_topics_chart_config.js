(function(params){
    var data = params.data || {};


    var cstatus = new Baseliner.StatusBox({ name: 'statuses', fieldLabel: _('Select topics in statuses'), value: data.statuses || ''});
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });

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
                ccategory,
                cstatus,
                { xtype : "checkbox", name : "not_in_status", checked: data.not_in_status=='on' ? true : false, boxLabel : _('Exclude selected statuses?') },
                { xtype:'textfield', anchor: '100%', fieldLabel: _('Advanced JSON/MongoDB condition for filter'), name: 'condition', value: data.condition }
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
                new Baseliner.ComboDouble({ fieldLabel: _('Chart will be shown as ...'), name:'type', value: data.type || 'donut', data: [
                    ['pie', _('Pie')],
                    ['donut', _('Donut')],
                    ['bar', _('Bar')]
                  ] 
                }),
                new Baseliner.ComboSingle({ forceSelection: false, allowBlank: false, fieldLabel: _('Select or type the grouping field'), editable: true, name: 'group_by', value: data.group_by || 'category.name', data: [
                    ['category.name'],
                    ['category_status.name'],
                    ['created_by'],
                    ['modified_by']
                  ] 
                })
              ]
            },
            { layout:'form', 
              columnWidth: .5, 
              bodyStyle: 'background:transparent;',
              items: [
                { xtype:'numberfield', fieldLabel: _('Minimum % to group series in Others group'), name: 'group_threshold', value: data.group_threshold || 5}
              ]
            }
          ]
        }

        // {
        //     xtype: 'radiogroup',
        //     name: 'group_by',
        //     anchor:'50%',
        //     fieldLabel: _('Number of topics grouped by ...'),
        //     defaults: {xtype: "radio",name: "group_by"},
            // items: [
            //     {boxLabel: _('Category'), inputValue: 'topics_by_category', checked: data.group_by  == 'topics_by_category'},
            //     {boxLabel: _('Status'), inputValue: 'topics_by_status', checked: data.group_by == undefined || data.group_by == 'topics_by_status'}
            // ]
        // }
    ]);
})
