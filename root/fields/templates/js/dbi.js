/*
name: DBI Query
params:
    origin: 'template'
    type: 'combo'
    html: '/fields/templates/html/row_body.html'
    js: '/fields/templates/js/dbi.js'
    field_order: 1
    section: 'body'
    value_field: id
    display_field: name
    dbi_connection:
*/

(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    
    var value = data[ meta.bd_field ];
    
    var store = new Baseliner.JsonStore({
        root: 'data',
        remoteSort: true,
        autoLoad: false,
        totalProperty: 'totalCount',
        jsonData: { id_field: meta.id_field, form: {}, raw: {}, data: data, meta: meta },
        url: '/ci/'+ meta.dbi_connection + '/query_from_field',
        fields: [ meta.value_field, meta.display_field ]
    });  
    
    var send_fields = Ext.isString(meta.send_fields) ? meta.send_fields.split(',') : meta.send_fields;
    store.on('beforeload', function(){
        store.jsonData.form = params.form.getValues();
        params.form.cascade( function(obj){
            if( obj.name != undefined && obj.getValueEx ) {
                //console.log( obj.name );
                //console.log( obj.getValueEx() );
                //console.log( obj.getCaption() );
                store.jsonData.raw[ obj.name ] = obj.getValueEx();
            }
        });
    });
    
    var combo =new Baseliner.SuperBox({ 
        name: meta.id_field,
        fieldLabel:_(meta.name_field), 
        valueField: meta.value_field,
        displayField: meta.display_field,
        value: value || meta['default_value'],
        singleMode: false, 
        forceSelection: true,
        selectOnFocus: true,
        anchor: meta.anchor || '100%',
        store: store,
        hidden: Baseliner.eval_boolean(meta.hidden),
        disabled: Baseliner.eval_boolean(meta.readonly)
    });
    
    
    /*
    var combo =  new Ext.form.ComboBox({
        name: meta.id_field,
        fieldLabel: _(meta.name_field),
        store: store,
        triggerAction: 'all',
        valueField: meta.value_field,
        displayField: meta.display_field,
        editable: meta.editable || true,
        mode: 'remote',
        anchor: meta.anchor || '100%',
        value: value || meta['default_value'],
        forceSelection: true,
        selectOnFocus: true,
        hidden: meta ? (meta.hidden ? meta.hidden : false): true,
        disabled: meta && meta.readonly ? meta.readonly : false
    });  
    */
    
    /*
    combo.on('afterrender', function(){
        combo.el.setHeight( parseInt(meta.height) || 22 );
    });
    */
    
    return [
        combo
    ]
})


