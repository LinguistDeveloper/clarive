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

    var allow = Baseliner.eval_boolean(meta.allowBlank);
    var readonly = Baseliner.eval_boolean(meta.readonly);
	
    var records = data && data[ meta.bd_field ]? data[ meta.bd_field ] : '[]';
    var grid = new Baseliner.GridEditor({
		fieldLabel: _(meta.name_field),
		allowBlank: readonly ? true : allow,
		readOnly: readonly,
        width: meta.width || '100%',
        height: meta.height || 300,
        //style: 'margin-bottom: 10px',
        name: meta.id_field,
        id_field: meta.id_field,
        bd_field: meta.bd_field,
        records: records, 
        preventMark: false,        
        columns: meta.columns,
        disabled: readonly,
        viewConfig: {
            forceFit: meta.forceFit || true
        }
    });


	return [
        //Baseliner.field_label_top( meta.name_field, meta.hidden, allow, readonly ),
        grid
    ]
})

