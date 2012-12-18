
/*
    Formulario añaido al job_new.js

*/

var store_incidencias = new Baseliner.JsonStore({
    root: 'data',
    baseParams: { cam: [] },
    remoteSort: true,
    totalProperty: 'totalCount',
    id: 'inc_codigo',
    url: '/form/main/load_grid_inc',
    fields: [ 'inc_codigo', 'inc_descripcion', 'inc_clase', 'inc_estado', 'inc_activa', 'inc_cam' ]
});

store_incidencias.on('load', function(s,recs){
    Ext.each( recs, function( rec ){
        if( rec.data.inc_activa == 'NO' ) {
            rec.set('cls_activo', 'cannot-job' );
            var d = rec.get('inc_descripcion');
            if( d.length > 60 ) d = d.substring(0,60) + '...';
            rec.set('inc_desc', d );
        }
    });
    store_incidencias.commitChanges();
    //ss.add( store_incidencias.getRange() );
    //combo_incidencias.onTriggerClick();
});

var tpl_inc = new Ext.XTemplate(
    '<tpl for=".">',
    '<div class="search-item {cls_activo}">',
    '<b>{inc_codigo} - {inc_estado}</b>',
    ' (<span style="font-family: Calibri;">{inc_cam}</span>)',
    ' - {inc_descripcion}',
    '</div>',
    '</tpl>'
);

var tpl_field = new Ext.XTemplate(
    '{inc_codigo}{[ values.inc_desc != undefined ? " - " + values.inc_desc : "" ]}'
);

var ss = new Ext.data.SimpleStore({
    id: 'inc_codigo',
    fields: [ 'inc_codigo', 'inc_descripcion', 'inc_clase', 'inc_estado', 'inc_activa', 'inc_cam' ]
});

var combo_incidencias = new Ext.ux.form.SuperBoxSelect({
    fieldLabel: _('Incidencias'),
    mode: 'local',
    store: store_incidencias ,
    name: 'inc_codigo',
    displayField: 'inc_codigo',
    hiddenName: 'inc_codigo',
    valueField: 'inc_codigo',
    width: 750,
    allowBlank: true,
    hidden: true,
    loadingText: 'Cargando listado de incidencias de USD...',
    //emptyText: 'relleanar con etc...',
    blankText: 'Es necesario indicar el código de incidencia para los pases urgentes. Para introducir un código manualmente, teclee el código y pulse ENTER.' ,
    //queryDelay: 0,
    minChars: 100,
    //itemDelimiterKey: Ext.EventObject.TAB,
    msgTarget: 'under',
    allowAddNewData: true,
    typeAhead: true,
    addNewDataOnBlur: true,
    triggerAction: 'all',
    resizable: true,
    tpl: tpl_inc,
    displayFieldTpl: tpl_field,
    //hidden: true,
    extraItemCls: 'x-tag',
    itemSelector: 'div.search-item',
    listeners: {
        newitem: function(bs,v, f){
            //v = v+'';
            //v = v.slice(0,1).toUpperCase() + v.slice(1).toLowerCase();
            var obj = { inc_codigo: v };
            bs.addItem(obj);
        }
    }
});

combo_incidencias.on('beforeadditem', function(bs,v) {
    var rec = store_incidencias.getById( v );
    if( rec && rec.data.inc_activa != 'SI' ) {
        return false; 
    } else {
        return true;
    }
});
combo_incidencias.on('afterrender', function() {
    combo_incidencias.onTC = combo_incidencias.onTriggerClick;  // save original
    combo_incidencias.onTriggerClick = function(){
        combo_incidencias.onFocus({});
        combo_incidencias.expand();
        store_incidencias.load({ params: { query: combo_incidencias.getRawValue() } });
        //combo_incidencias.onTC();
    }
    /* combo_incidencias.el.on({
        xkeydown : function(e){
           if( e.getKey() == e.DOWN ) {
               combo_incidencias.expand();
               store_incidencias.load({ params: { query: combo_incidencias.getRawValue() } });
           }
        }
    }); */
});


/*
var inc_box = new Ext.form.FieldSet({
    anchor: '100%',
    hidden: true,
    style: { 'margin': '0' , 'padding': '0' },
    border: false,
    labelWidth: 150,
    items: [
    ]
});
*/

var check_ll = new Ext.form.Checkbox({
    name: 'check_linked_list',
    fieldLabel: '',
    boxLabel: "Forzar refresco de LinkList",
    hidden: true,
    disabled: false
});


var alert_ll = false;

combo_search.on('collapse', function(){
    if( alert_ll && combo_baseline.getValue() == 'PROD') {
        alert_ll = false;
        Ext.Msg.alert( 'Aviso', 'Opción de LinkedList añadida' );
    }
});

var ev = function(s,rec){
    var v = combo_time.getRawValue();
    if( v ) {
        var ix = store_time.find( 'time', v );
        if( ix > -1 && store_time.getAt( ix ).get('type') == 'U' ) {
            // es Urgente, poner incidencia
            //    combo_baseline.getValue();
            combo_incidencias.show();
            cams_set();
            combo_incidencias.allowBlank = false;
            combo_incidencias.validate();
        } else {
            combo_incidencias.hide();
            combo_incidencias.allowBlank = true;
        }
    } else{ 
        combo_incidencias.hide();
        combo_incidencias.allowBlank = true;
    }
};

combo_time.on('change', ev );
combo_time.on('select', ev );

var cams_set = function(){
    if( ! combo_incidencias.isVisible() ) return;
    store_incidencias.baseParams.cam = [];
    var cams = {};
    var recs = [];
    jc_store.each( function(rec) {
        recs.push( rec );
        var item = rec.get('item'); 
        if( item && item.length > 0 ) {
            cams[ item.substring(0,3) ] = 1;
        }
    });
    for( var k in cams ) {
        store_incidencias.baseParams.cam.push( k );
    }
};

var ll_set = function(recs){
    var show_ll = false;
    jc_store.each( function(rec) {
        var ns_data = rec.get('data'); 
        if( ! ns_data ) return;
        var linklist = ns_data.linklist;  
        if( typeof linklist == 'object'  ) return;
        if( linklist == 'SI' && combo_baseline.getValue() == 'PROD' ) {
            show_ll = true;
        }
    });
    alert_ll = show_ll;
    if( show_ll ) {
        check_ll.show();
    } else {
        check_ll.hide();
    }
};

jc_store.on('remove', cams_set );
jc_store.on('remove', ll_set );
jc_store.on('add', function(s,recs,ix){
    // busco naturalezas
    ll_set();
    cams_set();
});

main_form.add( check_ll );
main_form.add( combo_incidencias );
// main_form.doLayout();

