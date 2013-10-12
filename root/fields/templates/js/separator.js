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
        labelStyle: 'color:#0099FF;font-weight:bold',
        hidden: meta ? (meta.hidden ? meta.hidden : false): true,
        autoEl: {html:'<hr style="background-color:#0099FF;height:2px;border:none;>"'}

    });
    
    return separator
})
