(function(params) {
    var record = Ext.data.Record.create([ 'mid','_id','_parent','_is_leaf','type', 'item','class','versionid','ts','tags','data','properties','icon','collection']);
    var store_ci = new Ext.ux.maximgb.tg.AdjacencyListStore({  
       autoLoad : true,  
       url: '/ci/list',
       baseParams: {},
       reader: new Ext.data.JsonReader({ id: '_id', root: 'data', totalProperty: 'total', successProperty: 'success' }, record )
    }); 

    var search_field = new Baseliner.SearchField({
        store: store_ci, params: {start: 0, limit: 100 }, emptyText: _('<Enter your search string>')
    });

    Baseliner.ci_add = function( index ) {
        var rec = store_ci.getAt( index );
        if( rec == undefined ) return false;
        var classname = rec.data.class;
        var collection = rec.data.collection;
        var component = String.format('/ci/{0}.js' , collection );
        Baseliner.add_tabcomp( component, _('New %1' , classname), rec.data );
        return false;
    };

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
        sortable: false,
        checkOnly: true
    });

    var ci_grid = new Ext.ux.maximgb.tg.GridPanel({
        stripeRows: true,
        autoScroll: true,
        autoWidth: true,
        sortable: false,
        //header: false,
        //hideHeaders: true,
        store: store_ci,
        sm: check_sm,

        //enableSort: false,
        //lines: true,
        //enableDD: true,

        tbar: [ 
            //{ xtype: 'checkbox', handler: function(){ if( this.getValue() ) check_sm.selectAll(); else check_sm.clearSelections() } },
            search_field,
            { xtype:'button', text: _('Create'), cls: , icon: '/static/images/icons/edit.gif', cls: 'x-btn-text-icon' },
            { xtype:'button', text: _('Delete'), icon: '/static/images/icons/delete_.png', cls: 'x-btn-text-icon' },
            { xtype:'button', text: _('Tag This'), icon: '/static/images/icons/tag.gif', cls: 'x-btn-text-icon' },
            { xtype:'button', text: _('Export'), icon: '/static/images/icons/downloads_favicon.png', cls: 'x-btn-text-icon' }
        ],
        viewConfig: {
            //headersDisabled: true,
            enableRowBody: true,
            scrollOffset: 2,
            forceFit: true
        },
        master_column_id : 'item',
        autoExpandColumn: 'item',
        columns:[
            check_sm,
            { width: 16, hidden: true, dataIndex: 'icon', renderer: Baseliner.render_icon },
            { id:'item', header: _('Item'), dataIndex: 'item', width: 230, renderer: render_item },
            { header: _('Collection'), width: 160, dataIndex: 'collection' },
            { header: _('ID'), width: 30, dataIndex: 'mid' },
            { header: _('Class'), hidden: true, width: 160, dataIndex: 'class' },
            { header: _('Version'), width: 50, dataIndex: 'versionid' },
            { header: _('Timestamp'), width: 80, dataIndex: 'ts' },
            { header: _('Tags'), width: 140, dataIndex: 'tags', renderer: render_tags },
            { header: _('Properties'), hidden: true, width: 250, dataIndex: 'properties', renderer: render_properties },
            { header: _('Data'), hidden: false, width: 250, dataIndex: 'data', renderer: render_mapping_long }
        ],
        bbar: new Ext.ux.maximgb.tg.PagingToolbar({
            store: store_ci,
            displayInfo: true,
            pageSize: 10
        })
    });

    store_ci.on('beforeload', function(s,obj) {
        if( obj.params.anode!= undefined ) {
            var row = store_ci.getById( obj.params.anode );
            obj.params.mid = row.data.mid;
            obj.params.item = row.data.item;
            obj.params.type = row.data.type;
            obj.params.class = row.data.class;
        }
    });
    //store_ci.load();
    return ci_grid;
})

