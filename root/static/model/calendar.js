define(function() {
	return {
		delete: function(args, callback) {
			var url = '/job/calendar_delete';
			Cla.ajax_json(url, args, function(res) {
				Cla.message(_('Calendar'), res.msg);
				if (res.success && callback) callback();
			});
		}
	}
});