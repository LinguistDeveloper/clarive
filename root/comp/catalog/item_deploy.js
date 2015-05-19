(function(params) {
    if( params==undefined ) params={};

    Baseliner.cis = function(c) {
        if( c==undefined ) c={};
        var role = ( c.role == undefined ? 'CI' : c.role );
        var ci_store = new Baseliner.store.CI({ baseParams: { role:role } });
        var cis = new Baseliner.model.CISelect(Ext.apply({
            store: ci_store, 
            singleMode: true, 
            fieldLabel:_('CI'), 
            name:'ci', 
            hiddenName:'ci', 
            allowBlank:false }, c)); 
        ci_store.on('load',function(){
            if( c.value != undefined )  {
               cis.setValue( c.value ) ;            
            }
        });
        return cis;
    };

    //var scripts_single = Baseliner.array_field({ name:'scripts_single',
        //title:_('Scripts Single'), label:_('Scripts Single'), value: params.scripts_single, default_value: 'ssh_script://user@host:port/path/new_script.sh'});

    //var scripts_multi = Baseliner.array_field({ name:'scripts_multi',
        //title:_('Scripts Multi'), label:_('Scripts Multi'), value: params.scripts_multi, default_value: 'ssh_script://user@host:port/path/new_script.sh'});

    var include = Baseliner.array_field({ name:'include',
        title:_('Include'), label:_('Include'), description: _('Element pattern regex to include'), 
            value: params.include, default_value: '\\.js$'});

    var exclude = Baseliner.array_field({ name:'exclude',
        title:_('Exclude'), label:_('Exclude'), description: _('Element pattern regex to exclude'),
            value: params.exclude, default_value: '\\.ext$'});

    var projects = Baseliner.cis({ name:'projects', hiddenName:'projects', role: 'Internal', allowBlank:true,
        fieldLabel:_('Projects'), value: params.projects });

    var scripts_multi = Baseliner.cis({ name:'scripts_multi', hiddenName:'scripts_multi', role: 'Script', allowBlank:true,
        fieldLabel:_('Scripts Multi'), value: params.scripts_multi });

    var scripts_single = Baseliner.cis({ name:'scripts_single', hiddenName:'scripts_single', role: 'Script', allowBlank:true,
        fieldLabel:_('Scripts Single'), value: params.scripts_single });

    var deployments = Baseliner.cis({ name:'deployments', hiddenName:'deployments', role: 'Destination', description: _('List of nodes to deploy to'),
        fieldLabel:_('Deployments'), value: params.deployments });

    //var deployments = Baseliner.array_field({ name:'deployments', description: _('List of nodes to deploy to'),
        //title:_('Deployments'), label:_('Deployments'), value: params.deployments, default_value: 'new_deployment'});
    
    var tabs = new Ext.TabPanel({ width: '705', height: '200',  plugins: [ new Ext.ux.panel.DraggableTabs()],
                items: [ include.grid, exclude.grid ] });

    tabs.setActiveTab( include.grid );

    var form = new Ext.FormPanel( {
         border : false,
         frame  : true,
         // url - is set by the submit button later on
         defaults: {
            width: 600
         },
         items  : [
            { xtype: 'hidden', name: "id", fieldLabel: "id", allowBlank: 1, value: params.id },
            //new Baseliner.model.Projects({ value: params.projects || params.project }),
            {
                xtype: 'checkbox',
                name: "active",
                fieldLabel: _("Active"),
                checked: params.active == undefined ? true : params.active,
                allowBlank: 1
            },
            { xtype: 'textfield', name: "name", fieldLabel: _("Name"), allowBlank: 1, value: params.name, style:'font-weight:bold' },
            projects,
            Baseliner.combo_baseline({ value: params.bl || '*' }) ,
            {
                xtype: 'textfield',
                name: "workspace",
                fieldLabel: _("Directory"),
                value: params.workspace || '/app/path',
                allowBlank: 0
            },
            { xtype:'container', autoEl: { tag: 'div', html: _('Use regex, forward slashes and captures: %1', '/mydir/, /(.*?)/mydir/, /(?<app>MyApp)/path/to') },
                style: 'padding: 0 0 10px 120px' },
            {
                xtype: 'textfield',
                name: "order",
                fieldLabel: _("Mapping Order"),
                value: params.order || 1,
                allowBlank: 0
            },
            { xtype: 'checkbox', name: 'no_paths', fieldLabel: _('Options'), boxLabel: _("Do not deploy paths, only files"),
                checked: params.no_paths == undefined ? true : params.no_paths
            },
            { xtype: 'checkbox', name: 'path_deploy', fieldLabel: _('Path'), boxLabel: _("Deploy full workspace path"),
                checked: params.path_deploy == undefined ? false : params.path_deploy
            },
            deployments,
            scripts_single,
            scripts_multi,
            include.data,
            exclude.data,
            tabs,
            {
                type: 'Submit',
                name: 'Sb'
            }] 
    }); //form      
        
    var panel = new Ext.Panel({
        //width: 800,
        height: '100%',
        autoScroll:true,
        tbar: [ Baseliner.button(_('Save'), '/static/images/icons/keyboard_add.png', function(){
            form.getForm().submit({
                url: '/itemdeploy/submit',
                waitMsg: _('Saving...'),
                success: function(fp, o){
                    var res = Ext.util.JSON.decode(o.response.responseText);
                    Baseliner.message( _('Eclipse Java/J2EE Mapping'), _('Data stored') );
                    // tell catalog to refresh
                    var win = panel.findParentByType('window');
                    if( win != undefined ) win.rc = true;
                    Baseliner.close_parent(panel);
                },
                failure:  function(fp, o){
                    var res = Ext.util.JSON.decode(o.response.responseText);
                    Ext.MessageBox.show({
                        title: _('Error while writing to catalog'),
                        msg: res.msg,
                        buttons: Ext.MessageBox.OK,
                        icon: Ext.MessageBox.ERROR
                    });
                }
            });
        } ), { xtype: 'button', text:_('Close'), handler:function(){ Baseliner.close_parent(panel) } } ],
        items: [ form ]
    });
    return panel;
})


