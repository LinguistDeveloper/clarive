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
        autoWidth: true,

        hidden: data.selection_method === 'duration_selection' ? false : true
    });

    var select_by_duration_offset = new Ext.form.TextField({
        fieldLabel: _('Offset'),
        name: 'select_by_duration_offset',
        value: data.select_by_duration_offset,

        width: 165,

        hidden: data.selection_method === 'duration_selection' ? false : true
    });

    var select_by_period_from = new Ext.form.DateField({
        fieldLabel: _("From"),
        value: data.select_by_period_from,
        name: "select_by_period_from",

        anchor: '100%',
        format: 'Y-m-d',
        height: 100,
        autoWidth: true,

        hidden: data.selection_method === 'period_selection' ? false : true
    });

    var select_by_period_to = new Ext.form.DateField({
        fieldLabel: _("To"),
        value: data.select_by_period_to,
        name: "select_by_period_to",

        anchor: '100%',
        format: 'Y-m-d',
        height: 100,
        autoWidth: true,

        hidden: data.selection_method === 'period_selection' ? false : true
    });

    var selector = new Ext.Container({
        fieldLabel: _('Date selection method'),
        value: data.selection_method,
        id: 'selection_method',
        layout: 'hbox',
        items: [{
            xtype: 'radiogroup',
            id: 'rdogrpMethod',
            items: [{
                    id: 'duration_selection',
                    boxLabel: _('Duration'),
                    name: 'selection_method',
                    inputValue: 'duration_selection',
                    checked: data.selection_method === 'duration_selection' ? true : false
                }, {
                    id: 'period_selection',
                    boxLabel: 'Period',
                    name: 'selection_method',
                    width: 20,
                    inputValue: 'period_selection',
                    checked: data.selection_method === 'period_selection' ? true : false
                }

            ],
            listeners: {
                'change': function(rg, checked) {
                    if (checked.id === 'period_selection') {
                        select_by_duration_range.hide();
                        select_by_duration_offset.hide();

                        select_by_period_from.show();
                        select_by_period_to.show();
                    } else if (checked.id === 'duration_selection') {
                        select_by_duration_range.show();
                        select_by_duration_offset.show();

                        select_by_period_from.hide();
                        select_by_period_to.hide();
                    }
                }
            }
        }]
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

    var group_by_period = new Baseliner.ComboDouble({
        fieldLabel: _('Group by date'),
        name: 'group_by_period',
        value: data.group_by_period || 'hour',
        data: [
            ['hour', _('Hour')],
            ['day_of_week', _('Day Of Week')],
            ['month', _('Month')],
            ['date', _('Date')]
        ],
    });

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
            items: [{
                    xtype: 'textfield',
                    anchor: '100%',
                    allowBlank: false,
                    fieldLabel: _('Group by field'),
                    name: 'date_field',
                    value: data.date_field
                },
                group_by_period,
                new Baseliner.ComboDouble({
                    fieldLabel: _('Chart will be shown as ...'),
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
        }, {
            layout: 'form',
            columnWidth: 0.5,
            bodyStyle: 'background:transparent;',
            items: [
                selector,
                select_by_duration_range,
                select_by_duration_offset,
                select_by_period_from,
                select_by_period_to,
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
