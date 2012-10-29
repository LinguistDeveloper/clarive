<%init>
    my $cal = $c->stash->{calendar};
</%init>
(function(){
    var id = Ext.id();
    var id2 = 'container-' + id;
    var bl_store = new Ext.data.SimpleStore({ 
       fields: ['value', 'name'], 
       data : <% js_dumper( $c->stash->{baselines} ) %>
    }); 

    var calendar_type_help = '<b>Ventanas de pase:</b><br>';    
    calendar_type_help += '<TABLE border="0" width="100%" cellpadding="2">';
    calendar_type_help += '<TR><TD class="normal" width=20 height=20>&nbsp;</TD><TD>Pase: Son ventanas en las que se pueden realizar pases.</TD></TR>';
    calendar_type_help += '<TR><TD class="urgente" width=20 height=20>&nbsp;</TD><TD>Urgente/No pase: Son ventanas urgentes, fuera de lo habitual. Este estado sirve para sobreescribir un pase nornmal.</TD></TR>';
    calendar_type_help += '</TABLE>';
    
    var cal_form = new Ext.FormPanel({
                url: '/job/calendar_update',
                frame: true,
                title: _('Calendar Info'),
                autoHeight: true,
                autoWidth: true,
                defaults: { width: 300 },
                buttons: [                  
                    /*{  text: _('Ayuda'),
                        handler: function(){ 
                            Ext.Msg.show({
                               title:'Ayuda sobre la herencia',
                               msg: calendar_type_help,
                               buttons: Ext.Msg.OK,
                               animEl: 'elId'
                            });
                        } 
                    },*/
                    {  text: _loc('Update'),
                        handler: function(){ 
                            var ff = cal_form.getForm();
                            ff.submit({
                                success: function(form, action) { Baseliner.message(_('Calendar'), action.result.msg); },
                                failure: function(form, action) { Baseliner.message(_('Failure'), action.result.msg); }
                            });
                        } 
                    }                   
                ],
                items: [
                    {  xtype: 'hidden', name: 'id_cal', value: '<% $cal->id %>' },
                    {  xtype: 'textfield',
                        fieldLabel: _loc('Name'),
                        name: 'name',
                        value: '<% $cal->name %>'
                    },
                    {  xtype: 'textfield',
                        fieldLabel: _loc('Priority'),
                        name: 'seq',
                        value: '<% $cal->seq %>'
                    },
                    {  xtype: 'textarea',
                        fieldLabel: _('Description'),
                        name: 'description',
                        value: '<% $cal->description %>'
                    },
                    Baseliner.ci_box({ name:'ns', role:'Project', fieldLabel:_('Namespace'), value: '<% $cal->ns %>', emptyText: _('Global')  }),
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
                               allowBlank: false
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

