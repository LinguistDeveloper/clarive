/*
name: Separator
params:
    origin: 'template'
    type: 'separator'
    js: '/fields/templates/js/separator.js'
    field_order: 1
    color: '#99CCFF'
*/

(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    var color = meta.color ? meta.color: '#99CCFF';
    
    var separator = new Ext.Component({
        fieldLabel: _(meta.name_field),
        name: meta.id_field,
        labelSeparator: '',
        labelStyle: 'color:'+ color + ';font-weight:bold',
        hidden: Baseliner.eval_boolean(meta.hidden),
        autoEl: {html:'<hr style="background-color:' + color + ';height:2px;border:none;>"'},
        readOnly: false

    });
    
    return separator
})
