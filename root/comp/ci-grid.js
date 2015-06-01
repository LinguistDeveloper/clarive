(function(params){
    //alert( JSON.stringify( params ) );
    var ps = 20;
    var store_ci = new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        url: '/ci/grid',
        baseParams: Ext.apply({ start:0, limit: ps}, params),
        fields: [ 'mid','_id','_parent','_is_leaf','type', 'item','class','versionid','ts','tags','data','properties','icon','collection']
    });
    var search_field = new Baseliner.SearchField({
        store: store_ci,
        params: {start: 0, limit: ps },
        emptyText: _('<Enter your search string>')
    });
    
    /*  Renderers */
    var render_tags = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( typeof value == 'object' ) {
            var va = value.slice(0); // copy array
            return Baseliner.render_tags( va, metadata, rec );
        } else {
            return Baseliner.render_tags( value, metadata, rec );
        }
    };
    var render_item = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( rec.data.type == 'class' ) {
            // we create objects
            value = String.format('<a href="#" onclick="Baseliner.ci_add({0})">{1}</a>', rowIndex, value );
        }
        value = '<table><tr><td width="1"><img style="margin-top:-2px" src="' + rec.data.icon + '" alt="" /></td><td>' + value + '</td></tr></table>';
        return value;
    };
    var render_properties = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( value == undefined ) return '';
        return '<pre style="font-size:9px">' + value + '</pre>';
    };
    var render_mapping_long = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( value == undefined ) return '';
        if( typeof value == 'string' ) return '';
        var ret = '';
        var k = 0;
        var ary =[];
        for( var k in value ) {
            if( value[k]==undefined ) value[k]='';
            if( value[k]=='' ) continue;
            ary.push( String.format('<b>{0}</b>: <code>{1}</code>',  _(k), value[k] ) );
        }
        return ary.join(', ');
    };
    var render_mapping = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( value == undefined ) return '';
        if( typeof value == 'string' ) return '';
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

    var check_sm = new Ext.grid.CheckboxSelectionModel({
        singleSelect: false,
        sortable: true,
        checkOnly: true
    });

    var grid = new Ext.grid.GridPanel({
        title: _('CI: %1', params.item),
        store: store_ci,
        sm: check_sm,
        tbar: [ search_field,
            { xtype:'button', text: 'Crear', icon: '/static/images/icons/edit.gif', cls: 'x-btn-text-icon' },
            { xtype:'button', text: 'Borrar', icon: '/static/images/icons/delete_.png', cls: 'x-btn-text-icon' },
            { xtype:'button', text: 'Etiquetar', icon: '/static/images/icons/tag.gif', cls: 'x-btn-text-icon' },
            { xtype:'button', text: 'Exportar', icon: '/static/images/icons/downloads_favicon.png', cls: 'x-btn-text-icon' }
        ],
        bbar: new Ext.PagingToolbar({
            store: store_ci,
            pageSize: ps,
            displayInfo: true,
            displayMsg: _('Rows {0} - {1} of {2}'),
            emptyMsg: _('There are no rows available')
        }),        
        columns:[
            check_sm,
            { width: 16, hidden: true, dataIndex: 'icon', renderer: Baseliner.render_icon, sortable: true },
            { id:'item', header: _('Item'), dataIndex: 'item', width: 230, renderer: render_item, sortable: true },
            { header: _('Collection'), width: 160, dataIndex: 'collection', sortable: true},
            { header: _('ID'), width: 30, dataIndex: 'mid', sortable: true},
            { header: _('Class'), hidden: true, width: 160, dataIndex: 'class', sortable: true},
            { header: _('Version'), width: 50, dataIndex: 'versionid', sortable: true},
            { header: _('Timestamp'), width: 80, dataIndex: 'ts', sortable: true},
            { header: _('Tags'), width: 140, dataIndex: 'tags', renderer: render_tags, sortable: true},
            { header: _('Properties'), hidden: true, width: 250, dataIndex: 'properties', renderer: render_properties, sortable: true},
            { header: _('Data'), hidden: false, width: 250, dataIndex: 'data', renderer: render_mapping_long }
        ]
    });
    if( Baseliner.explorer ) {
        var click_foo = function(n, ev){ 
            if( ! grid.isVisible() ) return;
            var data = n.attributes.data;
            if( data.class == undefined ) return;
            grid.setTitle(_('CI: %1', data.item ) );
            store_ci.load({ params: data });
        };
        Baseliner.explorer.on('click', click_foo );
        grid.on('destroy', function(){
            Baseliner.explorer.removeListener('click', click_foo );
        });
    }

    //store_ci.load();
    return grid;
})

