(function(params) {
    var data = params.data || {};

    var select_by_duration_range = new Baseliner.ComboDouble({
        fieldLabel: _('Range'),
        name: 'select_by_duration_range',
        value: data.select_by_duration_range || 'day',
        data: [
            ['day', _('Day')],
            ['week', _('Week')],
            ['month', _('Month')],
            ['year', _('Year')]
        ],

        hidden: !data.selection_method || data.selection_method === 'duration' ? false : true
    });

    var select_by_duration_offset = new Ext.ux.form.SpinnerField({
        fieldLabel: _('Offset'),
        name: 'select_by_duration_offset',
        value: data.select_by_duration_offset || 0,
        minValue: 0,
        maxValue: 365,

        width: 165,

        hidden: !data.selection_method || data.selection_method === 'duration' ? false : true
    });

    var select_by_period_from = new Ext.form.DateField({
        fieldLabel: _("From"),
        value: data.select_by_period_from,
        name: "select_by_period_from",

        anchor: '100%',
        format: 'Y-m-d',
        height: 100,

        hidden: data.selection_method === 'period' ? false : true
    });

    var select_by_period_to = new Ext.form.DateField({
        fieldLabel: _("To"),
        value: data.select_by_period_to,
        name: "select_by_period_to",

        anchor: '100%',
        format: 'Y-m-d',
        height: 100,

        hidden: data.selection_method === 'period' ? false : true
    });

    var select_by_topic_filter_from = new Ext.form.TextField({
        fieldLabel: _('From field'),
        name: 'select_by_topic_filter_from',
        value: data.select_by_topic_filter_from,

        width: 165,

        hidden: data.selection_method === 'topic_filter' ? false : true
    });

    var select_by_topic_filter_to = new Ext.form.TextField({
        fieldLabel: _('To field'),
        name: 'select_by_topic_filter_to',
        value: data.select_by_topic_filter_to,

        width: 165,

        hidden: data.selection_method === 'topic_filter' ? false : true
    });

    var scale_selector = new Baseliner.ComboDouble({
        fieldLabel: _('Scale'),
        name: 'scale',
        value: data.scale || 'day',
        data: [
            ['hour', _('Hour')],
            ['day', _('Day')],
            ['month', _('Month')],
            ['year', _('Year')]
        ]
    });

    var selector = new Baseliner.ComboDouble({
        fieldLabel: _('Date selection method'),
        name: 'selection_method',
        value: data.selection_method || 'duration',
        data: [
            ['duration', _('Duration')],
            ['period', _('Period')],
            ['topic_filter', _('Topic Filter')]
        ],
        listeners: {
            'select': function(ev, comp) {
                var value = ev.value;
                if (value === 'period') {
                    select_by_duration_range.hide();
                    select_by_duration_offset.hide();

                    select_by_topic_filter_from.hide();
                    select_by_topic_filter_to.hide();

                    select_by_period_from.show();
                    select_by_period_to.show();
                } else if (value === 'duration') {
                    select_by_period_from.hide();
                    select_by_period_to.hide();

                    select_by_topic_filter_from.hide();
                    select_by_topic_filter_to.hide();

                    select_by_duration_range.show();
                    select_by_duration_offset.show();
                } else if (value === 'topic_filter') {
                    select_by_period_from.hide();
                    select_by_period_to.hide();

                    select_by_duration_range.hide();
                    select_by_duration_offset.hide();

                    select_by_topic_filter_from.show();
                    select_by_topic_filter_to.show();
                }
            }
        }
    });

    var query = new Ext.form.TextField({
        fieldLabel: _('Custom JSON query'),
        name: 'query',
        value: data.query,
        anchor: '100%'
    });
    var closed_statuses = new Baseliner.StatusBox({
        name: 'closed_statuses',
        fieldLabel: _('Close statuses'),
        value: data.closed_statuses || ''
    });

    var ccategory = new Baseliner.CategoryBox({
        name: 'categories',
        fieldLabel: _('Select topics in categories'),
        value: data.categories || ''
    });

    var common = params.common_options || Cla.dashlet_common(params);

    return common.concat([{
        xtype: 'label',
        text: _('General control'),
        style: {
            // 'margin': '10px',
            'font-size': '12px',
            'font-weight': 'bold'
        }
    }, {
        xtype: 'panel',
        hideBorders: true,
        layout: 'column',
        bodyStyle: 'margin: 3px; padding: 3px 3px;background:transparent;',
        items: [{
            layout: 'form',
            columnWidth: 0.5,
            bodyStyle: 'background:transparent;',
            items: [
                new Baseliner.ComboDouble({
                    fieldLabel: _('Chart will be shown as'),
                    name: 'type',
                    value: data.type || 'area',
                    data: [
                        ['area', _('Area')],
                        ['stack-area-step', _('Area step')],
                        ['line', _('Line')],
                        ['bar', _('Bar')],
                        ['scatter', _('Scatter')]
                    ]
                })
            ]
        }]
    }, {
        xtype: 'label',
        text: _('X-Axis'),
        style: {
            // 'margin': '10px',
            'font-size': '12px',
            'font-weight': 'bold'
        }
    }, {
        xtype: 'panel',
        hideBorders: true,
        layout: 'column',
        bodyStyle: 'margin: 3px; padding: 3px 3px;background:transparent;',
        items: [{
            layout: 'form',
            columnWidth: 0.5,
            bodyStyle: 'background:transparent;',
            items: [{
                    xtype: 'textfield',
                    anchor: '100%',
                    allowBlank: false,
                    fieldLabel: _('Topic date field'),
                    name: 'date_field',
                    value: data.date_field
                },
                scale_selector,
                selector,
                select_by_duration_range,
                select_by_duration_offset,
                select_by_period_from,
                select_by_period_to,
                select_by_topic_filter_from,
                select_by_topic_filter_to
            ]
        }]
    }, {
        xtype: 'label',
        text: _('Topics selection criteria'),
        style: {
            // 'margin': '10px',
            'font-size': '12px',
            'font-weight': 'bold'
        }
    }, {
        xtype: 'panel',
        hideBorders: true,
        layout: 'column',
        bodyStyle: 'margin: 3px; padding: 3px 3px;background:transparent;',
        items: [{
            layout: 'form',
            columnWidth: 1,
            bodyStyle: 'background:transparent;',
            items: [
                ccategory,
                closed_statuses,
                query
            ]
        }]
    }]);
})
