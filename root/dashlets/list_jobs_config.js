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
        states,
        { xtype : "checkbox", name : "not_in_states", checked: data.not_in_states=='on' ? true : false, boxLabel : _('Exclude selected states?') },
        Baseliner.ci_box({ name:'bls', fieldLabel:_('Which bls do you want to see'), allowBlank: true,'class':'bl', value: data.bls, force_set_value: true, singleMode: false }),
        { xtype:'numberfield', fieldLabel: _('Maximum number of jobs to list'), allowBlank: false, name: 'limit', value: data.limit || 100}
    ])
})




