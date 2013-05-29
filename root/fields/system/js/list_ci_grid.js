/*
name: CI Grid
params:
    html: '/fields/system/html/field_ci_grid.html'
    js: '/fields/system/js/list_ci_grid.js'
    relation: 'system'
    rel_type: topic_ci
    type: 'listbox'
    get_method: 'get_cis'    
    set_method: 'set_topics'
    field_order: 100
    section: 'details'
    single_mode: 'false'    
---
*/
(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
    
    var topic_mid = params.topic_data.topic_mid;
    
    //var ci_store = new Baseliner.store.CI({ baseParams: { class:'item', rel_type: meta.rel_type, mid: topic_mid } });
    var ci_store = new Ext.data.SimpleStore({
        fields: ['mid','name','versionid', 'icon', 'user' ],
        data: [
            [ 11, 'pase.pm', '34', '/static/images/icons/file.gif' , 'infroox'],
            [ 12, 'monitor.jsp', '12', '/static/images/icons/file.gif', 'infroox' ]
        ]
    });
    
    var cols = [
          { header: '', width: 30, dataIndex: 'icon', renderer: Baseliner.render_icon },
          { width: 20, dataIndex: 'mid', header: _('ID') },
          { header: _('Name'), width: 240, dataIndex: 'name', renderer: function(v){ return '<b>'+v+'</b>'} }
        ];
    if( meta.versions ) {
        cols.push( { header: _('Version'), width: 240, dataIndex: 'versionid' } );
        cols.push( { header: _('User'), width: 240, dataIndex: 'user' } );
    }
    
    var ci_grid = new Ext.grid.GridPanel({
        store: ci_store,
        layout: 'form',
        height: 220,
        fieldLabel: _(meta.name_field),
        hideHeaders: true,
		disabled: meta ? meta.readonly : true,
        viewConfig: {
            headersDisabled: true,
            enableRowBody: true,
            //scrollOffset: 2,
            forceFit: true
        },
        columns:  cols
    });
    
    ci_store.on('load', function(){
    });
    
	return [
        ci_grid
    ]
})

