/*
name: Datefield
params:
    origin: 'template'
    type: 'datefield'
    html: '/fields/templates/html/row_body.html'
    js: '/fields/templates/js/datetimefield.js'
    field_order: 1
    section: 'body'
    default_today: 'false'
    meta_type: 'date'
---
*/

(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;

	var show_time = meta.show_time && (meta.show_time == 'true' || meta.show_time == 'on');
	var date_format = show_time ? Cla.user_js_date_time_format() : Cla.user_js_date_format();
	var date_format_moment =  Cla.js_date_to_moment_hash[Cla.user_js_date_format()];
	date_format_moment = show_time ? date_format_moment + " HH:mm" : date_format_moment;

    var value = data ? (data[meta.id_field] ? data[meta.id_field] : '' ): '';
    if( !value && meta.default_today && (meta.default_today == 'true' || meta.default_today == 'on') ) {
        value = new Date();
    };
    value = moment(value).format(date_format_moment);

    return [
		{
			xtype:'xdatefield',
			fieldLabel: _(meta.name_field),
			name: meta.id_field,
			value: value,
			//style: { 'font-size': '16px' },
			format:  date_format,
			show_time: show_time,
			width: 165,
			//height: 30,
			allowBlank: Baseliner.eval_boolean(meta.allowBlank),
			readOnly: Baseliner.eval_boolean(meta.readonly),
			hidden: Baseliner.eval_boolean(!meta.active)
		}
    ]
})
