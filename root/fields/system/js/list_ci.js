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
(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;

    var single_mode = !Baseliner.eval_boolean(meta.single_mode) || (!meta.single_mode && meta.list_type && meta.list_type != 'single') ? false : true;

    var tpl;
    if (meta.display_mode == 'bl'){
        tpl = new Ext.XTemplate(
            '<tpl for=".">'
            +  '<div class="search-item ui-ci_box-ci-list"><span id="boot" style="background: transparent">'
            +  '<div class="x-combo-name-list"><img src="{icon}" /></div><strong>{name} </strong>'
            +  ' <span class="x-combo-name-list-description">{[ Cla.ci_loc(values.bl) ]}</span>'
            + '</div>'
            +'</tpl>'
        );
    } else if (meta.display_mode == 'moniker'){
        tpl = new Ext.XTemplate(
            '<tpl for=".">'
            +  '<div class="search-item ui-ci_box-ci-list"><span id="boot" style="background: transparent">'
            +  '<div class="x-combo-name-list"><img src="{icon}" /></div><strong>{name} </strong>'
            +  ' <span class="x-combo-name-list-description">{[ Cla.ci_loc(values.moniker) ]}</span>'
            + '</div>'
            +'</tpl>'
        );
    } else if (meta.display_mode == 'class'){
        tpl = new Ext.XTemplate(
            '<tpl for=".">'
            +  '<div class="search-item ui-ci_box-ci-list"><span id="boot" style="background: transparent">'
            +  '<div class="x-combo-name-list"><img src="{icon}" /></div><strong>{name} </strong>'
            +  ' <span class="x-combo-name-list-description">{[ Cla.ci_loc(values.collection) ]}</span>'
            + '</div>'
            +'</tpl>'
        );
        meta.show_class = true;
    }

    var ci = {};
    if( meta.ci_role ) ci['role'] = meta.ci_role;
    else if( meta.ci_class ) ci['class'] = meta.ci_class;
  return [
       Baseliner.ci_box(Ext.apply({
           fieldLabel: _(meta.name_field),
           name: meta.id_field,
           mode: 'remote',
           singleMode: single_mode,
           force_set_value: true,
           value: data[meta.id_field]!=undefined ? data[meta.id_field] : (meta.default_value!=undefined? meta.default_value: data[meta.id_field]),
           allowBlank: Baseliner.eval_boolean(meta.allowBlank),
           disabled: Baseliner.eval_boolean(meta.readonly),
           filter: meta.filter ? meta.filter : '',
           showClass: Baseliner.eval_boolean(meta.show_class),
           order_by: meta.order_by ? meta.order_by : undefined,
           tpl: tpl,
       }, ci) )
    ]
})