(function(params){
    var store_incidencias = new Ext.data.SimpleStore({
        fields: ['codigo'],
        data: [],
        sortInfo: {field: 'codigo', direction: 'ASC'}
    });

    var combo_incidencias = new Ext.ux.form.SuperBoxSelect({
        id: 'jobincidencias<% $iid %>',
        allowBlank: true,
        msgTarget: 'under',
        allowAddNewData: true,
        width: 808,
        addNewDataOnBlur: true,
        triggerAction: 'all',
        resizable: true,
        store: store_incidencias ,
        mode: 'local',
        fieldLabel: _('Incidencias'),
        typeAhead: true,
        hidden: true,
        name: 'combo_incidencias',
        displayField: 'codigo',
        hiddenName: 'combo_incidencias',
        valueField: 'codigo',
        extraItemCls: 'x-tag',
        listeners: {
            newitem: function(bs,v, f){
                v = v.slice(0,1).toUpperCase() + v.slice(1).toLowerCase();
                var newObj = {
                    codigo: v
                    };
                bs.addItem(newObj);
                }
            }
    });
        
    var add_incidencia = function (rec) {
        var arr=rec.data.inc_id;
        if (rec.data.inc_id == undefined) return;
        if (arr.length == 0) return;
        if (arr == undefined) return;
        if (arr[0].codigo == null) return;

        for (var i=0;i<arr.length;i++) {
            var ix=store_incidencias.find('codigo',arr[i].codigo);
            if (ix == -1) {
                store_incidencias.add(new Ext.data.Record(arr[i]));
                }
            }
        combo_incidencias.clearValue(true);
        if (combo_incidencias.store.data.length > 0) {
            text=combo_incidencias.store.data.items[0].data.codigo;
            for (var i=1;i<combo_incidencias.store.data.length;i++) {
                if (text.indexOf(combo_incidencias.store.data.items[i].data.codigo) < 0 ) {
                    text=text + "," + combo_incidencias.store.data.items[i].data.codigo;
                    }
                }
            combo_incidencias.setValue(text);
            }
    };
    
})
