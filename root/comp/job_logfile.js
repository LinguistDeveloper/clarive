(function(params) {
        var logfile = new Ext.form.TextArea({
            height: '100%',
            width: '100%',
            style: 'font-family: Consolas, monospace',
            name: 'logfile',
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
            tbar: [
                { xtype: 'button', text: _('Reload'), handler: load_logfile, icon:'/static/images/icons/refresh.gif', cls:'x-btn-text-icon' }
            ],
            items: [ logfile ]
        });
        return panel;
})
