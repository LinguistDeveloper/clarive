(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    var value_type = Baseliner.generic_list_fields(data);
    ret.push(value_type);

    var collection = new Ext.form.Hidden({ name: 'collection', value: data.collection });

    var ci_store = new Ext.data.JsonStore({
        root: 'data', 
        remoteSort: true,
        totalProperty: 'totalCount', 
        id: 'id', 
        baseParams: Ext.apply({  start: 0, limit: 9999 }, this.baseParams ),
        url: '/ci/classes',
        fields: [ 'name', 'classname' ],
        listeners:{
            'load': function (){
                //console.log(this);
            } 
        }
    });

    var ci_class_box = new Baseliner.SuperBox({
        name: 'ci_class_box',
        xtype: 'combo',
        fieldLabel: _('CI class'),
        store: ci_store,
        triggerAction: 'all',
        valueField: 'name',
        displayField: 'name',
        singleMode: false,
        mode: 'remote',
        value: data.collection,
        listeners:{
            'change': function(elem,value){
                collection.setValue(value);
            }
        }
    });

    ret.push([ 
    	{ xtype:'hidden', name:'fieldletType', value: 'fieldlet.system.projects' },
    	ci_class_box,
    	collection,
    	{ xtype:'textfield', fieldLabel: _('Default Value'), name:'default_value', value: data.default_value || '' },
    ]);
    return ret;
})