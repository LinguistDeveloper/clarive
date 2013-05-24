(function(params){
    var query = params.query;
    //var date = new Date();
    //var mins = date.getHours()*60 + date.getMinutes();
    //var id_date = ['search',date.getFullYear(),date.getMonth(),date.getDay(), mins].join('-');
    //var panel_prev = Ext.getCmp( id_date );
    var panel_prev;
    var current_tab = Baseliner.tabpanel().getActiveTab();
    if( current_tab.id && current_tab.id.indexOf('search-') == 0 ) {
        panel_prev = current_tab;
        panel_prev.removeAll();
        panel_prev.setTitle( query );
    }
    //var panel = panel_prev ? panel_prev
        //: new Ext.Panel({
    var panel = new Ext.Panel({
        title: query, 
        layout:'column',
        id: 'search-' + Ext.id(),
        overflow:'auto', 
        style:{ margin: 45, padding: 30 } });
    
    var toptpl = '<div id="boot"><h6>{0}</h6><h7>{1}</h7></div>';
    Baseliner.ajaxEval( '/search/providers', {}, function(res) {
        var provs = res.providers;
        for( var i=0; i < provs.length; i++ ) {
            var provider = provs[ i ];
            var prov_wait = new Ext.Container({
                html: String.format( toptpl, _(provider.name), _('searching...') ),
                style: 'border-bottom: 1px solid #ddd; margin: 0 0 15 10'
                
            });
            var prov_panel = new Ext.Container({ columnWidth: 1/provs.length, style:{ margin:'0 70 0 7' } });
            prov_panel.add( prov_wait );
            panel.add( prov_panel );
            panel.doLayout();
            Baseliner.ajaxEval( '/search/query', { provider: provider.pkg, query: query },
                function(res_query, scope ) {
                    //console.log( res_query );
                    var prov_panel = scope[0];
                    var prov_wait = scope[1];
                    var provider = scope[3];
                    prov_wait.el.update( String.format(toptpl, _(res_query.name), _('%1 results, elapsed %2s', res_query.results.length, res_query.elapsed) ) );
                    //panel.remove( prov_wait );
                    var results = res_query.results;
                    for( var ir=0; ir < results.length; ir++ ) {
                        var r = results[ir];
                        var url;
                        if( r.type == 'topic' ) {
                            r.title = ['<table><tr><td>', Baseliner.topic_name({ category_name:r.url[1], category_color:r.url[2] }),
                                '&nbsp;</td><td><h4>', r.title, '</h4></td></tr></table>' ].join(''); 
                        }
                        var block = '<div id="boot" style="margin:4"><div id="search-result-block">'
                            + '<div id="search-result-block-title"><h4>'
                            + r.title
                            + '</h4>'
                            + '</div>';
                        block +=  '<p style="color:#aaa;margin: 6 0 0 100">' + r.info + '</p>';
                        block +=  '<p>' + ( r.excerpt ? r.excerpt : r.text ) + '</p>'
                            + '</div></div>'
                            ;
                        var hit_panel = new Ext.Container({ html: block, style:'padding-right:20px; cursor:pointer; border: 1px solid #fff;', name: 'search-result' });
                        hit_panel.url = r.url;
                        hit_panel.type = r.type;
                        hit_panel.on('afterrender', function(){
                            hit_panel.el.on('mouseover', function(){
                                this.setStyle('border', '1px dashed #999');
                            });
                            hit_panel.el.on('mouseout', function(){
                                this.setStyle('border', '1px solid #fff');
                            });
                            hit_panel.el.on('click', function(){
                                var id = this.dom.id;
                                var r = Ext.getCmp( id );
                                if( r ) {
                                    if( r.type == 'log' ) {
                                        Baseliner.openLogTab( r.url[0], r.url[1] );
                                    }
                                    else if( r.type == 'topic' ) {
                                        Baseliner.add_tabcomp( "/topic/view?topic_mid=" + r.url[0] , r.url[1], { topic_mid: r.url[0], title:r.url[1] } );
                                    }
                                }
                            });
                        });
                        prov_panel.add( hit_panel );
                        prov_panel.doLayout();
                    }
                }, [prov_panel,prov_wait,provider]
            );
        }
    });
    return panel;
})

