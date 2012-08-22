(function(params){
    var store_joboptionsglobal = new Ext.data.ArrayStore({
        fields: ['id', 'name'],
        data: [],
        sortInfo: {field: 'name', direction: 'ASC'}
        });

    var combo_joboptionsglobal = new Ext.ux.form.SuperBoxSelect({
        id: 'joboptionsglobal<% $iid %>',
        allowBlank: true,
        msgTarget: 'under',
        allowAddNewData: true,
        width: 808,
        addNewDataOnBlur: true,
        hidden: true,
        //emptyText: _('Enter or select the category tags'),
        triggerAction: 'all',
        resizable: true,
        store: store_joboptionsglobal ,
        mode: 'local',
        fieldLabel: _('Job Options'),
        typeAhead: true,
        name: 'combo_joboptionsglobal',
        displayField: 'name',
        hiddenName: 'combo_joboptionsglobal',
        valueField: 'id',
        // displayFieldTpl: tpl2,
        // value: params.role_hash,
        extraItemCls: 'x-tag',
        listeners: {
            newitem: function(bs,v, f){
                v = v.slice(0,1).toUpperCase() + v.slice(1).toLowerCase();
                var newObj = {
                    id: v,
                    name: v
                };
                bs.addItem(newObj);
                },
            beforeremoveitem: function(bs,v, f){
                // if (check_no_cal.checked && ( v == 'chm_rf_ll' || v== 'chm_rf_db2')) return false;
                }
            }
        });
        
    var add_joboptionsglobal = function (rec) {
        if (rec.data.job_options_global == undefined) return;
        var arr=rec.data.job_options_global;
        if (arr.length==0) return;
        if (arr == undefined) return;

        for (var i=0;i<arr.length;i++) {
            var ix=store_joboptionsglobal.find('id',arr[i].id, 0, true, false);
            if (ix == -1) {
                arr[i].name=_(arr[i].name);
                store_joboptionsglobal.add(new Ext.data.Record(arr[i]));
                }
            }
        combo_joboptionsglobal.clearValue(true);
        if (combo_joboptionsglobal.store.data.length > 0) {
            text=combo_joboptionsglobal.store.data.items[0].data.id;
            for (var i=1;i<combo_joboptionsglobal.store.data.length;i++) {
                if (text.indexOf(combo_joboptionsglobal.store.data.items[i].data.id) < 0 ) {
                    text=text + "," + combo_joboptionsglobal.store.data.items[i].data.id;
                    }
                }
            combo_joboptionsglobal.setValue(text);
            }
        };

})

