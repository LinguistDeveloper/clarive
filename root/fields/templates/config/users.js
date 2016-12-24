(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    Cla.help_push({ title:_('User Combo'), path:'rules/palette/fieldlets/user-combo' });
    var value_type = Baseliner.generic_list_fields(data);
    ret.push(value_type);

    var ci_role_field = new Ext.form.Field({
        name: 'ci_role',
        xtype: "textfield",
        value: data.ci_role || '',
        hidden: true
    });

    var roles_store = new Ext.data.JsonStore({
    root: 'data',
        remoteSort: true,
        totalProperty: 'totalCount',
        id: 'id',
        baseParams: Ext.apply({  start: 0, limit: 9999 }, this.baseParams ),
        url: '/role/all',
        fields: ['id' ,'role']
    });

    var role_box_multiselect = new Cla.SuperBox({
        deal_combo_change: function(obj){
            ci_role_field.setValue('');
            var selected = [];
            for(var i= 0; i<obj.usedRecords.items.length; i++){
                var temp = obj.usedRecords.items[i].data.role;
                selected.push(temp);
            }
            ci_role_field.setValue(selected);
        },
        store: roles_store,
        name: 'roles_filter',
        xtype: 'combo',
        fieldLabel: _('Roles'),
        triggerAction: 'all',
        valueField: 'id',
        displayField: 'role',
        singleMode: false,
        value: data.roles_filter,
        mode: 'remote',
        listeners:{
            'removeitem': function(obj){
                return this.deal_combo_change(obj);
            },
            'additem': function(obj){
                return this.deal_combo_change(obj);
            }
        }
    });

    ret.push(role_box_multiselect);

    return ret;
})
