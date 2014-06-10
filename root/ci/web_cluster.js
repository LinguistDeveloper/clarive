(function(params){
    var data = params.rec || {};
    
    var webinstance_cis = function(c) {
        var bp  = {};
        bp['class'] = c['isa'];
        var ci_store = new Baseliner.store.CI({ 
            url:'/ci/web_instance/store', 
            autoLoad:true, 
            baseParams: bp, 
            totalProperty: 'totalCount',
            fields: ['mid','name','bl','moniker', 'server'] 
        });
        var tpl_list = new Ext.XTemplate(
            '<tpl for="."><div class="search-item">',
            '<span id="boot" style="background: transparent"><strong>{name}</strong>',
            '<tpl if="values.bl && values.bl!=\'*\'">',
                ' ({bl} - {moniker}) ',
            '</tpl>',
            '<tpl for="server">',
                ' ({name})',
            '</tpl>',  
            '</span>',
            '</div></tpl>'
        );
        var cis = new Baseliner.model.CISelect(Ext.apply({
            store: ci_store,
            hiddenName:'ci', 
            triggerAction: 'all',
            tpl:tpl_list,
        }, c));
        ci_store.on('load',function(){
            if( c.value != undefined )  {
               cis.setValue( c.value ) ;            
            }
        });
        return cis;
    };

    return [
      { xtype: 'textfield', fieldLabel: _('URL'), anchor:'100%', name:'url', allowBlank: false, value: data.url },
    	Baseliner.ci_box({ name:'server', anchor:'100%', fieldLabel:_('Server'), role:'Server', allowBlank: false, singleMode:false, force_set_value: true, value: data.server }),
      { xtype: 'textfield', fieldLabel: _('Doc Root'), anchor:'100%', name:'doc_root', allowBlank: false, value: data.doc_root },
      { xtype: 'textfield', fieldLabel: _('User'), anchor:'100%', name:'user', allowBlank: true, value: data.user },
      webinstance_cis({ name:'instances', anchor:'100%', fieldLabel:_('Instances'), isa:'web_instance', allowBlank: true, singleMode:false, force_set_value: true, value: data.instances })
    ]
})
