(function(params){
    var common = Cla.dashlet_common(params);
    var data = params.data;
    var states_store = new Baseliner.JsonStore({ 
        id: 'id', 
        baseParams: {},
        root: 'data',
        autoLoad: true,
        url: '/job/states',
        fields: ['id','name'] 
    });

    var tpl2 = new Ext.XTemplate( '<tpl for=".">{name}</tpl>' );

    var states = new Ext.ux.form.SuperBoxSelect({
        msgTarget: 'under',
        addNewDataOnBlur: true, 
        triggerAction: 'all',
        store: states_store,
        mode: 'remote',
        fieldLabel: _('Select job in states'),
        typeAhead: true,
        name: 'states',
        displayField: 'name',
        hiddenName: 'states',
        valueField: 'id',
        displayFieldTpl: tpl2,
        value: data.states,
        extraItemCls: 'x-tag'
     });

    return common.concat([
        {
            xtype: 'label',
            text: _('Job selection criteria'),
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
                states,
                { xtype : "checkbox", name : "not_in_states", checked: data.not_in_states=='on' ? true : false, boxLabel : _('Exclude selected states?') }
              ]
            },
            { layout:'form', 
              columnWidth: .50, 
              bodyStyle: 'background:transparent;',
              items: [
                Baseliner.ci_box({ name:'bls', fieldLabel:_('Which bls do you want to see'), allowBlank: true,'class':'bl', value: data.bls, force_set_value: true, singleMode: false }),
                { xtype:'numberfield', fieldLabel: _('Maximum number of jobs to list'), allowBlank: false, name: 'limit', value: data.limit || 100}
              ]
            }
          ]
        }

    ])
})




