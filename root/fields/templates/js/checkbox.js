/*
name: Checkbox
params:
    origin: 'template'
    type: 'checkbox'
    html: '/fields/system/html/field_checkbox.html'
    js: '/fields/templates/js/checkbox.js'
    field_order: 1
    allowBlank: 0
    section: 'body'
*/

(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    
    var checkbox = new Baseliner.CBox({
        fieldLabel: _(meta.name_field),
        name: meta.id_field,
        checked: data && data[ meta.bd_field ]=='1'  ? true : false,
        default_value: false,
        disabled: meta ? meta.readonly : true,
        hidden: meta ? (meta.hidden ? meta.hidden : false): true,
        labelSeparator: '',
        hideLabel: true,
        boxLabel: _(meta.name_field),
        fieldLabel: _(meta.name_field),
        style: 'margin-bottom: 15px'
    });
    
    return checkbox
})
