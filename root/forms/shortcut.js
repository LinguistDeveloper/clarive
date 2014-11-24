(function(params){
    var data = params.data || {};
    var stash_data = new Baseliner.DataEditor({ 
        name:'stash_data', 
        hide_save: true, hide_cancel: true,
        title: _('Stash Data'),
        data: data.stash_data || {} 
    });

    var tabpanel = new Ext.TabPanel({ activeTab: 0, height: 500, fieldLabel: _('Stash Data'), items: [ stash_data] });
    tabpanel.on('afterrender', function(){
         //tabpanel.hideTabStripItem( stash_data );
    });
    
    var source_key = params.data.source_key;
    var config_data = new Ext.form.Hidden({
        name: 'config_data',
        get_save_data : function(){
            return this.fd;
        }
    });
    var config_window = function( key ) {
        Baseliner.ajaxEval( '/rule/edit_key', { key: key }, function(res){
            if( res.success ) {
                if( res.form ) {
                    Baseliner.ajaxEval( res.form, { data: data.config_data || {}, attributes: {} }, function(comp){
                        var params = {};
                        var save_form = function(){
                            var fd = form.getValues();
                            for( var k in fd ) {
                                // TODO missing correct identification of modified fields
                                if( fd[k] === undefined || ( Ext.isFunction(fd[k].isDirty) && !fd[k].isDirty() ) ) 
                                    delete fd[k];
                            }
                            config_data.fd = fd;
                            win.close();
                        };
                        var form = new Baseliner.FormPanel({ 
                            title: _('Config'),
                            frame: false, forceFit: true, defaults: { msgTarget: 'under', anchor:'100%' },
                            labelWidth: 150,
                            labelAlign: 'right',
                            height: 800,
                            labelSeparator: '',
                            autoScroll: true,
                            tbar: [
                                '->',
                                { xtype:'button', text:_('Cancel'), icon:'/static/images/icons/delete.gif', handler: function(){ win.close() } },
                                { xtype:'button', text:_('Save'), icon:'/static/images/icons/save.png', handler: function(){ save_form() } }
                            ],
                            bodyStyle: { padding: '4px', "background-color": '#eee' },
                            items: comp,
                        });
                        var win = new Baseliner.Window({ modal:true, width: 900, height: 500, items: form, layout: 'fit' });
                        win.show();
                    });
                } else {
                    // var node_data = Ext.apply( res.config, node.attributes.data );
                    // var comp = new Baseliner.DataEditor({ data: node_data });
                    // show_win( node, comp, { width: 800, height: 400 } );
                }
            } else {
                Baseliner.error( _('Error'), res.msg );
            }
        });
    };    
    
        //if( source_key && source_key!='statement.shortcut' ) config_window(source_key);
    var btn_config = new Ext.Button({ hidden: (!source_key || source_key=='statement.shortcut'), 
        icon: IC('edit.gif'),
        fieldLabel:_('Config Data'), width: 150, text:_('Open Config Window'), handler: function(){
        config_window(source_key);
    } });
    
    return [ 
        { xtype:'textfield', fieldLabel: _('Shortcut ID'), name: 'call_shortcut', 
            readOnly: true,
            value: params.data.call_shortcut || Baseliner.name_to_id(Math.floor(1000*Math.random())+'_'+new Date().format('Ymdhis')) 
        },
        { xtype:'textfield', fieldLabel: _('Source Key'), name: 'source_key', readOnly: true, value: params.data.source_key || '' },
        btn_config,
        config_data,
        tabpanel
    ];
})
