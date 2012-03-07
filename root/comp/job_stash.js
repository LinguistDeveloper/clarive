(function(params) {
        var stash = new Ext.form.TextArea({
            height: '100%',
            width: '100%',
            style: 'font-family: Consolas, monospace',
            name: 'stash',
            value: ''
        });
        var load_stash = function() {
            Baseliner.ajaxEval( '/job/job_stash', { id_job: params.id_job || 0 },
                function(res) {
                    //Baseliner.message( _('Stash Log'), res.stash );
                    stash.setValue( res.stash );
                }
            ); 
        };
        var save_stash = function() {
            Baseliner.ajaxEval( '/job/job_stash_save', { id_job: params.id_job, stash: stash.getValue() },
                function(res) {
                    Baseliner.message( _('Save'), res.msg );
                }
            ); 
        };
        load_stash();
        var panel = new Ext.Panel({
            tbar: [
                { xtype: 'button', text: _('Save'), handler: save_stash },
                { xtype: 'button', text: _('Reload'), handler: load_stash }
            ],
            items: [ stash ]
        });
        return panel;
})
