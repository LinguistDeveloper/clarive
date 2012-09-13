(function(params){
	var data = params.topic_data;
	
	return [
		{   xtype:'panel', layout:'fit',
			//hidden: rec.fields_form.show_description ? false : true,
			items: [ //this panel is here to make the htmleditor fit
				{
					xtype:'htmleditor',
					name:'description',
					fieldLabel: _('Description'),
					width: '100%',
					value: data ? data.description : '',
					height:350
				}
			]
		}
    ]
})