// Catalog Grid
(function(){
    var ps = 100;
    var store=new Ext.data.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id', 
        url: '/catalog/json',
        baseParams: {  start: 0, limit: ps },
        fields: [ 'pkg','url','icon', 'project',
            'id', 'ns', 'bl', 'name', 'description', 'type', 'for', 'mapping', 'row' ]
    });
    var store_types=Baseliner.new_jsonstore({ url:'/catalog/types', fields:[ 'name', 'url', 'icon' ] });

    <& /comp/search_field.mas &>

    var render_for = function(value,metadata,rec,rowIndex,colIndex,store) {
        var ret = '<table>';
        for( var k in value ) {
            if( value[k]==undefined ) value[k]='';
            ret += '<tr>'; 
            ret += '<td style="font-weight: bold;padding: 3px 3px 3px 3px;">' + _(k) + '</td>'
            ret += '<td width="80%" style=" background: #f5f5f5;padding: 3px 3px 3px 3px;"><pre>' + value[k] + '</pre></td>'
            ret += '</tr>'; 
        }
        ret += '</table>';
        return ret;
    };
    var render_mapping = function(value,metadata,rec,rowIndex,colIndex,store) {
        var ret = '<table>';
        for( var k in value ) {
            if( value[k]==undefined ) value[k]='';
            ret += '<tr>'; 
            ret += '<td style="font-weight: bold;padding: 3px 3px 3px 3px;">' + _(k) + '</td>'
            ret += '<td width="80%" style=" background: #f5f5f5;padding: 3px 3px 3px 3px;"><pre>' + value[k] + '</pre></td>'
            ret += '</tr>'; 
        }
        ret += '</table>';
        return ret;
    };
    var close_event = function(){
        store.load();
    };
    var menu_add = new Ext.menu.Menu({ });
    store_types.on('load', function(){
        menu_add.removeAll();
        store_types.each(function(rec){
            menu_add.add({ text: _(rec.data.name), icon: rec.data.icon, url: rec.data.url, handler: function(m){
                Baseliner.add_wincomp( m.url, _(m.text), { }, { event:'close', func: close_event } );
            } });
        });
    });
    store_types.load();
    var button_add = new Ext.Button({ text: _('Add'), menu: menu_add , icon: '/static/images/icons/new.gif', cls: 'x-btn-text-icon' });
    var button_del = Baseliner.button(_('Delete'), '/static/images/icons/delete.gif', function(){
        var sel = sm.getSelected();
        if( sel == undefined ) return ; 
        var row = sel.data;
        row.confirm = _('Are you sure you want to delete %1 from catalog?', '<b>' + row.name + '</b>' );
        Baseliner.ajaxEval( '/catalog/delete', row, 
            function(res) {
                store.load();
            }
        );
    } ); 
    var edit_action = function(){
        var sel = sm.getSelected();
        if( sel == undefined ) return ; 
        if( sel.data.row['id'] == undefined ) sel.data.row['id'] = sel.data.id;
        Baseliner.add_wincomp( sel.data.url, _(sel.data.name), sel.data.row, { event:'close', func: close_event } );
    } ;
    var button_edit = Baseliner.button(_('Modify'), '/static/images/icons/write.gif', edit_action ); 
    var button_clone = Baseliner.button(_('Clone'), '/static/images/icons/copy.gif', function(){
        var sel = sm.getSelected();
        if( sel == undefined ) return ; 
        if( sel.data.row['id'] != undefined ) sel.data.row['id'] = '';
        Baseliner.add_wincomp( sel.data.url, _(sel.data.name), sel.data.row, { event:'close', func: close_event } );
    } ); 

    var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
    var grid = new Ext.grid.EditorGridPanel({
        title: _('Catalog'),
        sm: sm,
        tbar: [ _('Search') + ': ', ' ',
            new Ext.app.SearchField({
                store: store,
                params: {start: 0, limit: ps },
                emptyText: _('<Enter your search string>')
            }),
            Baseliner.button( '', '/static/images/icons/refresh.gif', function(){ store.load() } ),
            button_add, button_del, button_edit, button_clone
        ],
        store: store,
        viewConfig: {
            forceFit: true
        },
        loadMask:'true',
        columns: [
            { hidden: false, width: 30, dataIndex: 'icon', sortable: true, renderer: Baseliner.render_icon  },   
            { header: _('Project'), width: 80, dataIndex: 'project', sortable: true, renderer: Baseliner.render_ns },   
            { header: _('Environment'), width: 60, dataIndex: 'bl', sortable: true, renderer: Baseliner.render_bl },   
            { header: _('For'), width: 200, dataIndex: 'for', sortable: true, renderer: render_for },   
            { header: _('Mapping'), width: 200, dataIndex: 'mapping', sortable: true, renderer: render_mapping },
            { header: _('Name'), width: 120, dataIndex: 'name', sortable: true, renderer: Baseliner.columnWrap },   
            { header: _('Type'), hidden: true, width: 120, dataIndex: 'type', sortable: true },   
            { header: _('ID'), hidden: true, width: 120, dataIndex: 'id', sortable: true },   
            { header: _('Description'), width: 120, dataIndex: 'description', sortable: true, renderer: Baseliner.columnWrap },
            { header: _('Package'), hidden: true, width: 120, dataIndex: 'pkg', sortable: true }
        ]
    });
    grid.on('rowdblclick', function(){ edit_action(); });
    store.load();
    return grid;
})()
