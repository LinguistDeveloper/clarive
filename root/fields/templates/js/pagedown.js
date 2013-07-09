/*
name: Pagedown Editor
params:
    origin: 'template'
    html: '/fields/templates/html/markdown.html'
    js: '/fields/templates/js/pagedown.js'
    field_order: 1
    field_order_html: 1000
    allowBlank: 0
    section: 'head'
*/

(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    
    var value = data[ meta.bd_field ] || meta.default_value ;
    var editor = new Baseliner.Pagedown({
        fieldLabel: _(meta.name_field),
        name: meta.id_field,
        anchor: meta.anchor || '100%',
        height: meta.height || 30,
        value: value || ''
    });
    return [
        editor
    ]
})



