/*
name: revisions
params:
    id_field: 'revisions'
    origin: 'rel'
    html: '/fields/field_revisions.html'
    js: '/fields/field_revisions.js'
    field_order: 12
    section: 'details'
    set_method: 'set_revisions'
    rel_field: 'revisions'
    method: 'get_revisions'
---
*/
(function(params){
    var revision_store = new Ext.data.SimpleStore({
        fields: ['mid','name','id']
    });
    
    var revision_grid = new Ext.grid.GridPanel({
        store: revision_store,
        layout: 'form',
        height: 120,
        fieldLabel: _('Revisions'),
        hideHeaders: true,
        viewConfig: {
            headersDisabled: true,
            enableRowBody: true,
            //scrollOffset: 2,
            forceFit: true
        },
        columns: [
          //{ header: _('ID'), width: 60, hidden: true, dataIndex: 'id' },
          { header: '', width: 20, dataIndex: 'id', renderer: function(){ return '<img style="float:right" src="/static/images/icons/tag.gif" />'} },
          { header: _('Name'), width: 240, dataIndex: 'name',
              renderer: function(v,metadata,rec){
                  return Baseliner.render_wrap( String.format('<a href="javascript:Baseliner.show_revision({1})"><span id="boot"><h5>{0}</h5></span></a>', v, rec.data.mid ) );
              }
          },
          { width: 20, dataIndex: 'mid',
              renderer: function(v,meta,rec,rowIndex){
                  return '<a href="javascript:Baseliner.delete_revision_row(\''+revision_grid.id+'\', '+v+')"><img style="float:middle" height=16 src="/static/images/icons/clear.png" /></a>'
              }
          },

        ]
    });
    
    // a hidden form field, needed for this to save data in a form
    var field = new Ext.form.TextField({ hidden: true, name:'revisions' });
    var refresh_field = function(){
        var mids = [];
        revision_store.each(function(row){
            mids.push( row.data.mid ); 
        });
        field.setValue( mids.join(',') );
    };

    // Load data
    if( ! params ) params = {};
    if( ! params.topic_data ) params.topic_data = {};
	var data = params.topic_data.revisions || [];
    Ext.each( data, function(row){
        var r = new revision_store.recordType( row, row.mid );
        revision_store.add( r );
        revision_store.commitChanges();
        refresh_field();
    });
    
    Baseliner.delete_revision_row = function( id_grid, mid ) {
        var g = Ext.getCmp( id_grid );
        var s = revision_grid.getStore();
        s.each( function(row){
            if( row.data.mid == mid ) {
                s.remove( row );
            }
        });
        refresh_field();
    };

    revision_grid.on( 'afterrender', function(){
        //if( c.value != undefined ) {
            // TODO no loader from mids yet 
        //}
        var el = this.el.dom; 
        var revision_box_dt = new Ext.dd.DropTarget(el, {
            ddGroup: 'lifecycle_dd',
            copy: true,
            notifyDrop: function(dd, e, id) {
                var n = dd.dragData.node;
                //var s = project_box.store;
                var attr = n.attributes;
                var data = attr.data || {};
                var ci = data.ci;
                var mid = data.mid;
                if( mid==undefined && ( ci == undefined || ci.role != 'Revision') ) { 
                    Baseliner.message( _('Error'), _('Node is not a revision'));
                } 
                else if ( mid!=undefined ) {
                    // TODO
                }
                else if ( ci !=undefined ) {
                    Baseliner.ajaxEval('/ci/sync',
                        { name: ci.name, 'class': ci['class'], ns: ci.ns, ci_json: Ext.util.JSON.encode( ci.data ) },
                        function(res) {
                            if( res.success ) {
                                var mid = res.mid ;
                                var d = { name: attr.text, id: mid, mid: mid };
                                var r = new revision_store.recordType( d, mid );

                                revision_store.add( r );
                                revision_store.commitChanges();
                                refresh_field();
                            }
                            else {
                                Ext.Msg.alert( _('Error'), _('Error adding revision %1: %2', ci.name, res.msg) );
                            }
                        }
                    );
                }
                return (true); 
             }
        });
    }); 
	return [
        revision_grid, field
        //revision_box
    ]
})
