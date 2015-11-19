(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    var selected_category = new Ext.form.Field({
        name: 'category',
        xtype: "textfield",
        value: '',
        hidden: true,
    });

    var store_category = new Ext.data.SimpleStore({
        fields: ['category', 'category_name' ],
        data: []  
    });
    Baseliner.ajaxEval('/topic/list_category', {cmb:'category'}, function(res){ 
        var data = []; 
        res.data.forEach(function(elem){
        	data.push([ elem.category, elem.category_name]);
        });
        store_category.loadData(data);
    } );


    var combo_category = new Ext.form.ComboBox({
        value: data ? data.category : '',
        mode: 'local',
        forceSelection: true,
        emptyText: _('select a category'),
        triggerAction: 'all',
        fieldLabel: _('Category'),
        name: 'category_combo',
        valueField: 'category',
        hiddenName: 'category_name',
        displayField: 'category_name',
        store: store_category,
        allowBlank: true,
        listeners:{
            'select': function(cmd, rec, idx){
            	selected_category.setValue(rec.data.category_name);   
            }
        }
    });

    ret.push([ 
        combo_category,
        { xtype:'textfield',fieldLabel: _('Filter'), name: 'filter', value: data.filter },
        { xtype:'numberfield',fieldLabel: _('Depth'), name: 'depth', value: data.depth },
        selected_category
    ]);

    return ret;
});
