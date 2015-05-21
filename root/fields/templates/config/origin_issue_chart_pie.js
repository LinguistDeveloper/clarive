(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);

    var selected_category = new Ext.form.Field({
        name: 'category',
        xtype: "textfield",
        value: ''
    });
    selected_category.hide();

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
        emptyText: 'select a category',
        triggerAction: 'all',
        fieldLabel: _('Category'),
        name: 'category_combo',
        valueField: 'category',
        hiddenName: 'category_name',
        displayField: 'category_name',
        store: store_category,
        allowBlank: false,
        listeners:{
            'select': function(cmd, rec, idx){
            	selected_category.setValue(rec.data.category_name);   
            }
        }
    });
    ret.push([ 
    	{ xtype:'hidden', name:'fieldletType', value: 'fieldlet.origin_issue_chart_pie' },
    	{ xtype:'numberfield',fieldLabel: _('Depth'), name: 'depth', allowBlank: false, value: data.depth },
    	{ xtype:'textfield',fieldLabel: _('Role filter'), name: 'filter', value: data.filter },
    	combo_category,
    	selected_category
    ]);
    return ret;
})

