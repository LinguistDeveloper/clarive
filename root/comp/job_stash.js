(function(params) {
        var stash = new Ext.form.TextArea({
            style: 'font-family: Consolas, monospace',
            value: ''
        });
        var load_stash = function() {
            Baseliner.ajaxEval( '/job/job_stash', { mid: params.mid || 0 },
                function(res) {
                    //Baseliner.message( _('Stash Log'), res.stash );
                    stash.setValue( res.stash );
                }
            ); 
        };
        var save_stash = function() {
            Baseliner.ajaxEval( '/job/job_stash_save', { mid: params.mid, stash: stash.getValue() },
                function(res) {
                    Baseliner.message( _('Save'), res.msg );
                }
            ); 
        };
        load_stash();
        var panel = new Ext.Panel({
            layout: 'fit',
            tbar: [
                { xtype: 'button', icon: '/static/images/icons/html.gif', style: 'width: 30px', cls: 'x-btn-icon',
                    text: _('H'), handler: function(){ Baseliner.open_pre_page( panel.title, stash.getValue() ) } },
                { xtype: 'button', text: _('Save'), icon: '/static/images/icons/save.png', handler: save_stash },
                { xtype: 'button', text: _('Reload'), icon: '/static/images/icons/refresh.png', handler: load_stash }
            ],
            tab_icon: '/static/images/icons/stash.gif',
            items: [ stash ]
        });
        panel.on('afterrender', function(){
            panel.body.setStyle({ 'overflow': 'hidden' });
        });
        return panel;
})
