(function(params){
    var revision_box = new Baseliner.model.RevisionsBoxDD({
        name: 'revisions'
        //hidden: rec.fields_form.show_revisions ? false : true
    });

	return [
		revision_box
    ]
})