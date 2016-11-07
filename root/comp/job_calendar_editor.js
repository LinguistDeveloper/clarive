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

    var id_cal = '<% $c->stash->{id_cal} %>';
    var can_admin = Cla.eval_boolean(<% $c->stash->{can_admin} %>);
    var can_edit = Cla.eval_boolean(<% $c->stash->{can_edit} %>);

    var calendar_type_help = '<b>'+_('Job Slots')+':</b><br>';
    calendar_type_help += '<TABLE border="0" width="100%" cellpadding="2">';
    calendar_type_help += '<TR><TD class="normal" width=20 height=20>&nbsp;</TD><TD>Pase: Son ventanas en las que se pueden realizar pases.</TD></TR>';
    calendar_type_help += '<TR><TD class="urgente" width=20 height=20>&nbsp;</TD><TD>Urgente/No pase: Son ventanas urgentes, fuera de lo habitual. Este estado sirve para sobreescribir un pase nornmal.</TD></TR>';
    calendar_type_help += '</TABLE>';

    var cal_ns = '<% $cal->{ns} %>';

    var cal_form = new Ext.FormPanel({
        url: '/job/calendar_update',
        frame: true,
        headerCssClass: 'job-slots-panel-header',
        bwrapCssClass: 'job-slots-panel-bwrap',
        items: [{
            itemId: 'text',
            layout: 'column',
            anchor: '90%',
            items: [{
                layout: 'form',
                columnWidth: 0.5,
                cls: 'job_slots_form_column_body',
                defaults: {
                    xtype: 'textfield',
                    anchor: '90%'
                },
                items: [{
                    name: 'name',
                    fieldLabel: _('Name'),
                    value: '<% $cal->{name} %>'
                }, {
                    fieldLabel: _('Priority'),
                    name: 'seq',
                    value: '<% $cal->{seq} %>'
                }, {
                    xtype: 'textarea',
                    name: 'description',
                    height: 60,
                    fieldLabel: _('Description'),
                    value: '<% $cal->{description} %>'
                }]
            }, {
                itemId: 'form',
                layout: 'form',
                columnWidth: 0.5,
                cls: 'job_slots_form_column_body',
                defaults: {
                    anchor: '90%'
                },
                items: [
                    Baseliner.ci_box({
                        name: 'bl',
                        "class": 'BaselinerX::CI::bl',
                        fieldLabel: _('Baseline'),
                        value: '<% $cal->{bl}  %>',
                        valueField: 'moniker',
                        force_set_value: true
                    }),
                    Baseliner.ci_box({
                        name: 'ns',
                        role: ['Infrastructure', 'Project'],
                        fieldLabel: _('Scope'),
                        value: cal_ns != '/' ? cal_ns : '/',
                        emptyText: _('Global'),
                        force_set_value: cal_ns && cal_ns != '/' ? true : false
                    }),
                ]
            }]
        }]
    });

    var cal_slots = new Ext.Panel({
        id: id,
        frame: true,
        autoLoad: {
            url: '/job/calendar_slots',
            params: {
                panel: id,
                id_cal: id_cal,
                scripts: true
            }
        },
        split: true
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
        cls: 'job-slots-panel',
        headerCssClass: 'job-slots-panel-header',
        bodyCssClass: 'job-slots-panel-body',
        bwrapCssClass: 'job-slots-panel-bwrap',
        autoHeight: true,
        autoWidth: true,
        defaults: {
            width: 900
        },
        height: 450,
        items: [{
            itemId: 'week',
            cls: 'job-slots-panel-item',
            bodyCssClass: 'job-slots-panel-item-body',
            layout: 'column',
            columnWidth: 0.7,
            minWidth: 70,
            autoWidth: false,
            items: [
                cal_slots,
            ]
        }, {
            layout: 'column',
            columnWidth: 0.3,
            cls: 'job_calendar_edit_cal_windows_column',
            frame: true,
            autoHeight: true,
            autoWidth: true,
            maxWidth: 150,
            items: [{
                    itemId: 'date',
                    xtype: 'datepickerplus',
                    value: _CurrentDate,
                    cls: 'job_calendar_edit_cal_windows',
                    noOfMonth: 1,
                    multiSelection: true,
                    allowMouseWheel: false,
                    showWeekNumber: true,
                    weekendText: '',
                    showActiveDate: false,
                    summarizeHeader: true,
                    height: 300,
                    width: 100,
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

    var btnSave = new Ext.Button({
        icon: '/static/images/icons/save.svg',
        text: _('Save'),
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
    });

    var btnDelete = new Ext.Button({
        icon: '/static/images/icons/delete.svg',
        text: _('Delete'),
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
                    Baseliner.closeCurrentTab();
                },

                failure: function(form, action) {
                    Baseliner.message(_('Failure'), action.result.msg);
                }
            });
        }
    });

    var btnClose = new Ext.Button({
        text: _('Close'),
        cls: 'ui-comp-role-edit-close',
        icon: IC('close'),
        handler: function() {
            panel.destroy()
        }
    });

    var panel = new Ext.Panel({
        id: id2,
        autoScroll: true,
        tbar: [
            '->', btnSave, btnDelete, btnClose
        ],
        items: [cal_form, cal_windows]
    });

    if (!can_edit && !can_admin) {
        btnSave.hide();
        btnDelete.hide();
        cal_form.getComponent('text').disable();
        cal_windows.getComponent('week').disable();
    }

    return panel;
})