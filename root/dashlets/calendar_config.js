(function(params){
    var data = params.data || {};

    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });

    var common = Cla.dashlet_common(params);

    var weeks_from = new Ext.ux.form.SpinnerField({ 
        value: data.weeks_from==undefined?10:data.weeks_from, 
        name: "weeks_from",
        anchor:'100%',
        fieldLabel: _("Number of weeks back from today to start")
    });

    var weeks_until = new Ext.ux.form.SpinnerField({ 
        value: data.weeks_until==undefined?10:data.weeks_until, 
        name: "weeks_until",
        anchor:'100%',
        fieldLabel: _("Number of weeks after today to end")
    });

    var first_weekday = new Baseliner.ComboDouble({ anchor: '100%', fieldLabel:_('First Weekday'), name:'first_weekday', 
        value: data.first_weekday==undefined ? 0 : data.first_weekday,
        data: [ [0,_('Sunday')], [1,_('Monday')], [2,_('Tuesday')], [3,_('Wednesday')], [4,_('Thursday')], [5,_('Friday')], [6,_('Saturday')] ]
    });

    var query_type = new Baseliner.ComboDouble({ anchor: '100%', fieldLabel:_('Calendar Query'), name:'query_type', 
        value: data.query_type==undefined ? 'start_end' : data.query_type,
        data: [ 
            ['start_end',_('Topic Activity (from Created to Modified Dates)')], 
            ['open_topics',_('Open Topics (from Created to Closed Dates)')], 
            ['cal_field',_('Calendar Field (like Milestones or Environment Planner)')] 
        ]
    });
    query_type.on('change', function(){
        query_type.getValue()!='cal_field' ? id_fieldlet.hide() : id_fieldlet.show( );
        id_fieldlet.allowBlank = query_type.getValue()!='cal_field';
    });

    var id_fieldlet = new Ext.form.TextField({ 
        anchor:'100%', fieldLabel: _('Calendar Fields'), name: 'id_fieldlet', 
        value: data.id_fieldlet, hidden: data.query_type!='cal_field', allowBlank: data.query_type!='cal_field'
    });

    var default_view = new Baseliner.ComboDouble({ anchor: '100%', fieldLabel:_('Default View'), name:'default_view', 
        value: data.default_view==undefined ? 'month' : data.default_view,
        data: [ ['month',_('Month')], ['basicWeek',_('Basic Week')], ['agendaWeek',_('Agenda Week')], ['basicDay',_('Basic Day')], ['agendaDay',_('Agenda Day')] ]
    });
    return common.concat([
        {
            xtype: 'label',
            text: _('Topics selection criteria'),
            style: {
                // 'margin': '10px',
                'font-size': '12px',
                'font-weight': 'bold'
            }
        },
        { xtype:'panel', 
          hideBorders: true, 
          layout:'column', 
          bodyStyle: 'margin: 3px; padding: 3px 3px;background:transparent;',
          items:[
            { layout:'form', 
              columnWidth: .90, 
              bodyStyle: 'background:transparent;',
              items: [
                query_type,
                id_fieldlet,
                default_view,
                first_weekday,
                ccategory,
                { xtype : "checkbox", name : "not_in_category", checked: data.not_in_category=='on' ? true : false, boxLabel : _('Exclude selected categories?') },
                { xtype : "checkbox", name : "show_jobs", checked: Baseliner.eval_boolean(data.show_jobs), boxLabel : _('Show Jobs?') },
                { xtype:'textarea', height: 80, anchor:'100%', fieldLabel: _('Advanced JSON/MongoDB condition for filter'), name: 'condition', value: data.condition },
                { xtype:'textarea', height: 80, anchor:'100%', fieldLabel: _('Label Mask'), name: 'label_mask', 
                    value: data.label_mask || '${category.acronym}#${topic.mid} ${topic.title}' }
              ]
            }
          ]
        }
    ]);
})


