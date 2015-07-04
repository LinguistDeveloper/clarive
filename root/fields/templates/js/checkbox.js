/*
name: Checkbox
params:
    origin: 'template'
    type: 'checkbox'
    html: '/fields/system/html/field_checkbox.html'
    js: '/fields/templates/js/checkbox.js'
    field_order: 1
    section: 'body'
    default_value: 'false'
*/

(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    
    var checkbox = new Baseliner.CBox({
        name: meta.id_field,
        checked: Baseliner.eval_boolean(data[meta.id_field], false),
        disabled: Baseliner.eval_boolean(meta.readonly),
        hidden: Baseliner.eval_boolean(meta.hidden),
        anchor: meta.anchor || '100%',
        width: meta.width || '100%',
        labelSeparator: '',
        hideLabel: true,
        boxLabel: _(meta.name_field),
        fieldLabel: _(meta.name_field),
        // style: 'margin-bottom: 15px'
    });
    
    return [checkbox]
})
