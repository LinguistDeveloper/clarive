    Baseliner.show_email = function(params) {
	    var id = params.id_message;
	    if( id == undefined ) {
		    Baseliner.message( _('Error'), _('No email found for request %1', params.id_req ) );
		    return;
	    }
	    var url = '/message/body/' + id;
	    var field_body = new Ext.form.HtmlEditor({
		    readOnly: true,
		    hideLabel: true,
		    height: 400,
		    width: 500
	    });
	    var form_body = new Ext.FormPanel({
		    frame: true,
		    hideLabel: true,
		    items: field_body
	    });
	    var win = new Ext.Window({ layout: 'fit', 
		    autoScroll: false,
		    title: _('Request'),
		    maximizable: true,
		    height: 600, width: 900,
		    html: '<iframe border=0 height="100%" width="100%" src="' + url + '"></iframe>'
		    //autoLoad: { url: url, scripts: true }
	    });
	    win.show();
    };

