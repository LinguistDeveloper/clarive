(function(params){
	var data = params.topic_data;
	
	var ff = params.form.getForm();
	var topic_mid = ff.findField("topic_mid").getValue();

    var release_box_store = new Baseliner.store.Topics({ baseParams: { mid: topic_mid, show_release: 1 } });

    var release_box = new Baseliner.model.Topics({
        hiddenName: 'release',
        name: 'release',
        fieldLabel: _('Release'),
        singleMode: true,
        //hidden: rec.fields_form.show_release ? false : true,
        store: release_box_store
    });
	
    release_box_store.on('load',function(){
		release_box.setValue (data ? (data.release.mid ? data.release.mid : '') : '');
    });


	return [
		release_box
    ]
})