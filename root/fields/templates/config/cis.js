(function(params){
    var data = params.data || {};
    if (data.var_ci_role == 'CI') data.var_ci_role = _('All');
    var ret = Baseliner.generic_fields(data);
    var value_type = Baseliner.generic_list_fields(data);
    Cla.help_push({ title:_('CI Combo'), path:'rules/palette/fieldlets/ci-combo' });
    ret.push(value_type);
    var ci_role_field = new Ext.form.Field({
        name: 'ci_role',
        xtype: "textfield",
        value: data.ci_role || ''
    });
    ci_role_field.hide();
    var ci_class_field = new Ext.form.Field({
        name: 'ci_class',
        xtype: "textfield",
        value: data.ci_class || ''
    });
    ci_class_field.hide();


    var roles_store = new Ext.data.JsonStore({
        root: 'data',
        allowBlank: false,
        remoteSort: true,
        totalProperty: 'totalCount',
        id: 'id',
        baseParams: Ext.apply({  start: 0, limit: 9999 }, this.baseParams ),
        url: '/ci/roles',
        fields: [ 'role', 'name' ]
    });

   var ci_store = new Ext.data.JsonStore({
        root: 'data',
        remoteSort: true,
        totalProperty: 'totalCount',
        id: 'id',
        baseParams: Ext.apply({  start: 0, limit: 9999 }, this.baseParams ),
        url: '/ci/classes',
        fields: [ 'name', 'classname' ],
    });
    ci_store.on('load', function(){
        ci_class_box.setValue(data.ci_class_box);
    });

    var default_store = new Baseliner.store.CI({
        baseParams: Ext.apply({ params:{'class': ci_class_field.value, no_vars: 1}})
    });

    default_store.on('load', function(){
        default_box.setValue(data.default_value);
        default_store.baseParams.class = ci_class_field.value;
    });

    var class_selected = false;
    if (data.var_ci_role == 'CI') data.var_ci_role = _('All');

    var role_box_multiselect = new Cla.SuperBox({
        deal_combo_change: function(obj){
            ci_role_field.setValue('');
            var selected = [];
            for(var i= 0; i<obj.usedRecords.items.length; i++){
                var temp = obj.usedRecords.items[i].data.role;
                selected.push(temp);
            }
            ci_role_field.setValue(selected);
            if(class_selected){
                ci_store.load({params:{'role': ci_role_field.value, process_array: 1}});
             }
        },
        store: roles_store,
        name: 'var_ci_role',
        xtype: 'combo',
        fieldLabel: _('Roles'),
        triggerAction: 'all',
        valueField: 'name',
        displayField: 'name',
        singleMode: false,
        value: data.var_ci_role || _('All'),
        allowBlank: Boolean(ci_class_field.value),
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

    var ci_class_box = new Baseliner.SuperBox({
        deal_combo_change: function(obj){
            ci_class_field.setValue('');
            var selected = [];
            for(var i= 0; i<obj.usedRecords.items.length; i++){
                var temp = obj.usedRecords.items[i].data.classname;
                selected.push(temp);
            }
            ci_class_field.setValue(selected);
            ci_role_field.setValue('');
            if (obj.usedRecords.items.length){
                Cla.enableDefaultBox(default_box);
                default_store.load({params:{'class': ci_class_field.value, process_array: 1}});
            } else {
                Cla.disableDefaultBox(default_box);
            }
            //role_box_multiselect.setValue('');
        },
        name: 'ci_class_box',
        xtype: 'combo',
        fieldLabel: _('CI class'),
        triggerAction: 'all',
        store: ci_store,
        valueField: 'name',
        displayField: 'name',
        singleMode: true,
        autoLoad: false,
        mode: 'local',
        value: data.ci_class_box,
        listeners:{
            'removeitem': function(obj){
                return this.deal_combo_change(obj);
            },
            'additem': function(obj){
                return this.deal_combo_change(obj);
            }
        }
    });

    var default_box = new Baseliner.DefaultBox({
        store: default_store,
        value: data.default_value
    });

    if(!ci_role_field.value && !ci_class_field.value || ci_role_field.value && !ci_class_field.value){
        role_box_multiselect.allowBlank = false;
        role_box_multiselect.show();
        ci_class_box.disable();
    }else if(ci_class_field.value){
        ci_store.load({params:{'role': ci_role_field.value, process_array: 1}});
        class_selected = true;
        role_box_multiselect.allowBlank = true;
        ci_class_box.allowBlank = false;
        ci_class_box.enable();
    }

    var store_display_mode = new Ext.data.SimpleStore({
        fields: ['display_mode', 'name'],
        data: [
            ['collection', _('Name')],
            ['bl', _('Baseline')],
            ['class', _('Class')],
            ['moniker', _('Moniker')]
        ]
    });

    var display_mode = new Ext.form.ComboBox({
        store: store_display_mode,
        displayField: 'name',
        value: data.display_mode || 'collection',
        valueField: 'display_mode',
        hiddenName: 'display_mode',
        name: 'display_mode',
        editable: false,
        mode: 'local',
        allowBlank: false,
        forceSelection: true,
        triggerAction: 'all',
        fieldLabel: _('Description'),
        emptyText: _('Select one'),
        autoLoad: true
    });

    ret.push([
        // { xtype:'hidden', name:'fieldletType', value: 'fieldlet.system.cis' },
        {
            xtype: 'container',
            layout: 'hbox',
            fieldLabel: _('Selection method'),
            items: [
                {
                    xtype: 'radiogroup',
                    items: [
                        { boxLabel: _('Role selection'), name: 'rdoMethod', inputValue: 'roleSelection', width: 20, checked: !ci_role_field.value && !ci_class_field.value || ci_role_field.value },
                        { boxLabel: 'Class selection', name: 'rdoMethod', width: 20, inputValue: 'classSelection', checked: ci_class_field.value }
                    ],
                    listeners: {
                        'change': function(rg,checked){
                            ci_class_box.setValue('');
                            if(checked.id == 'rdoRole'){
                                ci_class_box.allowBlank = true;
                                class_selected = false;
                                role_box_multiselect.allowBlank = false;
                               ci_class_box.disable();
                            }else{
                                ci_store.load({params:{'role': ci_role_field.value, process_array: 1}});
                                class_selected=true;
                                ci_class_box.allowBlank = false;
                                role_box_multiselect.allowBlank = true;
                                ci_class_box.enable();
                            }
                        }
                    }
                }
            ]
        },
        role_box_multiselect,
        ci_class_box,
        ci_role_field,
        ci_class_field,
        default_box,
        display_mode,
        { xtype:'checkbox', name:'show_class', fieldLabel:_('Show class'), value: data.show_class, checked: data.show_class ? true : false }
    ]);

    return ret;
})
