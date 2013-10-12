/*
name: Separator
params:
    origin: 'template'
    type: 'separator'
    js: '/fields/templates/js/separator.js'
    field_order: 1
*/

(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    
    var separator = new Ext.Component({
        fieldLabel: _(meta.name_field),
        name: meta.id_field,
        labelSeparator: '',
        autoEl: {tag:'hr'}
    });
    
    return separator
})
