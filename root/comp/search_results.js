(function(params){
    var query = params.query;
    var panel = new Ext.Panel({ title: _('Search: %1', query ) });

    Baseliner.ajaxEval( '/search/providers', {}, function(res) {
        var provs = res.providers;
        for( var i=0; i < provs.length; i++ ) {
            var provider = provs[ i ];
            Baseliner.ajaxEval( '/search/query', { provider: provider, query: query },
                function(res_query) {
                    var results = res_query.results;
                    for( var ir=0; ir < results.length; ir++ ) {
                        var r = results[ir];
                        var url;
                        if( r.type == 'log' ) {
                            url = 'javascript:Baseliner.openLogTab(' + r.url[0] + ", '" + r.url[1] + "' )";
                        }
                        var block = '<div id="search-result-block">'
                            + '<div id="search-result-block-title">';
                        if( url != undefined ) {
                            block += res_query.name + ": " +  '<a href="' + url + '">' + r.title + '</a>';
                        } else {
                            block += res_query.name + ": " +  r.title;
                        }

                        block += '</div>'
                            +  r.text
                            + '</div>'
                            ;
                        panel.add( { xtype: 'container', html: block } );
                        panel.doLayout();
                    }
                }
            );
        }
    });
    return panel;
})

