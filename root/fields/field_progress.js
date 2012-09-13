(function(params){
	var data = params.topic_data;
	
    return [
		{ xtype:'sliderfield', fieldLabel: _('Progress'), name: 'progress',
			value: data ? data.progress : 0,
			//hidden: !rec.fields_form.show_progress,
			anchor: '40%', tipText: function(thumb){
					return String(thumb.value) + '%';
			} 
		}
    ]
})
