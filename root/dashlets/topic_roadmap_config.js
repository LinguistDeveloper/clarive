(function(params){
    var data = params.data || {};

    var bl_combo = new Baseliner.model.SelectBaseline({ value: data.bl, fieldLabel: _('Environments') });
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });

    var common = Cla.dashlet_common(params);

    var weeks_from = new Ext.ux.form.SpinnerField({ 
        value: data.weeks_from==undefined?10:data.weeks_from, 
        name: "weeks_from",
        anchor:'100%',
        fieldLabel: _("Number of weeks back from today to start")
    });

    var weeks_until = new Ext.ux.form.SpinnerField({ 
        value: data.weeks_until==undefined?10:data.weeks_until, 
        name: "weeks_until",
        anchor:'100%',
        fieldLabel: _("Number of weeks after today to end")
    });

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
                bl_combo,
                { xtype : "checkbox", name : "not_in_bls", checked: data.not_in_bls=='on' ? true : false, boxLabel : _('Exclude selected environments?') },
                ccategory,
                { xtype : "checkbox", name : "not_in_category", checked: data.not_in_category=='on' ? true : false, boxLabel : _('Exclude selected categories?') },
                { xtype:'textfield', anchor:'100%', fieldLabel: _('Advanced JSON/MongoDB condition for filter'), name: 'condition', value: data.condition }
              ]
            },
            { layout:'form', 
              columnWidth: .30, 
              bodyStyle: 'background:transparent;',
              items: [
                weeks_from,
                weeks_until
              ]
            }
          ]
        }
    ]);
})

