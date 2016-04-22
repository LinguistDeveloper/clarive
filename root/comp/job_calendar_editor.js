<%perl>
    my $cal = $c->stash->{calendar};
</%perl>
(function(){
    var id = Ext.id();
    var id2 = 'container-' + id;
    var bl_store = new Ext.data.SimpleStore({ 
       fields: ['value', 'name'], 
       data : <% js_dumper( $c->stash->{baselines} ) %>
    });

    var id_cal = '<% $c->stash->{id_cal} %>' ;
    var admin = '<% $c->stash->{admin} %>' ;
    var can_edit = '<% $c->stash->{can_edit} %>' ;

    var calendar_type_help = '<b>'+_('Job Slots')+':</b><br>';    
    calendar_type_help += '<TABLE border="0" width="100%" cellpadding="2">';
    calendar_type_help += '<TR><TD class="normal" width=20 height=20>&nbsp;</TD><TD>Pase: Son ventanas en las que se pueden realizar pases.</TD></TR>';
    calendar_type_help += '<TR><TD class="urgente" width=20 height=20>&nbsp;</TD><TD>Urgente/No pase: Son ventanas urgentes, fuera de lo habitual. Este estado sirve para sobreescribir un pase nornmal.</TD></TR>';
    calendar_type_help += '</TABLE>';
    
    var cal_ns = '<% $cal->{ns} %>';

    
    var cal_form = new Ext.FormPanel({
        url: '/job/calendar_update',
        frame: true,
        title: _('Calendar Info'),
        autoHeight: true,
        autoWidth: true,
        defaults: {
            width: 300
        },
        items: [{
            itemId: 'text',
            layout: 'column',
            anchor: '90%',
            items: [{

                layout: 'form',
                columnWidth: 0.5,
                defaults: {
                    anchor: '90%'
                },
                items: [{
                    xtype: 'textfield',
                    fieldLabel: _loc('Name'),
                    name: 'name',
                    value: '<% $cal->{name} %>'
                }, {
                    xtype: 'textfield',
                    fieldLabel: _loc('Priority'),
                    name: 'seq',
                    value: '<% $cal->{seq} %>'
                }, {
                    xtype: 'textarea',
                    fieldLabel: _('Description'),
                    name: 'description',
                    value: '<% $cal->{description} %>'
                }]
            }, {
                itemId: 'form',
                layout: 'form',
                columnWidth: 0.5,
                items: [{
                        xtype: 'combo',
                        name: 'bl',
                        hiddenName: 'bl',
                        fieldLabel: _('Baseline'),
                        mode: 'local',
                        editable: false,
                        forceSelection: true,
                        triggerAction: 'all',
                        store: bl_store,
                        valueField: 'value',
                        value: '<% $cal->{bl}  %>',
                        displayField: 'name',
                        allowBlank: false
                    },
                    Baseliner.ci_box({
                        name: 'ns',
                        role: ['Infrastructure', 'Project'],
                        width: 400,
                        fieldLabel: _('Scope'),
                        value: cal_ns != '/' ? cal_ns : '/',
                        emptyText: _('Global'),
                        force_set_value: cal_ns && cal_ns != '/' ? true : false
                    }),
                ],
                buttons: [{
                    icon: '/static/images/icons/save.png',
                    text: _loc('Save'),
                    handler: function() {
                        var ff = cal_form.getForm();
                        ff.submit({
                            params: {
                                id_cal: id_cal
                            },
                            success: function(form, action) {
                                Baseliner.message(_('Calendar'), action.result.msg);
                                if (!id_cal || id_cal == '' || id_cal == -1) {
                                    id_cal = action.result.id_cal;
                                    cal_slots.load({
                                        url: '/job/calendar_slots',
                                        params: {
                                            panel: id,
                                            id_cal: id_cal,
                                            scripts: true
                                        }
                                    });
                                    cal_windows.show();
                                }
                            },
                            failure: function(form, action) {
                                Baseliner.message(_('Failure'), action.result.msg);
                            }
                        });
                    }
                }, {
                    icon: '/static/images/icons/delete_.png',
                    text: _loc('Delete'),
                    handler: function() {
                        var ff = cal_form.getForm();
                        ff.submit({
                            params: {
                                action: 'delete',
                                id_cal: id_cal
                            },
                            success: function(form, action) {
                                Baseliner.message(_('Calendar'), action.result.msg);
                                id_cal = '';
                                cal_windows.hide();
                            },
                            failure: function(form, action) {
                                Baseliner.message(_('Failure'), action.result.msg);
                            }
                        });
                    }
                }]
            }, ]
        }]
    });

    var cal_slots = new Ext.Panel({    
        id: id,
        //region:'center',
        frame: true,
        autoHeight: true,
        autoWidth: true,
        defaults: { height: 20, width: 300 },
        maxWidth: 400,
        //width: 720,             
        autoLoad: { url: '/job/calendar_slots', params: { panel: id, id_cal: id_cal, scripts: true  } },
        split: true,
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

    var cal_windows = new Ext.Panel({
        layout: 'column',
        anchor: '90%',
        frame: true,
        title: _('Calendar Windows'),
        hidden: (id_cal == -1 ? true : false),
        cls:'job_calendar_edit_cal_windows',
        autoHeight: true,
        autoWidth: true,
        defaults: {
            width: 900
        },
        height: 450,
        items: [{
            itemId: 'week',
            layout: 'column',
            columnWidth: 0.7,
            anchor: '90%',
            items: [
                cal_slots,
            ]
        }, {
            layout: 'column',
            columnWidth: 0.3,
            anchor: '90%',
            cls:'job_calendar_edit_cal_windows_column',
            frame: true,
            autoHeight: true,
            autoWidth: true,
            maxWidth: 150,
            defaults: {
                height: 300,
                width: 100
            },
            items: [{
                    itemId: 'date',
                    xtype: 'datepickerplus',
                    value: _CurrentDate,
                    noOfMonth: 1,
                    multiSelection: true,
                    allowMouseWheel: false,
                    showWeekNumber: true,
                    weekendText: '',
                    showActiveDate: false,
                    summarizeHeader: true,
                    listeners: {
                        'beforedateclick': function(picker, t) {
                            this.currentDateRef = t;
                        },
                        'beforerender': function(picker) {
                            _setSelectedWeek(picker, _CurrentDate);
                        },
                        'afterdateclick': function(picker, t) {
                            _setSelectedWeek(picker, t);
                            var fecha = t.getDate() + "/" + (t.getMonth() + 1) + "/" + t.getFullYear();
                            Ext.get(id).load({
                                url: '/job/calendar_slots',
                                params: {
                                    panel: id,
                                    id_cal: id_cal,
                                    date: fecha
                                }
                            });
                        },
                        'afterweekclick': function(picker, t) {
                            _setSelectedWeek(picker, t);
                            var fecha = t.getDate() + "/" + (t.getMonth() + 1) + "/" + t.getFullYear();
                            Ext.get(id).load({
                                url: '/job/calendar_slots',
                                params: {
                                    panel: id,
                                    id_cal: id_cal,
                                    date: fecha
                                }
                            });
                        }

                    }
                }

            ]
        }]

    });

    if (can_edit == 0 && admin == 0) {

          cal_form.getComponent('text').getComponent('form').buttons[0].disable();
          cal_form.getComponent('text').getComponent('form').buttons[1].disable();
          cal_windows.getComponent('week').disable();
     }

    var panel = new Ext.Panel({
        id: id2,
        style: 'padding: 5px',
        autoScroll: true,
        items: [ cal_form, cal_windows ]
    });
    return panel;
})



