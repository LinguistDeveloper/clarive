/*
name: Pills
params:
    origin: 'template'
    type: 'combo'
    html: '/fields/templates/html/row_body.html'
    js: '/fields/templates/js/pills.js'
    field_order: 1
    allowBlank: 0
    section: 'body'
    options: 'option1,option2,option3'
*/

(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    
    var value = data[ meta.bd_field ] || meta.default_value ;
    var options = meta[ 'options' ];
    
    var buts = new Baseliner.Pills({
        fieldLabel: _(meta.name_field),
        name: meta.id_field,
        anchor: meta.anchor || '100%',
        height: meta.height || 30,
        options: meta['options'],
        value: value
    });
    return [
        buts
    ]
})


