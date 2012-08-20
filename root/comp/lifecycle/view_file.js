(function(params) {
    var style_cons = 'background: black; background-image: none; color: #10C000; font-family: "DejaVu Sans Mono", "Courier New", Courier';
    var code = new Ext.form.TextArea({
        name: 'code',
	    style: style_cons
    });

    Baseliner.ajaxEval( '/lifecycle/view_file', params, function(res) {
        code.setValue( res.data );
    });

    var checkin = function() {
        code.setValue( res.data );
    };

    var form = new Ext.FormPanel({
            layout: 'fit',
            url      : '/repl/eval',
            frame    : false,
            hideLabel: false,
            tbar     : [
                { xtype:'button', text:_('Commit...'),icon: '/static/images/icons/drive_add.png', cls: 'x-btn-text-icon',
                    handler: checkin },
                { xtype:'button', text:_('Compile'),icon: '/static/images/icons/run.png', cls: 'x-btn-text-icon',
                    handler: checkin },
                { xtype:'button', text:_('Save'), icon: '/static/images/icons/action_save.gif', cls: 'x-btn-text-icon',
                    handler: checkin }
            ],
            items 	 : [ code ]
        }
    );
    return form;
})
