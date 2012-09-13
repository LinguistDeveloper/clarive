/*
name: revisions
params:
    id_field: 'revisions'
    origin: 'rel'
    html: '/fields/field_revisions.html'
    js: '/fields/field_revisions.js'
    field_order: 12
    section: 'details'
    set_method: 'set_revisions'
    rel_field: 'revisions'
    method: 'get_revisions'
---
*/
(function(params){
    var revision_box = new Baseliner.model.RevisionsBoxDD({
        name: 'revisions'
        //hidden: rec.fields_form.show_revisions ? false : true
    });

	return [
		revision_box
    ]
})