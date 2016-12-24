/*
name: Release
params:
    html: '/fields/system/html/field_release.html'
    js: '/fields/system/js/list_release.js'
    relation: 'system'
    type: 'listbox'
    get_method: 'get_release'
    set_method: 'set_release'
    field_order: 7
    section: 'body'
    filter: 'none'
    release_field: ''
    allowBlank: true
    single_mode: true
    rel_type: 'topic_topic'
    meta_type: 'release'
---
*/
(function(params) {
    var data = params.topic_data;
    var meta = params.topic_meta;
    var form = params.form.getForm();

    var topic_mid = data.topic_mid || undefined;
    var ps = meta.page_size || 10; // for combos, 10 is a much nicer on a combo
    var display_field = meta.display_field || undefined;
    var tpl_cfg = meta.tpl_cfg || undefined;

    var rows = data[meta.id_field];
    var row_mids;
    if (rows) {
        row_mids = Ext.isArray(rows) ? rows.map(function(row) {
            return row.mid
        }) : rows.mid;
    }

    var release_box_store = new Baseliner.store.Topics({
        baseParams: {
            not_in_status: meta.not_in_status,
            categories: meta.categories,
            statuses: meta.statuses,
            limit: ps,
            logic: meta.logic,
            mid: topic_mid,
            show_release: 1,
            filter: meta.filter ? meta.filter : ''
        },
        display_field: display_field,
        tpl_cfg: tpl_cfg
    });

    var release_box = new Baseliner.TopicBox({
        fieldLabel: _(meta.name_field),
        pageSize: ps,
        name: meta.id_field,
        hiddenName: meta.id_field,
        emptyText: _(meta.emptyText),
        allowBlank: Baseliner.eval_boolean(meta.allowBlank),
        store: release_box_store,
        disabled: Baseliner.eval_boolean(meta.readonly),
        singleMode: true,
        hidden: Baseliner.eval_boolean(!meta.active),
        display_field: display_field,
        tpl_cfg: tpl_cfg,
        hidden_value: row_mids,
        listeners: {
            additem: function(combo) {
                this.fireEvent('filter', combo, this.getValue().split(","));
            },
            removeitem: function(combo) {
                this.fireEvent('filter', combo, this.getValue().split(","));
            },
            render: function(combo) {
                this.fireEvent('filter', combo, this.getValue().split(","));
            }
        }
    });
    release_box.value = data ? (eval('data.' + meta.id_field + ' && data.' + meta.id_field + ' != undefined && data.' + meta.id_field + '.mid') ? eval('data.' + meta.id_field + '.mid') : '') : '';
    params.form.on('afterrender', function() {
        if(!meta.filter_field)
            return;
        var filterField = params.fieldletMap[meta.filter_field[0]] ? params.fieldletMap[meta.filter_field[0]][0] : '';
        if (filterField) {
            filterField.addListener('filter', function(parent, values) {
                release_box_store.baseParams['filter'] = Cla.generateFieldletFilter(meta, values);
                release_box_store.load();
            });
        }
    });
    return [
        release_box
    ]
})