(function(params) {
    var repo_path = '<% $c->stash->{repo_path} %>';
    var repo_type = '<% $c->stash->{collection} %>';
    var bl = '<% $c->stash->{bl} %>';
    var store = {
        reload: function() {
           tree.root.reload(); 
        }
    };
    <& /comp/search_field.mas &>
    var search_field = new Ext.app.SearchField({
        store: store,
        params: {start: 0, limit: 100 },
        emptyText: _('<Enter your search string>')
    });
    var render_tags = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( typeof value == 'object' ) {
            var va = value.slice(0); // copy array
            return Baseliner.render_tags( va, metadata, rec );
        } else {
            return Baseliner.render_tags( value, metadata, rec );
        }
    };
    var render_mapping = function(value,metadata,rec,rowIndex,colIndex,store) {
        var ret = '<table>';
        ret += '<tr>'; 
        var k = 0;
        for( var k in value ) {
            if( value[k]==undefined ) value[k]='';
            ret += '<td style="font-size: 10px;font-weight: bold;padding: 1px 3px 1px 3px;">' + _(k) + '</td>'
            ret += '<td width="80px" style="font-size: 10px; background: #f5f5f5;padding: 1px 3px 1px 3px;"><code>' + value[k] + '</code></td>'
            if( k % 2 ) {
                ret += '</tr>'; 
                ret += '<tr>'; 
            }
        }
        ret += '</table>';
        return ret;
    };
    var tree = new Ext.ux.tree.TreeGrid({
        region: 'center',
        width: 500,
        height: 300,
        lines: true,
	    stripeRows: true,
        enableSort: false,
        enableDD: true,
        dataUrl: '/lifecycle/repo_data',
        //dataUrl: '/cia/data.json',
        tbar: [ search_field ],
        columns:[
            {
                header: 'Item',
                dataIndex: 'item',
                width: 230
            },
            {
                header: 'Size',
                width: 120,
                dataIndex: 'size'
            },
            {
                header: 'Version',
                width: 80,
                dataIndex: 'version'
            },
            {
                header: _('Tags'),
                width: 140,
                tpl: new Ext.XTemplate('{tags:this.renderer}', {
                    renderer: function(v) {
                        if( v== undefined ) return '';
                        return render_tags(v);
                    }
                }),
                dataIndex: 'tags'
            },
            {
                header: 'Properties',
                width: 250,
                tpl: new Ext.XTemplate('{properties:this.renderer}', {
                    renderer: function(v) {
                        if( v== undefined ) return '';
                        return render_mapping(v);
                    }
                }),
                dataIndex: 'properties'
            }
        ]
    });
    tree.getLoader().on("beforeload", function(treeLoader, node) {
        var loader = tree.getLoader();
        loader.baseParams = { path: node.attributes.path, repo_path: repo_path, bl: bl, repo_type: repo_type, leaf: node.leaf };
    });

    tree.on('dblclick', function(node, ev){
        show_properties( node.attributes.path, node.attributes.item, node.attributes.version, node.leaf );
    });

    var show_properties = function( path, name, version, leaf ) {
        Baseliner.ajaxEval('/comp/view_file.js', { repo_dir: repo_path, file: path, rev_num: version, controller: 'plastictree' }, function(comp){
            //var style_cons = 'background-color: #000; background-image: none; color: #10C000; font-family: "DejaVu Sans Mono", "Courier New", Courier';
            comp.setTitle(name);
            comp.closable = true;
            properties.add(comp);
            properties.setActiveTab(comp);
            properties.changeTabIcon( '/static/images/moredata.gif' ); 
            properties.expand();
        });
        //properties_load(output,{ pane: properties.pane, path: path, version: version, ref: bl, repo_path: repo_path });
    };

    var tpl_hist = new Ext.XTemplate(
        '<div style="width:50%;margin-bottom: 4px; padding: 5px 5px 5px 5px; background-color: #ddd;">'
        + '<table cellpadding="5">'
        + '<tr><td>Commit:</td><td></td>&nbsp;<td>{commit}</td></tr>'
        + '<tr><td>Revisi&oacute;n:</td><td></td>&nbsp;<td>{revs}</td></tr>'
        + '<tr><td>Autor:</td><td></td>&nbsp;<td>{author}</td></tr>'
        + '<tr><td>Fecha:</td><td></td>&nbsp;<td>{date}</td></tr>'
        + '</table>'
        + '</div>');
    
    var properties_load = function( panel, args ) {

        if(repo_type == 'PlasticRepository'){
        }else{
            Baseliner.ajaxEval( '/lifecycle/file', args, function(res){
                if( res == undefined ) return;
                if( res.info == undefined ) return;
                if( res.pane == 'hist' ) {
                    for( var i = 0; i < res.info.length ; i++ ) {
                        //panel.update({ data: res.info[i] });
                        panel.update('');
                        var row = res.info[i];
                        panel.add({ xtype:'component', tpl: tpl_hist, data: row });
                    }
                    //panel.update( '<pre>' + res.info.join('\n') + '</pre>' );
                }
                else if( res.pane == 'diff' ) {
                    panel.update('');
                    panel.update( '<pre>' + res.info.join('\n') + '</pre>' );
                }
                else if( res.pane == 'source' ) {
                    panel.update('');
                    panel.update( '<pre>' + res.info.join('\n') + '</pre>' );
                }
                else {
                    Baseliner.message( 'Error', 'No pane' );
                }
            });
        }
    };

    var properties = new Ext.TabPanel({
        //collapsible: true,
        defaults: { closable: true, autoScroll: true }, 
        split: true,
        activeTab: 0,
        enableTabScroll: true,
        layoutOnTabChange: true,
        autoScroll: true,
        collapsed: true,
        height: 350,
        tbar: [
            Baseliner.button('Close All', '/static/images/icons/clear.gif', function(b) { 
                properties.items.each(function(comp) {
                    if( comp.closable ) {
                        properties.remove( comp );
                        comp.destroy();
                    }
                    properties.items.getCount()==0 && properties.collapse();
                });
            }),
            Baseliner.button('Maximize', '/static/images/icons/application_double.png', function(b) { 
                var tab = properties.getActiveTab();
                if( tab.initialConfig.closable ) {
                    Baseliner.addNewTabItem( tab, '' );
                } else {
                    var to = new Ext.form.TextArea({ title: 'Output', value: output.getValue() });
                    Baseliner.addNewTabItem( to , '' );
                }
            }),
            '->',
            Baseliner.button('Collapse', '/static/images/icons/arrow_down.gif', function(b) { properties.collapse(true) } )
        ],
        region: 'south'
    });

    var panel = new Ext.Panel({
        layout: 'border',
        items: [
			    tree,
			    properties ]
    });
    return panel;
})

