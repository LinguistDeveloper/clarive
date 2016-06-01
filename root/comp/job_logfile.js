(function(params) {
        var logfile = new Ext.form.TextArea({
            style: 'font-family: Consolas, monospace',
            value: ''
        });
        var load_logfile = function() {
            if( panel.el ) panel.el.mask('');
            Baseliner.ajaxEval( '/job/job_logfile', { mid: params.mid || 0 },
                function(res) {
                    panel.el.unmask();
                    if( res.success )
                        logfile.setValue( res.data );
                    else
                        Ext.Msg.show({icon: 'ext-mb-error', buttons: { cancel: true },
                                title: _("Logfile Open Error"),
                                msg: res.msg });
                },
                function(){
                    panel.el.unmask();
                }
            );
        };
        var panel = new Ext.Panel({
            layout: 'fit',
            tbar: [
                { xtype: 'button', icon: '/static/images/icons/html.gif', cls: 'x-btn-icon', handler: function(){ Baseliner.open_pre_page( panel.title, logfile.getValue() ) } },
                { xtype: 'button', text: _('Reload'), handler: load_logfile, icon:'/static/images/icons/refresh.svg', cls:'x-btn-text-icon' }
            ],
            tab_icon: '/static/images/icons/page.gif',
            items: [ logfile ]
        });
        panel.on('afterrender', function(){
            load_logfile();
        });
        panel.on("activate", function() {
            Baseliner.showLoadingMask( panel.getEl());
    });
        panel.on('destroy', function(){
            autorefresh.stop(task);
    });
        return panel;
})
