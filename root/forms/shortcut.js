(function(params){
    var data = params.data || {};
    var stash_data = new Baseliner.DataEditor({ 
        name:'stash_data', 
        hide_save: true, hide_cancel: true,
        title: _('Stash Data'),
        data: data.stash_data || {} 
    });
    var tabpanel = new Ext.TabPanel({ activeTab: 0, height: 300, fieldLabel: _('Stash Data'), items: [ stash_data ] });
    tabpanel.on('afterrender', function(){
         //tabpanel.hideTabStripItem( stash_data );
    });
    
    return [ 
        { xtype:'textfield', fieldLabel: _('Shortcut ID'), name: 'call_shortcut', 
            readOnly: true,
            value: params.data.call_shortcut || Baseliner.name_to_id(Math.floor(1000*Math.random())+'_'+new Date().format('Ymdhis')) 
        },
        tabpanel
    ];
})
