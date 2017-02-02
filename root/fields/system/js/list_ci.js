/*
name: CIs
params:
    js: '/fields/system/js/list_ci.js'
    html: '/fields/templates/html/ci_grid.html'
    relation: 'system'
    type: 'listbox'
    get_method: 'get_cis'
    set_method: 'set_cis'
    field_order: 100
    field_order_html: 1000
    section: 'head'
    single_mode: false
    ci_role: 'Server'
    ci_class: ''
    rel_type: topic_ci
    show_class: false
    meta_type: 'ci'
---
*/
(function(params) {
    var meta = params.topic_meta;
    var data = params.topic_data;
    var form = params.form.getForm();

    var tpl, field, single_mode;

    if (meta.single_mode) {
        single_mode = Baseliner.eval_boolean(meta.single_mode);
    } else if (meta.list_type) {
        single_mode = meta.list_type != 'single' ? false : true;
    } else {
        single_mode = false;
    }

    if (meta.display_mode == 'bl'){
        field = 'values.bl';
    } else if (meta.display_mode == 'moniker'){
        field = 'values.moniker';
    } else if (meta.display_mode == 'class'){
        field = 'values.collection';
        meta.show_class = true;
    }

    tpl = new Ext.XTemplate(
        '<tpl for=".">'
       +  '<div class="search-item ui-ci_box-ci-list"><span id="boot" style="background: transparent">'
       +  '<div style="float:left; margin-right: 5px; margin-top: -2px"><img src="{icon}" /></div><strong>{name}</strong>'
       +  ' <span style="color:#808080; font-size: .9em">{[ Cla.ci_loc('+ field +') ]}</span>'
       +  '</span></div>'
       +'</tpl>'
    );

    var ci = {};
    if (meta.ci_role) ci['role'] = meta.ci_role;
    else if (meta.ci_class) ci['class'] = meta.ci_class;
    var ciBox = Baseliner.ci_box(Ext.apply({
        fieldLabel: _(meta.name_field),
        name: meta.id_field,
        baseParams: {
            logic: meta.logic
        },
        mode: 'remote',
        singleMode: single_mode,
        force_set_value: true,
        value: data[meta.id_field] != undefined ? data[meta.id_field] : (meta.default_value != undefined ? meta.default_value : data[meta.id_field]),
        allowBlank: Baseliner.eval_boolean(meta.allowBlank),
        disabled: Baseliner.eval_boolean(meta.readonly),
        filter: meta.filter ? meta.filter : '',
        showClass: Baseliner.eval_boolean(meta.show_class),
        order_by: meta.order_by ? meta.order_by : undefined,
        tpl: tpl,
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
    }, ci));

    params.form.on('afterrender', function() {
        if (!meta.filter_field)
            return;
        var filterField = meta.filter_field ? (meta.filter_field.length ? params.fieldletMap[meta.filter_field[0]][0] : form.findField(meta.filter_field)) : '';
        if (filterField) {
            filterField.addListener('filter', function(parent, values) {
                ciBox.store.jsonData['filter'] = Cla.generateFieldletFilter(meta, values);
                if (meta.filter_data == 'collection' && values.split(',').length == 1) {
                    ciBox.store.jsonData.class = "BaselinerX::CI::" + values;
                }
                ciBox.store.load();
            });
        }
    });

  return [
    ciBox
  ]
})