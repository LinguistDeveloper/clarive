    //---------------------------------------------------
    // Portal stuff

    //Baseliner.portalAddCompUrl({ col: 1, url_portlet: '/job/monitor_portlet', url_max: '/job/monitor' });
    //Baseliner.portalAddCompUrl({ col: 2, url_portlet: '/revision/grid', url_max: '/job/monitor' });
    // Ext.state.Manager.setProvider(new Ext.state.CookieProvider());

    Baseliner.portalConfig = {};
    Baseliner.portalConfig.col_number = 2;
    Baseliner.portalConfig.last_col = 0;
    var col_width = 1 / Baseliner.portalConfig.col_number;
    col_width = col_width - .002;
    
    Baseliner.portal = new Ext.ux.Portal({
            region:'center',
            margins:'5 5 5 0',
            id: 'theportal',
            items:[{
                columnWidth: col_width,
                id: 'baseliner-portal-column-1',
                style:'padding:10px 0 10px 10px'
            },{
                columnWidth: col_width,
                id: 'baseliner-portal-column-2',
                style:'padding:10px'
            }]
            
            /*
             * Uncomment this block to test handling of the drop event. You could use this
             * to save portlet position state for example. The event arg e is the custom 
             * event defined in Ext.ux.Portal.DropZone.
             */
//            ,listeners: {
//                'drop': function(e){
//                    Ext.Msg.alert('Portlet Dropped', e.panel.title + '<br />Column: ' + 
//                        e.columnIndex + '<br />Position: ' + e.position);
//                }
//            }
        });

    /* var container = new Ext.Container({
        id: 'portal_vp',
        layout:'column',
        monitorResize: true,
        border: false,
        autoWidth: false,
        items:[]
    }); */
    //var cc = new Ext.Panel({
     //   html: 'aaa'
    //});
    

    Baseliner.portalTools = [{
        id:'maximize',
        handler: function(e, target, panel ){
            if( panel.portlet_type == 'comp' ) 
                Baseliner.addNewTabComp( panel.url_max, panel.title );
            else
                Baseliner.addNewTab( panel.url_max, panel.title );
        }
    },{
        id:'close',
        handler: function(e, target, panel){
            panel.ownerCt.remove(panel, true);
        }
    }];

    Baseliner.portalAddUrl = function( params ){
        var comp = new Ext.Panel({
            cls: 'baseliner-portal-htmlpanel',
            autoLoad: { url: params.url_portlet, scripts: true }
        });
        Baseliner.portalAddComp({ title: params.title, portlet_type: 'html',
            comp: comp, col: params.col, url_portlet: params.url_portlet, url_max: params.url_max });
    };

    Baseliner.portalAddCompUrl = function( params ){
        Baseliner.ajaxEval( params.url_portlet, { }, function(comp) {
            Baseliner.portalAddComp({ comp: comp, portlet_type: 'comp',
                col: params.col, url_portlet: params.url_portlet, url_max: params.url_max });
        });
    };

    Baseliner.portalNextColumn = function(){
        Baseliner.portalConfig.last_col++;
        if( Baseliner.portalConfig.last_col > Baseliner.portalConfig.col_number )
            return 1;
        else 
            return Baseliner.portalConfig.last_col;
    };

    Baseliner.portalAddComp = function( params ) {
        var col = params.col || Baseliner.portalNextColumn();
        var comp = params.comp;
        comp.height = comp.height || 350;
        var title = comp.title || params.title || 'Portlet';
        comp.collapsible = true;
        var colobj = Baseliner.portal.findById('baseliner-portal-column-' + col);
        var portlet = {
            collapsible: true,
            title: title,
            portlet_type: params.portlet_type,
            tools: Baseliner.portalTools,
            //url_portlet: params.url_portlet,
            url_max: params.url_max,
            items: comp
        };
        colobj.add( portlet );
        //colobj.add(comp);
        colobj.doLayout();
        Baseliner.portal.doLayout();
    };

