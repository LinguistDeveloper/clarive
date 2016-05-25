(function(params) {
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    var value_type = Baseliner.generic_list_fields(data);
    ret.push(value_type);

    Cla.help_push({ title:_('Project combo'), path:'rules/palette/fieldlets/project-combo' });

    var collection = new Ext.form.Hidden({
        name: 'collection',
        value: data.collection
    });

    var ci_class_field = new Ext.form.Field({
        name: 'ci_class',
        xtype: "textfield",
        value: data.ci_class || ''
    });
    ci_class_field.hide();

    var ci_store = new Ext.data.JsonStore({
        root: 'data',
        remoteSort: true,
        totalProperty: 'totalCount',
        id: 'id',
        baseParams: Ext.apply({
            start: 0,
            limit: 9999,
            role: 'Baseliner::Role::CI::Project'
        }, this.baseParams),
        url: '/ci/classes',
        fields: ['name', 'classname'],
        listeners: {
            'load': function() {
                //console.log(this);
            }
        }
    });

    self.default_store = new Baseliner.store.CI({
        baseParams: Ext.apply({ params:{'class': collection.value, no_vars: 1, filter: self.filter}})
    });

    default_store.on('load', function(){
        default_box.setValue(data.default_value);
    });

    var ci_class_box = new Baseliner.SuperBox({
        deal_combo_change: function(obj){
            default_box.setValue('');
            ci_class_field.setValue('');
            var selected = [];
            for(var i= 0; i<obj.usedRecords.items.length; i++){
                var temp = obj.usedRecords.items[i].data.classname;
                selected.push(temp);
            }
            ci_class_field.setValue(selected);
            if (obj.usedRecords.items.length){
                default_store.reload({params:{'class': ci_class_field.value, process_array: 1}});
                default_box.enable();
            }else{
                default_box.disable();
            }
            this.focus();
        },
        name: 'ci_class_box',
        xtype: 'combo',
        fieldLabel: _('CI class'),
        store: ci_store,
        triggerAction: 'all',
        valueField: 'name',
        allowBlank: false,
        displayField: 'name',
        singleMode: true,
        mode: 'remote',
        value: data.collection || 'project',
        listeners:{
            'removeitem': function(obj){
                return this.deal_combo_change(obj);
             },
             'additem': function(obj){
                return this.deal_combo_change(obj);
             },
             'change': function(elem, value) {
                collection.setValue(value);
            }

        }
    });

    var store_display_mode = new Ext.data.SimpleStore({
        fields: ['display_mode', 'name'],
        data: [
            ['none', _('Name')],
            ['description', _('Description')],
            ['baseline', _('Baseline')],
            ['moniker', _('Moniker')],
        ]
    });

    var display_mode = new Ext.form.ComboBox({
        store: store_display_mode,
        displayField: 'name',
        value: data.display_mode || 'none',
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


    var default_box = new Baseliner.SuperBox({

        name: 'default_value',
        xtype: 'combo',
        fieldLabel: _('Default Value'),
        triggerAction: 'all',
        store: default_store,
        valueField: 'mid',
        displayField: 'name',
        singleMode: true,
        disabled: true,
        mode: 'local',
        value: data.default_value,

    });


    ret.push([
        ci_class_box,
        collection,
        default_box,
        ci_class_field, {
            xtype: 'textfield',
            fieldLabel: _('Roles (comma separated)'),
            name: 'roles',
            value: data.roles || ''
        },
        display_mode,
    ]);
    return ret;
})
