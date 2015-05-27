/*
name: Attach Files
params:
    origin: 'template'
    type: 'upload_files'
    html: '/fields/templates/html/upload_files.html'
    js: '/fields/templates/js/upload_files.js'
    relation: 'system'
    get_method: 'get_files'    
    field_order: 3
    section: 'details'
    allowBlank: true
---
*/
(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    var form = params.form;
	
    var allow = Baseliner.eval_boolean(meta.allowBlank, true);
    var readonly = Baseliner.eval_boolean(meta.readonly, false);   
    var editable = Baseliner.eval_boolean(meta.editable, true);	

    var up = new Baseliner.UploadFilesPanel({
		name:  meta.id_field,
		fieldLabel: _(meta.name_field),
        allowBlank  : allow,
        height: ( meta.height ? parseInt(meta.height) : 200 ),
        readOnly    : readonly,
        hidden: !editable,
		disabled: readonly,
        id_field    : meta.id_field,
        form : form
    });
    return [
        up
    ]
})


