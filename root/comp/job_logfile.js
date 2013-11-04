(function(params) {
        var logfile = new Ext.form.TextArea({
            style: 'font-family: Consolas, monospace',
            value: ''
        });
        var load_logfile = function() {
            Baseliner.ajaxEval( '/job/job_logfile', { id_job: params.id_job || 0 },
                function(res) {
                    if( res.success )
                        logfile.setValue( res.data );
                    else
                        Ext.Msg.show({icon: 'ext-mb-error', buttons: { cancel: true },
                                title: _("Logfile Open Error"),
                                msg: res.msg });
                }
            ); 
        };
        load_logfile();
        var panel = new Ext.Panel({
            layout: 'fit',
            tbar: [
                { xtype: 'button', icon: '/static/images/icons/html.gif', style: 'width: 30px', cls: 'x-btn-icon',
                    text: _('H'), handler: function(){ Baseliner.open_pre_page( panel.title, logfile.getValue() ) } },
                { xtype: 'button', text: _('Reload'), handler: load_logfile, icon:'/static/images/icons/refresh.gif', cls:'x-btn-text-icon' }
            ],
            tab_icon: '/static/images/icons/page.gif',
            items: [ logfile ]
        });
        panel.on('afterrender', function(){
            panel.body.setStyle({ 'overflow': 'hidden' });
        });
        return panel;
})
