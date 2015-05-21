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
    var default_value = Baseliner.eval_boolean(meta.default_value);
    var checked = data && data[ meta.bd_field ]=='1'  ? true:  data && data[ meta.bd_field ]=='0'  ? false : default_value;
    
    var checkbox = new Baseliner.CBox({
        name: meta.id_field,
        checked: checked,
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
