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
	
    var allow = meta.allowBlank == undefined ? true : ( meta.allowBlank == 'false' || !meta.allowBlank ? false : true );
    var readonly = meta.readonly == undefined ? true : meta.readonly;	

    var up = new Baseliner.UploadFilesPanel({
		name:  meta.id_field,
		fieldLabel: _(meta.name_field),
        allowBlank  : allow,
        height: ( meta.height ? parseInt(meta.height) : 200 ),
        readOnly    : readonly,
		disabled: readonly,
        id_field    : meta.id_field,
        form : form
    });
    return [
        up
    ]
})


