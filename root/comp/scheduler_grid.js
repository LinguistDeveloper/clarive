(function() {
    var default_page_size = 30;
    var hm = function() {
        new Date(Date.now()).format('H:i:s')
    }

    var today = function() {
        new Date(Date.now()).format('Y-m-d')
    }

    var store = new Baseliner.JsonStore({
        root: 'data',
        remoteSort: true,
        totalProperty: "totalCount",
        id: 'id',
        url: '/scheduler/json',
        fields: [{
            name: 'id'
        }, {
            name: 'name'
        }, {
            name: 'service'
        }, {
            name: 'id_last_log'
        }, {
            name: 'id_rule'
        }, {
            name: 'what_name'
        }, {
            name: 'next_exec'
        }, {
            name: 'last_exec'
        }, {
            name: 'description'
        }, {
            name: 'frequency'
        }, {
            name: 'workdays'
        }, {
            name: 'status'
        }, {
            name: 'pid'
        }]
    });
    store.on("load", function() {
        show_buttons();
    });
    store.load({
        params: {
            start: 0,
            limit: default_page_size
        }
    });

    var search_field = new Baseliner.SearchField({
        store: store,
        params: {
            start: 0,
            limit: default_page_size
        },
        emptyText: _('<Enter your search string>')
    });

    var button_toggle_activation = new Ext.Toolbar.Button({
        text: _('Activate'),
        hidden: true,
        cls: 'x-btn-text-icon',
        handler: toggle_activation_handler
    });

    var button_new_schedule = new Ext.Toolbar.Button({
        text: _('Create'),
        hidden: false,
        icon: '/static/images/icons/add.gif',
        cls: 'x-btn-text-icon',
        handler: function() {
            var next_exec = new Date(Date.now()).format('Y-m-d H:i:s');
            edit_window({
                next_exec: next_exec
            });
        }
    });

    var button_edit_schedule = new Ext.Toolbar.Button({
        text: _('Edit'),
        hidden: true,
        icon: '/static/images/icons/edit.gif',
        cls: 'x-btn-text-icon',
        handler: function() {
            var sm = grid.getSelectionModel();
            if (sm.hasSelection()) {
                edit_window(sm.getSelected().data);
            } else {
                Baseliner.message(_('Error'), _('Select a row'));
            }
        }
    });

    var delete_schedule_handler = function() {
        var sm = grid.getSelectionModel();
        if (sm.hasSelection()) {
            var r = sm.getSelected();
            Baseliner.ajaxEval('/scheduler/delete_schedule', {
                    id: r.data.id
                },
                function(response) {
                    if (response.success) {
                        Baseliner.message(_('SUCCESS'), _('Scheduled task deleted'));
                        store.load({
                            params: {
                                limit: default_page_size
                            }
                        });
                    } else {
                        Baseliner.message(_('ERROR'), _('Scheduled task not deleted'));
                    }
                }
            );
        }
    };

    var run_schedule_handler = function() {
        var sm = grid.getSelectionModel();
        if (sm.hasSelection()) {
            var r = sm.getSelected();
            Baseliner.ajaxEval('/scheduler/run_schedule', {
                    id: r.data.id
                },
                function(response) {
                    if (response.success) {
                        Baseliner.message(_('SUCCESS'), _('Scheduled to run now'));
                        store.load({
                            params: {
                                limit: default_page_size
                            }
                        });
                    } else {
                        Baseliner.message(_('ERROR'), _('Could not schedule task'));
                    }
                }
            );

        } else {
            alert(_('Select a row'));
        }
    };

    var kill_schedule_handler = function() {
        var sm = grid.getSelectionModel();
        if (sm.hasSelection()) {
            Ext.Msg.confirm(_('Confirm'), _('Are you sure you want to kill the task?'), function(btn, text) {
                if (btn == 'yes') {
                    var r = sm.getSelected();
                    Baseliner.ajaxEval('/scheduler/kill_schedule', {
                            id: r.data.id
                        },
                        function(response) {
                            if (response.success) {
                                Baseliner.message(_('SUCCESS'), _('Task killed'));
                                store.load({
                                    params: {
                                        limit: default_page_size
                                    }
                                });
                            } else {
                                Baseliner.message(_('ERROR'), _('Could not kill task'));
                            }
                        }
                    );
                }
            });
        }
    };

    var button_delete_schedule = new Ext.Toolbar.Button({
        text: _('Delete'),
        hidden: true,
        icon: '/static/images/icons/delete_.png',
        cls: 'x-btn-text-icon',
        handler: delete_schedule_handler
    });

    var button_duplicate_schedule = new Ext.Toolbar.Button({
        text: _('Duplicate'),
        hidden: true,
        icon: '/static/images/icons/copy.gif',
        cls: 'x-btn-text-icon',
        handler: function() {
            var sm = grid.getSelectionModel();
            if (sm.hasSelection()) {
                var rec = sm.getSelected().data;
                delete rec.id;
                edit_window(rec);
            } else {
                Baseliner.message(_('Error'), _('Select a row'));
            }
        }
    });

    var button_run_schedule = new Ext.Toolbar.Button({
        text: _('Run now'),
        hidden: true,
        icon: '/static/images/icons/start.png',
        cls: 'x-btn-text-icon',
        handler: run_schedule_handler
    });

    var button_kill_schedule = new Ext.Toolbar.Button({
        text: _('Kill'),
        hidden: true,
        icon: '/static/images/silk/clock_stop.png',
        cls: 'x-btn-text-icon',
        handler: kill_schedule_handler
    });

    var tbar = new Ext.Toolbar({
        items: [_('Search') + ': ', ' ',
            search_field, ' ', ' ',
            button_new_schedule,
            button_edit_schedule,
            button_delete_schedule,
            button_duplicate_schedule,
            button_toggle_activation,
            button_run_schedule,
            button_kill_schedule
        ]
    });

    var paging = new Ext.PagingToolbar({
        store: store,
        pageSize: default_page_size,
        displayInfo: true,
        displayMsg: _('Rows {0} - {1} of {2}'),
        emptyMsg: _("No records available")
    });

    var name_renderer = function(value, metadata, rec, rowIndex, colIndex, store) {
        var str = value + String.format(' <a target="_blank" href="/scheduler/last_log?id={0}"><img src="/static/images/icons/moredata.gif" /></a>', rec.data.id_last_log);
        return "<div style='font-weight:bold; font-size: 15px;font-family: Calibri, Helvetica Neue, Arial, Arial, sans-serif'>" + str + "</div>";
    };

    var grid = new Ext.grid.GridPanel({
        renderTo: 'main-panel',
        header: false,
        stripeRows: true,
        store: store,
        viewConfig: {
            enableRowBody: true,
            forceFit: true
        },
        selModel: new Ext.grid.RowSelectionModel({
            singleSelect: true
        }),
        loadMask: 'true',
        columns: [{
            header: _('Name'),
            width: 300,
            dataIndex: 'name',
            sortable: true,
            renderer: name_renderer
        }, {
            header: _('Status'),
            width: 60,
            dataIndex: 'status',
            sortable: true
        }, {
            header: _('Next execution'),
            width: 100,
            dataIndex: 'next_exec',
            sortable: true,
            renderer: Cla.render_date
        }, {
            header: _('Last execution'),
            width: 100,
            dataIndex: 'last_exec',
            sortable: true,
            renderer: Cla.render_date
        }, {
            header: _('PID'),
            width: 60,
            dataIndex: 'pid',
            sortable: true
        }, {
            header: _('Description'),
            width: 200,
            dataIndex: 'description',
            sortable: true
        }, {
            header: _('Frequency'),
            width: 60,
            dataIndex: 'frequency',
            sortable: true
        }, {
            header: _('Workdays'),
            width: 60,
            dataIndex: 'workdays',
            sortable: true
        }, {
            header: _('What'),
            width: 100,
            dataIndex: 'what_name',
            sortable: true
        }],
        bbar: paging,
        tbar: tbar
    });

    grid.getView().forceFit = true;

    grid.on("rowclick", function(grid, rowIndex, e) {
        var r = grid.getStore().getAt(rowIndex);
        show_buttons();
    });
    grid.on('rowdblclick', function(grid, rowIndex, columnIndex, e) {
        var sm = grid.getSelectionModel();
        if (sm.hasSelection()) {
            edit_window(sm.getSelected().data);
        }
    });

    var show_buttons = function() {
        var sm = grid.getSelectionModel();
        var r = sm.getSelected();
        if (r == undefined) return;

        if (r.data.status == 'IDLE' || r.data.status == 'KILLED') {
            button_run_schedule.show();
            button_toggle_activation.setText(_('Deactivate'));
            button_toggle_activation.setIcon('/static/images/icons/stop.png');
            button_delete_schedule.show();
            button_toggle_activation.show();
            button_kill_schedule.hide();
        } else if (r.data.status == 'INACTIVE') {
            button_toggle_activation.setText(_('Activate'));
            button_toggle_activation.setIcon('/static/images/icons/start.png');
            button_toggle_activation.show();
            button_delete_schedule.show();
            button_run_schedule.show();
            button_kill_schedule.hide();
        } else if (r.data.status == 'RUNNING') {
            button_toggle_activation.hide();
            button_delete_schedule.hide();
            button_run_schedule.hide();
            button_kill_schedule.show();
        }
        button_edit_schedule.show();
        button_duplicate_schedule.show();
        tbar.doLayout();
    };

    var edit_window = function(rec) {
        var schedule_id = new Ext.form.Hidden({
            name: 'id',
            value: rec.id
        });

        var schedule_name = new Ext.form.TextField({
            name: 'name',
            fieldLabel: _('Name'),
            width: 150,
            value: rec.name,
            labelWidth: 250
        });

        var schedule_description = new Ext.form.TextArea({
            name: 'description',
            fieldLabel: _('Description'),
            width: 150,
            height: 60,
            value: rec.description,
            labelWidth: 250
        });

        var schedule_date = new Ext.ux.form.DateFieldPlus({
            name: 'date',
            disabled: false,
            readOnly: false,
            fieldLabel: _('Date'),
            allowBlank: false,
            format: 'Y-m-d',
            value: today(),
            minValue: today(),
            noOfMonth: 2,
            noOfMonthPerRow: 2,
            renderTodayButton: false,
            showToday: true,
            multiSelection: false,
            allowMouseWheel: false,
            showWeekNumber: false,
            selectedDates: [],
            showActiveDate: true,
            summarizeHeader: true,
            width: 150,
            labelWidth: 250
        });

        var schedule_time = new Ext.ux.form.Spinner({
            name: 'time',
            format: "H:i",
            fieldLabel: _('Time'),
            allowBlank: false,
            disabled: false,
            value: hm(),
            editable: true,
            width: 150,
            labelWidth: 250,
            strategy: new Ext.ux.form.Spinner.TimeStrategy(),
            validator: time_validator
        });

        var schedule_frequency = new Ext.form.TextField({
            name: 'frequency',
            width: 150,
            labelWidth: 250,
            value: rec.frequency,
            fieldLabel: _('Frequency')
        });

        var chk_schedule_workdays = new Ext.form.Checkbox({
            name: 'workdays',
            checked: rec.workdays == 1,
            fieldLabel: _('Workdays only')
        });

        var store_pipeline = new Baseliner.JsonStore({
            url: '/rule/list',
            root: 'data',
            totalProperty: 'totalCount',
            id: 'id',
            fields: ['id', 'rule_name', 'rule_type', 'rule_desc']
        });
        var result_template = new Ext.XTemplate(
            '<tpl for="."><div class="x-combo-list-item">',
            '<span id="boot" style="background: transparent;">',
            '<strong>{rule_name}</strong>',
            '<tpl if="rule_desc">',
            '<br /><span style="color: #ccc">{rule_desc}<span>',
            '</tpl>',
            '</span>',
            '</div></tpl>'
        );
        var schedule_service = new Baseliner.SuperBox({
            singleMode: true,
            fieldLabel: _('Rule'),
            name: 'id_rule',
            displayField: 'rule_name',
            hiddenName: 'id_rule',
            valueField: 'id',
            store: store_pipeline,
            mode: 'remote',
            minChars: 0,
            loadingText: _('Searching...'),
            tpl: result_template,
            allowBlank: false,
            value: rec.id_rule,
            editable: false,
            lazyRender: true
        });
        store_pipeline.load();

        var btn_submit = new Ext.Button({
            text: _('Save'),
            icon: '/static/images/icons/save.png',
            handler: function() {
                var ff = schedule_form.getForm();
                ff.submit({
                    success: function(form, action) {
                        store.load({
                            params: {
                                limit: default_page_size
                            }
                        });
                        ff.reset();
                        win.close();
                    },
                    failure: function(form, action) {
                        if (action.result) {
                            Baseliner.error(_('Scheduler'), action.result.msg);
                        }
                    }
                });
            }
        });

        var schedule_form = new Baseliner.FormPanel({
            frame: true,
            url: '/scheduler/save_schedule',
            buttons: [
                btn_submit, {
                    text: _('Close'),
                    icon: '/static/images/icons/close.png',
                    handler: function() {
                        win.close();
                    }
                }
            ],
            defaults: {
                anchor: '100%',
                msgTarget: 'under'
            },
            items: [schedule_id, schedule_name, {
                    layout: 'column',
                    defaults: {
                        layout: 'form',
                        border: false,
                        xtype: 'panel',
                        bodyStyle: 'padding:0 2px 0 0'
                    },
                    items: [{
                        columnWidth: 0.86,
                        defaults: {
                            anchor: '100%'
                        },
                        items: [schedule_service]
                    }]
                },
                schedule_date, schedule_time, schedule_frequency, schedule_description, chk_schedule_workdays
            ]
        });

        if (rec.next_exec) {
            schedule_date.setValue(rec.next_exec.substring(0, 10));
            schedule_time.setValue(rec.next_exec.substring(11, 16));
        } else {
            schedule_date.setValue(undefined);
            schedule_time.setValue(undefined);
        }

        var win = new Baseliner.Window({
            autoScroll: true,
            title: _("Schedule information"),
            width: 650,
            items: [schedule_form]
        });

        win.show();
    };

    var toggle_activation_handler = function() {
        var sm = grid.getSelectionModel();
        if (sm.hasSelection()) {
            var r = sm.getSelected();
            Baseliner.ajaxEval('/scheduler/toggle_activation', {
                    id: r.data.id,
                    status: r.data.status
                },
                function(response) {
                    if (response.success) {
                        Baseliner.message(_('SUCCESS'), _(response.msg));
                        store.load({
                            params: {
                                limit: default_page_size
                            }
                        });
                    } else {
                        Baseliner.message(_('ERROR'), _(response.msg));
                    }
                }
            );
        }
    };

    var time_validator = function(time) {
        var regexp = /^(2[0-3])|[01][0-9]:[0-5][0-9]$/;

        var rv = regexp.test(time);

        if (rv) {
            return rv;
        }
        else {
            return 'Time is invalid'
        }
    };

    return grid;
})();
