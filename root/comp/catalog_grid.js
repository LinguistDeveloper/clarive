// Catalog Grid
(function(){
    var ps = 100;

    var reader_cat = new Ext.data.JsonReader({
            root: 'data',
            remoteSort: true,
            totalProperty:'totalCount',
            id: 'id'
        },[ 
            { name: 'pkg' },   
            { name: 'url' },   
            { name: 'url_save' },   
            { name: 'icon' },   
            { name: 'project' },   
            { name: 'id' },   
            { name: 'ns' },   
            { name: 'bl' },   
            { name: 'name' },   
            { name: 'active' },   
            { name: 'description' },   
            { name: 'type' },   
            { name: 'for' },   
            { name: 'mapping' },   
            { name: 'row' }
        ]
    );

    var store = new Baseliner.GroupingStore({
        id: 'id',
        reader: reader_cat,
        remoteGroup: true,
        url: '/catalog/json',
        groupField: 'type'
    });

    var expanded = false;
    store.on( 'load', function(s) {
        if( store.getTotalCount() < 20 ) {
            gview.toggleAllGroups( true );
            expanded = true;
        }
    });
    var button_expand = Baseliner.img_button( '/static/images/icons/expandall.gif', function(){
            expanded = ! expanded;
            gview.toggleAllGroups( expanded );
            if( expanded ) {
                button_expand.setIconClass( 'expandall' );
            } else {
                button_expand.setIconClass( 'collapseall' );
            }
        }
    );

    var store_types=Baseliner.new_jsonstore({ url:'/catalog/types', fields:[ 'name', 'url', 'icon' ] });

    <& /comp/search_field.mas &>

    var render_for = function(value,metadata,rec,rowIndex,colIndex,store) {
        var ret = '<table>';
        for( var k in value ) {
            if( value[k]==undefined ) value[k]='';
            ret += '<tr>'; 
            ret += '<td style="font-weight: bold;padding: 3px 3px 3px 3px;">' + _(k) + '</td>'
            ret += '<td width="80%" style=" background: #f5f5f5;padding: 3px 3px 3px 3px;"><code>' + value[k] + '</code></td>'
            ret += '</tr>'; 
        }
        ret += '</table>';
        return ret;
    };
    var render_icon = function(value,metadata,rec,rowIndex,colIndex,store) {
        var active = rec.data.active;
        if( active!=undefined && !active ) {
            value = '/static/images/icons/inactive.gif';
        }
        return Baseliner.render_icon( value, metadata, rec, rowIndex, colIndex, store );
    }
    var render_name = function(value,metadata,rec,rowIndex,colIndex,store) {
        var active = rec.data.active;
        if( ! active ) {
            return '<del>' + value + '</del>';
        }
        var ret = Baseliner.columnWrap( value, metadata, rec, rowIndex );
        ret = '<b>' + ret + '</b>';
        return ret;
    };
    var render_mapping = function(value,metadata,rec,rowIndex,colIndex,store) {
        var ret = '<table>';
        for( var k in value ) {
            if( value[k]==undefined ) value[k]='';
            ret += '<tr>'; 
            ret += '<td style="font-weight: bold;padding: 3px 3px 3px 3px;">' + _(k) + '</td>'
            ret += '<td width="80%" style=" background: #f5f5f5;padding: 3px 3px 3px 3px;"><code>' + value[k] + '</code></td>'
            ret += '</tr>'; 
        }
        ret += '</table>';
        return ret;
    };
    var close_event = function(win){
        if( win.rc ) {
            store.load();
        }
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
        // TODO get a fresh row to edit
        if( sel.data.row.active == undefined ) sel.data.row.active = true;
        Baseliner.add_wincomp( sel.data.url, _(sel.data.name), sel.data.row, { event:'close', func: close_event } );
    } ;
    var button_edit = Baseliner.button(_('Modify'), '/static/images/icons/write.gif', edit_action ); 
    var button_clone = Baseliner.button(_('Clone'), '/static/images/icons/copy.gif', function(){
        var sel = sm.getSelected();
        if( sel == undefined ) return ; 
        if( sel.data.row['id'] != undefined ) sel.data.row['id'] = '';
        Baseliner.add_wincomp( sel.data.url, _(sel.data.name), sel.data.row, { event:'close', func: close_event } );
    } ); 

    // YAML editor
    var button_raw = Baseliner.button(_('YAML'), '/static/images/icons/yaml.gif', function(){
        var sel = sm.getSelected();
        if( sel == undefined ) return ; 
        var sel_save_url = sel.data.url_save;
        Baseliner.ajaxEval( '/to_yaml', sel.data.row, function(res) {
            var ta = new Ext.form.TextArea({
                height: 500,
                width: 600,
                style: { 'font-family': 'Consolas, Courier, monotype' },
                value: res.yaml
            });
            var win = new Ext.Window({
                title: _("YAML"),
                tbar: [ 
                    { xtype:'button', text: _('Save'), iconCls:'x-btn-text-icon', icon:'/static/images/icons/write.gif',
                        handler: function(){
                            // convert the yaml text to a json object
                            Baseliner.ajaxEval('/from_yaml', { yaml: ta.getValue() }, function(res) {
                                if( ! res.success ) {
                                    Baseliner.error( _('YAML'), res.msg );
                                } else if( res.json != undefined ) {
                                    // save obj to its original controller
                                    Baseliner.ajaxEval( sel_save_url, res.json, function(res) {
                                        if( !res.success ) {
                                            Baseliner.error( _('YAML'), res.msg );
                                        } else {
                                            // saved ok
                                            Baseliner.message( _('YAML'), res.msg );
                                            store.load();
                                        }
                                    });
                                } else {
                                    Baseliner.error( _('YAML'), _('Generated JSON not available') );
                                }
                            });
                        }
                    }
                ],
                items: ta
            });
            win.show();
        });
    } ); 
    var button_by_project = new Ext.Button({
       text: _('Project'),
       icon: '/static/images/icons/project.gif',
       cls: 'x-btn-text-icon',
       pressed: false,
       toggleGroup: 'grouping',
       enableToggle: true,
       toggleHandler: function() {
           store.groupBy('project');
       } 
    });
    var button_by_type = new Ext.Button({
       text: _('Type'),
       icon: '/static/images/icons/catalog.gif',
       cls: 'x-btn-text-icon',
       pressed: true,
       enableToggle: true,
       toggleGroup: 'grouping',
       toggleHandler: function() {
           store.groupBy('type');
       } 
    });

    var sm = new Ext.grid.RowSelectionModel({singleSelect:true});

    var gview = new Ext.grid.GroupingView({
        forceFit: true,
        enableRowBody: true,
        autoWidth: true,
        autoSizeColumns: true,
        deferredRender: true,
        startCollapsed: true,
        hideGroupedColumn: true
        //groupTextTpl: '{[ values.rs[0].data["' + 'project' + '"] ]}'
    });

    var grid = new Ext.grid.GridPanel({
        title: _('Catalog'),
        view: gview,
        store: store,
        sm: sm,
        loadMask:'true',
        viewConfig: {
            forceFit: true
        },
        tbar: [ 
            button_expand,
            _('Search') + ': ', ' ',
            new Ext.app.SearchField({
                store: store,
                params: {start: 0, limit: ps },
                emptyText: _('<Enter your search string>')
            }),
            Baseliner.img_button( '/static/images/icons/refresh.gif', function(){ store.load() } ),
            button_add, button_del, button_edit, button_clone, button_raw,
            '->', _('Grouping') + ':', button_by_type, button_by_project 
        ],
        columns: [
            { hidden: false, width: 30, dataIndex: 'icon', sortable: false, renderer: render_icon  },   
            { header: _('Name'), width: 120, dataIndex: 'name', sortable: true, renderer: render_name },   
            { header: _('Project'), width: 80, dataIndex: 'project', sortable: true, renderer: Baseliner.render_ns },   
            { header: _('Environment'), width: 60, dataIndex: 'bl', sortable: true, renderer: Baseliner.render_bl },   
            { header: _('For'), width: 200, dataIndex: 'for', sortable: true, renderer: render_for },   
            { header: _('Mapping'), width: 200, dataIndex: 'mapping', sortable: true, renderer: render_mapping },
            { header: _('Type'), hidden: true, width: 120, dataIndex: 'type', sortable: true },   
            { header: _('Catalog'), hidden: true, width: 120, dataIndex: 'catalog_name', sortable: true },   
            { header: _('ID'), hidden: true, width: 120, dataIndex: 'id', sortable: true },   
            { header: _('Description'), width: 120, dataIndex: 'description', sortable: true, renderer: Baseliner.columnWrap },   
            { header: _('Package'), hidden: true, width: 120, dataIndex: 'pkg', sortable: true }
        ]
    });
    grid.on('rowdblclick', function(){ edit_action(); });
    var activated = false;
    grid.on('activate', function() {
        if( !activated ) { store.load(); activated=true } } );
    //store.load();
    function getGrid() { return grid };
    return grid;
})()
