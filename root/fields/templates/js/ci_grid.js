/*
name: CI Grid
params:
    origin: 'template'
    relation: 'system'
    js: '/fields/templates/js/ci_grid.js'
    html: '/fields/templates/html/ci_grid.html'
    get_method: 'get_cis'
    set_method: 'set_cis'
    section: 'head'
    field_order: 100
    field_order_html: 100
    rel_type: topic_ci
    ci_role: 'ci'
    ci_class: ''
    meta_type: 'ci'
---
*/
(function(params) {
    var meta = params.topic_meta;
    var data = params.topic_data;
    var form = params.form.getForm();

    var ci_meta = {};
    if (meta.ci_role) ci_meta['role'] = meta.ci_role;
    if (meta.ci_class) ci_meta['class'] = meta.ci_class;

    var list = data[meta.id_field];
    if (list) {
        var value = list.split(",");
    }

    if (typeof(value) === "undefined") value = meta.default_value;

    var sm = new Baseliner.CheckboxSelectionModel({
        checkOnly: true,
        singleSelect: false
    });
    var cis = new Baseliner.CIGrid({
        fieldLabel: _(meta.name_field),
        sm: sm,
        ci: ci_meta,
        title: null,
        columns: meta.columns || [],
        //labelAlign: 'top',
        readOnly: Baseliner.eval_boolean(meta.readOnly, false),
        disabled: Baseliner.eval_boolean(meta.readonly),
        //style: 'margin-top: 20px',
        height: (meta.height ? parseInt(meta.height) : 200),
        value: value,
        filter: meta.filter ? meta.filter : '',
        name: meta.id_field,
            listeners: {
                change: function(grid) {
                    var records = grid.getStore().getRange();
                    var mids = [];
                    for (var i = 0; i < records.length; i++) {
                        mids.push(records[i].data.mid);
                    }
                    this.fireEvent('filter', grid, mids);
                },
                render: function(grid) {
                    var records = grid.getStore().getRange();
                    var mids = [];
                    for (var i = 0; i < records.length; i++) {
                        mids.push(records[i].data.mid);
                    }
                    this.fireEvent('filter', grid, mids);
                }
            }
    });
    cis.ci_store.baseParams['logic'] = meta.logic;
    params.form.on('afterrender', function() {
        if(!meta.filter_field)
            return;
        var filterField = params.fieldletMap[meta.filter_field[0]] ? params.fieldletMap[meta.filter_field[0]][0] : '';
        if (filterField) {
            filterField.addListener('filter', function(parent, values) {
                cis.ci_box.store.baseParams['filter'] = Cla.generateFieldletFilter(meta, values);
                cis.ci_box.store.load();
            });
        }
    });
    return [
        cis
    ]
})