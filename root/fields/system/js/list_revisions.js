/*
name: Revisions
params:
    html: '/fields/system/html/field_revisions.html'
    js: '/fields/system/js/list_revisions.js'
    relation: system
    type: 'listbox'
    field_order: 12
    height: 200
    section: 'details'
    get_method: 'get_revisions'
    set_method: 'set_revisions'
    meta_type: 'revision'
    branch:
---
*/
(function(params) {
    var data = params.topic_data;
    var meta = params.topic_meta;

    var topic_data = data;

    var allow = Baseliner.eval_boolean(meta.allowBlank);

    var revision_store = new Ext.data.SimpleStore({
        fields: ['mid', 'name', 'id']
    });

    var revision_grid = new Ext.grid.GridPanel({
        name: meta.id_field,
        fieldLabel: _(meta.name_field),
        allowBlank: allow,
        store: revision_store,
        layout: 'form',
        height: meta.height ? parseInt(meta.height) : 200,
        readOnly: Baseliner.eval_boolean(meta.readonly),
        hideHeaders: true,
        stripeRows: true,
        viewConfig: {
            headersDisabled: true,
            enableRowBody: true,
            forceFit: true
        },
        columns: [{
                header: '',
                width: 20,
                dataIndex: 'id',
                renderer: function() {
                    return '<img style="float:right" src="/static/images/icons/tag.svg" />';
                }
            }, {
                header: _('Name'),
                width: 240,
                dataIndex: 'name',
                renderer: function(v, metadata, rec) {
                    return Baseliner.render_wrap(
                        String.format(
                            '<a href="javascript:Baseliner.show_revision(\'{1}\')"><span id="boot"><h6>{0}</h6></span></a>',
                            v,
                            rec.data.mid
                        )
                    );
                }
            }, {
                width: 20,
                dataIndex: 'mid',
                renderer: function(v, meta, rec, rowIndex) {
                    var html = '<a href="javascript:Baseliner.delete_revision_row(\'' + revision_grid.id + '\', \'' + v + '\')">';
                    html += '<img style="float:middle" height=16 src="/static/images/icons/close.svg" /></a>';
                    return html;
                }
            }

        ]
    });

    revision_grid.get_save_data = function() {
        var mids = [];
        revision_store.each(function(row) {
            mids.push(row.data.mid);
        });
        return mids;
    };

    revision_grid.is_valid = function() {
        return revision_store.getCount() > 0;
    };

    revision_store.on('add', function() {
        revision_grid.fireEvent('change', revision_grid);
    });
    revision_store.on('remove', function() {
        revision_grid.fireEvent('change', revision_grid);
    });

    // Load data
    if (!params) params = {};
    if (!params.topic_data) params.topic_data = {};
    data = params.topic_data[meta.id_field] || [];

    Ext.each(data, function(row) {
        var r = new revision_store.recordType(row, row.mid);
        revision_store.add(r);
        revision_store.commitChanges();
    });

    Baseliner.delete_revision_row = function(id_grid, mid) {
        var g = Ext.getCmp(id_grid);
        var s = revision_grid.getStore();
        s.each(function(row) {
            if (row.data.mid == mid) {
                s.remove(row);
            }
        });
    };

    var addCIToStore = function(mid,name) {
        if( revision_store.find('mid', mid ) > -1 ) {
            Baseliner.message( _('Revision'), _('Revision %1 has already been selected', name ) );
            return;
        }
        var d = { name: name, id: mid, mid: mid };
        var r = new revision_store.recordType( d, mid );

        revision_store.add( r );
        revision_store.commitChanges();
    }

    var addCI = function(name, node_data) {
        var ci = node_data.ci;
        var mid = node_data.mid;

        if (node_data.repo_dir != undefined) {
            ci.data.repo_dir = node_data.repo_dir
        };

        if (typeof ci.data.sha === 'undefined') {
            if (typeof ci.sha !== 'undefined') {
                ci.data.sha = ci.sha;
            } else {
                ci.data.sha = node_data.sha;
            }
        }

        if (mid == undefined && (ci == undefined || ci.role != 'Revision')) {
            Baseliner.message(_('Error'), _('Node is not a revision'));
        } else if (mid != undefined) {
            // TODO
        } else if (ci != undefined) {
            Baseliner.ajaxEval('/ci/attach_revisions', {
                name: ci.name,
                'class': ci['class'],
                ns: ci.ns,
                ci_json: Ext.util.JSON.encode(ci.data),
                repo: node_data.click ? node_data.click.repo_mid : node_data.repo_mid,
                topic_mid: topic_data.topic_mid,
                branch: node_data.branch,
                repo_dir: node_data.repo_dir
            }, function(res) {
                if (res.success) {
                    addCIToStore(res.mid, ci.name);
                } else {
                    Ext.Msg.alert(_('Error'), _('Error adding revision %1: %2', ci.name, res.msg));
                }
            });
        }
    };

    revision_grid.on( 'afterrender', function(){
        //if( c.value != undefined ) {
            // TODO no loader from mids yet
        //}
        var read_only = Baseliner.eval_boolean(meta.readonly);

        if (!read_only) {
            var el = revision_grid.el.dom;
            var revision_box_dt = new Baseliner.DropTarget(el, {
                comp: revision_grid,
                ddGroup: 'explorer_dd',
                copy: true,
                available: Baseliner.eval_boolean(meta.readonly),
                notifyDrop: function(dd, e, id) {
                    var n = dd.dragData.node;
                    var attr = n.attributes;
                    var node_data = attr.data || {};
                    var ci = node_data.ci;
                    if( ci ) {
                        addCI( attr.text, node_data );
                    }
                    else {
                        if( node_data.ci_new ) {
                            var ci_new = node_data.ci_new;
                            var coll = ci_new.collection;
                            var form_data = ci_new.form_data;
                            var name = attr.text;

                            Cla.ajax_json( '/ci/edit', { action:'add', collection: coll, name: name, form_data: form_data }, function(comp) {
                                comp.on('save', function( req, res ){
                                    var mid = res.mid;
                                    if( mid ) {
                                        addCIToStore( mid, req.form_data.name);
                                    }
                                    win.close();
                                });
                                var win = new Cla.Window({ modal: true, items:[comp], layout:'fit', width: 850, height: 500 });
                                win.show();
                            });
                        }
                        else if (node_data.repo_mid && node_data.ns) {
                            Baseliner.ajaxEval('/ci/attach_revisions', {
                                name: ci.name,
                                'class': ci['class'],
                                ns: ci.ns,
                                ci_json: Ext.util.JSON.encode(ci.data),
                                repo: node_data.click ? node_data.click.repo_mid : node_data.repo_mid,
                                topic_mid: topic_data.topic_mid,
                                branch: ci.data.branch,
                                repo_dir: node_data.repo_dir
                            }, function(res) {
                                if (res.success) {
                                    if (res.success) {
                                        addCIToStore(res.mid, attr.text);
                                    }
                                } else {
                                    Ext.Msg.alert(_('Error'), _('Error adding revision %1: %2', ci.name, res.msg));
                                }
                            });
                        }
                        else {
                            Baseliner.message(_('Error'), _('Node is not a Revision CI'));
                        }
                    }
                    return (true);
                }
            });
        }
    });

    return [
        revision_grid
    ];
});
