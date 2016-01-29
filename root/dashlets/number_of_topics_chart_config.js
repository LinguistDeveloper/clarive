(function(params){
    var data = params.data || {};


    var cstatus = new Baseliner.StatusBox({ name: 'statuses', fieldLabel: _('Select topics in statuses'), value: data.statuses || ''});
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });

    var common = params.common_options || Cla.dashlet_common(params);

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
              columnWidth: .5, 
              bodyStyle: 'background:transparent;',
              items: [
                new Baseliner.ComboSingle({ forceSelection: false, allowBlank: false, fieldLabel: _('Select or type the grouping field'), editable: true, name: 'group_by', value: data.group_by || 'category.name', data: [
                    ['category.name'],
                    ['category_status.name'],
                    ['created_by'],
                    ['modified_by']
                  ] 
                }),
                { xtype:'textfield', anchor:'100%', fieldLabel: _('Number field to group by'), name: 'numberfield_group', value: data.numberfield_group || ''},
                new Baseliner.ComboDouble({ fieldLabel: _('Show grouping field number as...'), name:'result_type', value: data.result_type || 'count', data: [
                    ['count', _('Count')],
                    ['avg', _('Average')],
                    ['sum', _('Sum Total')],
                    ['min', _('MIN')],
                    ['max', _('MAX')]
                  ]
                })
              ]
            },
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
                { xtype:'numberfield', anchor:'100%', fieldLabel: _('Minimum % to group series in Others group'), name: 'group_threshold', value: data.group_threshold || 5}
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
                { xtype:'textfield', anchor: '100%', fieldLabel: _('Advanced JSON/MongoDB condition for filter'), name: 'condition', value: data.condition }
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
