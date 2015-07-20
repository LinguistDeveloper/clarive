(function(params){
    var common = Cla.dashlet_common(params);
    var data = params.data;

    /*var limit = new Ext.ux.form.SpinnerField({ 
        value: data.limit,
        name: "limit",
        fieldLabel: _("Limit of records to animate")
    });*/




    var cstatus = new Baseliner.StatusBox({ name: 'statuses', fieldLabel: _('Select topics in statuses'), value: data.statuses || ''});
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });




    return common.concat([

        new Baseliner.ComboDouble({ fieldLabel: _('Background Color'), name:'background_color', value: data.background_color || '#FFFFFF', data: [
            ['#FFFFFF', _('White')],
            ['#000000',_('Black')]
          ] 
        }),
        new Baseliner.ComboDouble({ fieldLabel: _('Animation Start Mode'), name:'start_mode', value: data.start_mode || 'auto', data: [
            ['auto', _('Automatically')],
            ['manual', _('Manually')]
          ] 
        }),
        //{xtype: 'checkbox', id: 'anim_bucle', name: 'anim_bucle', boxLabel: 'anim_bucle', hideLabel: true, checked: true}
        { xtype : "checkbox", name : "anim_bucle", checked: data.anim_bucle=='on' ? true : false, boxLabel : _('Repit the animation') },
        //{ xtype : "checkbox", fieldLabel : _('Repit the animation'), name : "anim_bucle", checked: data.anim_bucle=='1' ? true : false },
        { xtype:'datefield', fieldLabel: _('Date from'), anchor:'100%', format:'Y-m-d', name: 'start_date', value: data.start_date },
        { xtype:'datefield', fieldLabel: _('Date to'), anchor:'100%', format:'Y-m-d', name: 'end_date', value: data.end_date },
        { xtype:'textfield', fieldLabel: _('Maximum Node'), name:'max_node', value:data.max_node || 0 },
        { xtype:'textfield', fieldLabel: _('Minimum Node Category'), name:'min_node', value:data.min_node || 0 },
        new Baseliner.ComboDouble({
            name: 'controller',
            fieldLabel: _('Node groupping'),
            anchor: '40%',
            data: [ ['/swarm/activity_by_category',_('Category')], ['/swarm/activity_by_status',_('Status')] ],  // patch?
            value: data.controller || '/swarm/activity_by_category'
        }),
        //limit


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
                { xtype : "checkbox", name : "not_in_status", checked: data.not_in_status=='on' ? true : false, boxLabel : _('Exclude selected statuses?') }
              ]
            }
          ]
        }



    ])
})





