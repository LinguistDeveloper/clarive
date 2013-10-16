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
    height: 400
*/

(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    
    var value = data[ meta.bd_field ] || meta.default_value ;
    var editor = new Baseliner.Pagedown({
        name: meta.id_field,
        font: meta.font,
        anchor: meta.anchor || '100%',
        height: meta.height || 30,
        value: value || ''
    });
    allow = meta.allowBlank == undefined ? true : ( meta.allowBlank == 'false' || !meta.allowBlank ? false : true );
    readonly = meta.readonly == undefined ? true : meta.readonly;

    return [
        Baseliner.field_label_top( meta.name_field, meta.hidden, allow, readonly ),
        new Ext.Panel({ layout:'fit', anchor: meta.anchor || '100%', height: meta.height, border: false, items: editor })
    ]
})



