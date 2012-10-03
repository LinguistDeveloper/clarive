/*
name: Progress bar
params:
    origin: 'template'
    html: '/fields/templates/html/progress_bar.html'
    js: '/fields/templates/js/progress_bar.js'
    field_order: 4
    section: 'body'
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;
	
    return [
		{ xtype:'sliderfield', fieldLabel: _(meta.name_field), name: meta.id_field,
			value: data ? eval('data.' + meta.bd_field) : 0,
			anchor: '40%', tipText: function(thumb){
					return String(thumb.value) + '%';
			},
			disabled: meta ? meta.readonly : true
		}
    ]
})
