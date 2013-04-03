<%init>
    use Baseliner::Utils;
    my $cal = $c->stash->{calendar};
    my @cam_natures;
    @cam_natures = split(/(?<=]),/,$cal->ns);
    my $readOnly = $c->stash->{user_action}->{'action.job.calendar.edit'}?'false':'true';
    #separamos los namespaces en dos arrays para diferenciar en dos combos
    my @namespaces =  $c->stash->{namespaces};
    my (@array_app, @array_nat);
    for(my $i=0; $i < scalar @{$namespaces[0]}; $i++){
        push @array_app, \@{$namespaces[0][$i]} if $namespaces[0][$i][1] =~ m/Global/;
        push @array_app, \@{$namespaces[0][$i]} if $namespaces[0][$i][0] =~ m/application/;
        push @array_nat, \@{$namespaces[0][$i]} if $namespaces[0][$i][0] =~ m/nature/;
    }
</%init>
(function(){
    var id = Ext.id();
    var id2 = 'container-' + id;
    var app_store = new Ext.data.SimpleStore({
       fields: ['value', 'name'],
       data : <% js_dumper( \@array_app ) %>
    });
    var nat_store = new Ext.data.SimpleStore({
       fields: ['value', 'name'],
       data : <% js_dumper( \@array_nat ) %>
    });

    var bl_store = new Ext.data.SimpleStore({
       fields: ['value', 'name'],
       data : <% js_dumper( $c->stash->{baselines} ) %>
    });

    var cn_field_name = 'cam_natures';
    var cn_value = <% js_dumper( \@cam_natures) %>;

    var cn_store = new Ext.data.SimpleStore({ fields:[ cn_field_name ] });
    if( cn_value != undefined ) {
        var push_item = function(f, v ) {
            var rr = new Ext.data.Record.create([{
                name: f,
                type: 'string'
            }]);
            var h = {}; h[ cn_field_name ] = v;
            // put it in the grid store
            cn_store.insert( x, new rr( h ) );
        };
        try {
            // if it's an Array or Hash
            if( typeof( cn_value ) == 'object' ) {
                for( var x=0; x < cn_value.length ; x++ ) {
                    push_item( cn_field_name, cn_value[ x ] ); 
                }
            } else if( cn_value.length > 0 ) {  // just one element
                push_item( cn_field_name, cn_value ); 
            }
        } catch(e) {}
    }

    var cn_data = new Ext.form.Hidden({ 
            name: cn_field_name, 
            allowBlank: false 
    });
    var cn_grid = new Ext.grid.EditorGridPanel({
            name: cn_field_name + '_grid',
            width: 400,
            height: 200,
            title: _('Namespace'),
            frame: true,
            viewConfig: {
                scrollOffset: 2,
                forceFit: true
            },
            store: cn_store,
            cm: new Ext.grid.ColumnModel([{
                dataIndex: cn_field_name,
                width: 390,
                editor: new Ext.form.TextField({
                    allowBlank: false, 
                    renderer: function(v) {  return "a" }
                })
            }]),
            sm: (function () {
                var rsm = new Ext.grid.RowSelectionModel({
                    singleSelect: true
                });
                rsm.addListener('rowselect', function () {
                    var __record = rsm.getSelected();
                    return __record;
                });
                return rsm;
                })(),
            tbar: [
                {
                text: _('Delete'),
                icon: '/static/images/del.gif',
                cls: 'x-btn-text-icon',
                disabled: <% $readOnly %>,
                handler: function (e) {
                    var __selectedRecord = cn_grid.getSelectionModel().getSelected();
                    if (__selectedRecord != null) {
                        cn_store.remove(__selectedRecord);
                    }
                }
                }, 
                '->', 'CAM - Naturalezas' 
            ]
    });

    var combo_nat = new Ext.ux.form.SuperBoxSelect({
        allowBlank: true,
        id: 'natures' + id,
        msgTarget: 'under',
        allowAddNewData: true,
        addNewDataOnBlur: true,
        triggerAction: 'all',
        resizable: true,
        store: nat_store,
        mode: 'local',
        fieldLabel: _('Natures'),
        typeAhead: true,
        name: 'natures',
        displayField: 'name',
        hiddenName: 'natures',
        valueField: 'value',
        extraItemCls: 'x-tag',
        disabled: <% $readOnly %>,
        listeners: {
            newitem: function(bs,v, f){
                //v = v.slice(0,1).toUpperCase() + v.slice(1).toLowerCase();
                var newObj = {
                    value: v
                    };
                bs.addItem(newObj);
                }
            }
    });
    
    var cal_form = new Ext.FormPanel({
                url: '/job/calendar_update',
                frame: true,
                layout: 'column',
                title: _('Calendar Info'),
                autoHeight: true,
                autoWidth: true,
                defaults: { 
                    xtype: 'container',
                    layout: 'form',
                    width: 500
                },
                buttons: [                  
% if( $c->stash->{user_action}->{'action.job.calendar.edit'} ) {
                    {  text: _loc('Update'),
                        handler: function(){ 
                            var arr = new Array();
                            cn_store.each( function(r) {
                                arr.push( r.data[ cn_field_name ] );
                            });
                            try {
                                var o = Ext.util.JSON.decode(arr.toString());
                                cn_data.setValue( arr );
                            }catch(JSONerror){
                                cn_data.setValue( Ext.util.JSON.encode(arr));
                            }
                            var ff = cal_form.getForm();
                            ff.submit({
                                success: function(form, action) { Baseliner.message("<% _loc('Calendar') %>", action.result.msg); },
                                failure: function(form, action) { Baseliner.message("<% _loc('Failure') %>", action.result.msg); }
                            });
                        } 
                    }                   
% } 
                ],
                items: [
                    {
                    defaults : { width: 300},
                    items:[
                        {  xtype: 'hidden', name: 'id_cal', value: '<% $cal->id %>' },
                        {  xtype: 'textfield',
                            fieldLabel: _loc('Name'),
                            name: 'name',
                            value: '<% $cal->name %>',
                            disabled: <% $readOnly %>
                        },
                            {  xtype: 'numberfield',
                                fieldLabel: _loc('Priority'),
                                name: 'seq',
                                value: '<% $cal->seq %>',
                                allowNegative: false,
                                allowDecimals: false,
                                minValue:1,
                                maxValue:999,
                                disabled: <% $readOnly %>
                            },
                            {  xtype: 'checkbox',
                                fieldLabel: _loc('Active'),
                                name: 'active',
                                disabled: <% $readOnly %>,
                                checked: <% $cal->active > 0 ? "true" : "false" %>
                            },
                            {  xtype: 'textarea',
                                fieldLabel: _('Description'),
                                name: 'description',
                                value: '<% $cal->description %>',
                                disabled: <% $readOnly %>
                            }
                       ]
                    },
                    {
                    defaults : { width: 300},
                    items:[
                        {  xtype: 'combo', 
                            name: 'bl', 
                            hiddenName: 'bl',
                            fieldLabel: _('Baseline'),
                            mode: 'local', 
                            editable: false,
                            forceSelection: true,
                            triggerAction: 'all',
                            store: bl_store, 
                            valueField: 'value',
                            value: '<% $cal->bl  %>',
                            displayField:'name', 
                            allowBlank: false,
                            disabled: <% $readOnly %>
                        },
                        {
                            xtype:'fieldset',
                            title: _loc('Namespace'),
                            width: 410,
                            disabled: <% $readOnly %>,
                            items :[
                                {  xtype: 'combo',
                                    name: 'ns',
                                    id: 'ns' + id,
                                    hiddenName: 'ns',
                                    fieldLabel: 'CAM',
                                    mode: 'local',
                                    editable: false,
                                    forceSelection: true,
                                    triggerAction: 'all',
                                    store: app_store,
                                    valueField: 'value',
                                    value: '/',
                                    displayField:'name',
                                    allowBlank: true,
                                    disabled: <% $readOnly %>
                                },                        
                                combo_nat,
                                { xtype:'button',
                                    text: 'Nuevo ' + _('Namespace'),
                                    width: 388,
                                    disabled: <% $readOnly %>,
                                    handler: function() {
                                        try {
                                            var ___record = Ext.data.Record.create([{
                                                name: cn_field_name,
                                                type: 'string'
                                            }]);
                                            var h = {};
                                            var arr = new Array();
                                            if( Ext.getCmp('ns' + id).getValue() != '' || Ext.getCmp('natures' + id).getValue() != ''){
                                                arr.push( Ext.getCmp('ns' + id).getValue() );
                                                arr.push( Ext.getCmp('natures' + id).getValue() );
                                                h[ cn_field_name ] = Ext.util.JSON.encode( arr );
                                                var p = new ___record( h );
                                                cn_store.add(p);
                                                cn_store.reload();
                                            }
                                        }catch(mierror){
                                            //alert("Error detectado: " + mierror.description)
                                        }
                                    }  
                                }
                            ]
                        }
                        ]
                    },
                    {
                        defaults : { width: 400},
                        items:[
                            cn_data,
                            cn_grid    
                        ]
                    }
                ]
    });

    var _CurrentDate = new Date(<% $c->stash->{fecha_anyo} %>,<% $c->stash->{fecha_mes} - 1 %>, <% $c->stash->{fecha_dia} %>);
    
    function _selectWeek(picker,t){
        var dd = new Date(t.dateValue);
        var startweekdate = new Date( t.dateValue).getFirstDateOfWeek();
        var daycell = t.dayCell - dd.getDay() + 1;                          
        var amount = 7;
        var reverseAdd = false;
        var monthcell = t.monthCell;
        
        for (var i=0,ni;i<amount;++i) {
            curmonth = startweekdate.getMonth();
            ni = (reverseAdd ? amount-1-i : i);
            if (amount == 7 || curmonth === startmonth) {
                picker.markDateAsSelected(startweekdate.clearTime().getTime(),true,monthcell,daycell+ni,false);
            }
            startweekdate = startweekdate.add(Date.DAY,1);
        }   
    }
    
    function _setSelectedWeek(picker, date){
        var _dates = [];
        var startweekdate = date.getFirstDateOfWeek();
        var amount = 7;     
        for (var i=0,ni;i<amount;++i) {
            _dates.push(startweekdate);
            startweekdate = startweekdate.add(Date.DAY,1);
        }   
        picker.clearSelectedDates();
        picker.setSelectedDates(_dates);        
    }
    
    var panel = new Ext.Panel({
        layout: 'fit',
        id: id2,
        style: 'padding: 5px',
        autoScroll: true,
        items: [
            cal_form,
            {  
                layout: 'border',
                title: _('Calendar Windows'),
                style: 'margin-top: 20px',
                height: 450,
                frame: true,
/*              items: [{  xtype: 'panel', id: id, layout: 'fit',
                    autoLoad: { url: '/job/calendar_slots', params: { panel: id, id_cal: '<% $c->stash->{id_cal} %>' }, scripts: true  }
                }]
*/              
        items: [    
            {       
                xtype: 'panel',
                id: id,
                region:'west',
                width: 720,             
                autoLoad: { url: '/job/calendar_slots', params: { panel: id, id_cal: '<% $c->stash->{id_cal} %>' }, scripts: true  },
                split: true,
                frame: true
            },
            {           
                region:'center',
                frame: true,
                items: [
                {
                    xtype: 'datepickerplus',
                    value: _CurrentDate,    
                    noOfMonth : 4, //(Ext.lib.Dom.getViewHeight()>600?9:4), //9 ,
                    noOfMonthPerRow : 2, //(Ext.lib.Dom.getViewWidth()>1024?3:2), //4,
                    multiSelection: true,
                    allowMouseWheel: false,
                    showWeekNumber: true,
                    weekendText: '',
                    // disabledDates: [new Date(2008,4,5).format(dform).replace(/\./g,"\\."),new Date(2008,4,6).format(dform).replace(/\./g,"\\."),new Date(2008,4,7).format(dform).replace(/\./g,"\\.")],
                    showActiveDate: false,
                    summarizeHeader: true,
                    // prevNextDaysView:"nomark",
                    // prevNextDaysView:false,
                    // listeners:{'beforeweekclick':function(){ return false; }} ,
                    // listeners:{'beforemousewheel':function(){ return false; }} ,
                    listeners:{
                        'beforedateclick':function(picker,t){   
                            this.currentDateRef = t;                            
                        },                      
                        'beforerender':function(picker){
                            _setSelectedWeek(picker, _CurrentDate);     
                        },
                        'afterdateclick':function(picker,t){
                            //_selectWeek(this, this.currentDateRef);
                            _setSelectedWeek(picker, t);
                            var fecha = t.getDate() + "/" + (t.getMonth() + 1) + "/" + t.getFullYear();
                            Ext.get(id).load({url: '/job/calendar_slots', params: { panel: id, id_cal: '<% $c->stash->{id_cal} %>', date: fecha}});
                        },
                        'afterweekclick':function(picker,t){
                            _setSelectedWeek(picker, t);    
                            var fecha = t.getDate() + "/" + (t.getMonth() + 1) + "/" + t.getFullYear();
                            Ext.get(id).load({url: '/job/calendar_slots', params: { panel: id, id_cal: '<% $c->stash->{id_cal} %>', date: fecha}});
                        }                       
                        
                    } 
                }
                ]
            }
        ]
                
            }
        ],
        destroy: function()
        {
            //Esta linea es muy importante, debido a un bug en Ext el autoDestroy no funciona correctamente en el TabPanel
            //La manera de solventar esto es asignar id al panel y obtener la coleccion completa con Ext.get
            //Sobrescribimos la funcion destroy para gestionar la eliminacion correcta del panel y todos sus items
            Ext.get( id2 ).remove();
        }       
    });
    return panel;
})         
