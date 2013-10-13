/*
name: Grid Editor
params:
    origin: 'template'
    js: '/fields/templates/js/grid_editor.js'
    html: '/fields/templates/html/grid_editor.html'
    field_order: 100
    field_order_html: 1000
    section: 'head'
    data: 1
---
*/
(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
	var ff = params.form.getForm();
    
    var records = data && data[ meta.bd_field ]? data[ meta.bd_field ] : '[]';
    var grid = new Baseliner.GridEditor({
        width: meta.width || '100%',
        height: meta.height || 300,
        id_field: meta.id_field,
        bd_field: meta.bd_field,
        records: records, 
        columns: meta.columns,
        readOnly: meta.readonly!=undefined ? meta.readonly : true,
        disabled: meta.readonly!=undefined ? meta.readonly : true,
        viewConfig: {
            forceFit: meta.forceFit || true
        }
    });
    allow = meta.allowBlank == undefined ? true : ( meta.allowBlank == 'false' || !meta.allowBlank ? false : true );
    readonly = meta.readonly == undefined ? true : meta.readonly;

	return [
        Baseliner.field_label_top( meta.name_field, meta.hidden, allow, readonly ),
        grid
    ]
})

