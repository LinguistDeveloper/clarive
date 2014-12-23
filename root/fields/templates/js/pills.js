/*
name: Pills
params:
    origin: 'template'
    type: 'combo'
    html: '/fields/templates/html/pills.html'
    js: '/fields/templates/js/pills.js'
    field_order: 1
    allowBlank: 'false'
    section: 'body'
    options: 'option1,#ddb;option2,#bdd;option3,#dbd'
    default_value: option1
*/

(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    
    var value = data[ meta.bd_field ] || meta.default_value || '';
    var options = meta[ 'options' ];
    
    var pills = new Baseliner.Pills({
        fieldLabel: _(meta.name_field),
        name: meta.id_field,
        anchor: meta.anchor || '100%',
        height: meta.height || 30,
        options: meta['options'],
        value: value
    });
    return [
        pills
    ]
})


