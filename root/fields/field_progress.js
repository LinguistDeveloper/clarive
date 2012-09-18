/*
name: progress
params:
    id_field: 'progress'
    origin: 'system'
    html: '/fields/field_progress.html'
    js: '/fields/field_progress.js'
    field_order: 8
    section: 'body'
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;
	
    return [
		{ xtype:'sliderfield', fieldLabel: _('Progress'), name: 'progress',
			value: data ? data.progress : 0,
			//hidden: !rec.fields_form.show_progress,
			anchor: '40%', tipText: function(thumb){
					return String(thumb.value) + '%';
			},
			disabled: meta ? meta.write ? meta.write: meta.readonly : true
		}
    ]
})
