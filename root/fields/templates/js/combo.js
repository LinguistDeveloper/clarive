/*
name: Combo
params:
    origin: 'template'
    type: 'combo'
    html: '/fields/templates/html/row_body.html'
    js: '/fields/templates/js/combo.js'
    field_order: 1
    allowBlank: 'false'
    section: 'body'
    options: 'option1,option2,option3'
*/

(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    var value = data[ meta.bd_field ];
    
    var options = meta[ 'options' ];

    var opt_arr = [];
    if( options != undefined  ) {
        var vv = options.split(',');
        Ext.each(vv, function(v){
            opt_arr.push([ v ]);
        });
    }
    
    var store = new Ext.data.ArrayStore({
        fields: [ meta.id_field ],
        data : opt_arr
    });  
    var combo =  new Ext.form.ComboBox({
        name: meta.id_field,
        xtype: 'combo',
        fieldLabel: _(meta.name_field),
        store: store,
        triggerAction: 'all',
        valueField: meta.id_field,
        editable: Baseliner.eval_boolean(meta.editable),
        displayField: meta.id_field,
        mode: 'local',
        anchor: meta.anchor || '100%',
        value: value || meta['default_value'],
        forceSelection: true,
        selectOnFocus: true,
        hidden: Baseliner.eval_boolean(meta.hidden),
        disabled: Baseliner.eval_boolean(meta.readonly),
        allowBlank: Baseliner.eval_boolean(meta.allowBlank)
    });  
    
    combo.on('afterrender', function(){
        combo.el.setHeight( meta.height || 30 );
    });
    
    return [
        combo
    ]
})

