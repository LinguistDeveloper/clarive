(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    var value_type = Baseliner.generic_list_fields(data);
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

    

    var class_selected = false;
    

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
        value: data.var_ci_role,
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

    ret.push([ 
      {
          xtype: 'container',
          id: 'selection_method',
          layout: 'hbox',
          fieldLabel: _('Selection method'),
          items: [
              {
                  xtype: 'radiogroup',
                  id: 'rdogrpMethod',
                  items: [
                      { id: 'rdoRole', boxLabel: _('Role selection'), name: 'rdoMethod', inputValue: 'roleSelection', width: 20, checked: !ci_role_field.value && !ci_class_field.value || ci_role_field.value },
                      { id: 'rdoClass', boxLabel: 'Class selection', name: 'rdoMethod', width: 20, inputValue: 'classSelection', checked: ci_class_field.value }
                  ],
                  listeners: {
                      'change': function(rg,checked){
                            ci_class_box.setValue('');
                            if(checked.id == 'rdoRole'){
                                ci_class_box.allowBlank = true;
                                class_selected = false;
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
        { xtype:'textfield', name:'show_class', fieldLabel: _('Show class'), value: data.show_class }
    ]);
    return ret;
})
