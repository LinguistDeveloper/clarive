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
    var size = meta.size ? meta.size: '12px';

    var separator = new Ext.Component({
        name: meta.id_field,
        hidden: Baseliner.eval_boolean(!meta.active),
        html: String.format(
            "<div style='color: {1}; margin: 4px 0px 8px 0px; border-bottom: 2px solid {1}; font-size: {2}; font-weight: bold'>{0}</div>",
            _(meta.name_field), color, size ),
        readOnly: false

    });

    return separator
})
