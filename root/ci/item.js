(function(params){
    var f = params.form;
    var rec = params.rec || {};
    
    // Parse tree grid
    var store = new Ext.data.SimpleStore({
        fields: ['tag','type',{ name:'line', type:'integer'} ],
        sortInfo: { field: 'line', direction: 'ASC'} ,
        data: []
    });
    var tree = new Ext.grid.GridPanel({
        store: store,
        viewConfig: {
            headersDisabled: false,
            //enableRowBody: true,
            forceFit: true
        },
        columns: [
          { header: _('Token'), width: 120, dataIndex: 'tag', sortable:true, renderer:function(v){ return '<b>'+v+'</b>' } },
          { header: _('Type'), width: 120, dataIndex: 'type', sortable:true  },
          { header: _('Line'), width: 120, dataIndex: 'line', sortable:true }
        ],
        anchor:'100%',
        height: 280,
        border: false,
        frame: true,
        fieldLabel: _('Parse Tree')
    });
    Ext.each( rec.parse_tree, function(rt){
        var tag,type,line;
        for( var k in rt ) {
            if( k=='line' ) {
                line = rt[ k ];
            } else {
                tag = rt[k];
                type = k;
            }
        }
        if( line == undefined ) line = '--';
        var r = new store.recordType({ tag: tag, type: type, line: line });
        store.add( r );
        store.commitChanges();
    });
    store.sort('line', 'ASC');
    
    return [
       { xtype:'textfield', fieldLabel: _('Directory'), name:'dir', allowBlank: true, anchor: '100%' },
       { xtype:'textfield', fieldLabel: _('Path'), name:'path', allowBlank: true, anchor: '100%' },
       { xtype:'textfield', fieldLabel: _('Directory?'), name:'is_dir', allowBlank: true, anchor: '100%'},
       tree
    ]
})

