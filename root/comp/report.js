(function(params) {
	var ps = 25;
    
    //Baseliner.add_tabcomp( '/comp/topic/topic_grid.js', {}, function(res){
    //});
    
    /*
	var columns_grid = [];
	for (i=0;i < params.fields.length; i++){
		columns_grid.push({header: params.fields[i]});
	}

    var store = new Baseliner.JsonStore({
		baseParams: { select: params.fields },
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        url: '/report/list_topics',
		fields: params.fields,
		autoLoad: true
    });
	
	var colModel = new Ext.grid.ColumnModel({
		columns: columns_grid,	 
		defaults: {
			sortable: true,
			menuDisabled: true,
			width: 100
		}
   });
	
    var btn_html = {
        icon: '/static/images/icons/html.png',
        text: _('Basic HTML Report'),
        handler: function() {
            //form_report_submit({ url: '/topic/report_html' });
        }
    };

    var btn_html_desc = {
        icon: '/static/images/icons/html.png',
        text: _('Basic HTML Report (Description)'),
        handler: function() {
            //form_report_submit({ url: '/topic/report_html?show_desc=1' });
        }
    };

    var btn_yaml = {
        icon: '/static/images/icons/yaml.png',
        text: _('YAML'),
        handler: function() {
            //form_report_submit({ url: '/topic/report_yaml' });
        }
    };

    var btn_csv = {
        icon: '/static/images/icons/csv.png',
        text: _('CSV'),
        handler: function() {
            //form_report_submit({ url: '/topic/report_csv', target: 'FrameDownload' });
        }
    };
	
    var btn_reports = new Ext.Button({
        icon: '/static/images/icons/reports.png',
        iconCls: 'x-btn-icon',
        menu: [ btn_html, btn_html_desc, btn_csv, btn_yaml ]
    });
	
    var ps_plugin = new Ext.ux.PageSizePlugin({
        editable: false,
        width: 90,
        data: [
            ['5', 5], ['10', 10], ['15', 15], ['20', 20], ['25', 25], ['50', 50],
            ['100', 100], ['200',200], ['500', 500], ['1000', 1000], [_('all rows'), -1 ]
        ],
        beforeText: _('Show'),
        afterText: _('rows/page'),
        value: ps,
        listeners: {
            'select':function(c,rec) {
                ps = rec.data.value;
                if( rec.data.value < 0 ) {
                    ptool.afterTextItem.hide();
                } else {
                    ptool.afterTextItem.show();
                }
            }
        },
        forceSelection: true
    });
	
    var ptool = new Ext.PagingToolbar({
            store: store,
            pageSize: ps,
            plugins:[
                ps_plugin,
				new Ext.ux.ProgressBarPager()
            ],
            displayInfo: true,
            displayMsg: _('Rows {0} - {1} of {2}'),
            emptyMsg: _('There are no rows available')
    });	
	
    var grid_report = new Ext.grid.GridPanel({
        title: _('Topics'),
        header: false,
        autoScroll: true,
        stateful: !Baseliner.DEBUG,
        stateId: 'topic-grid',
		cm: colModel,
        store: store,
        dropable: true,
        autoSizeColumns: true,
        viewConfig: {forceFit: true},
        loadMask:'true',
        tbar:   [
				'->', 
                btn_reports
        ],
		bbar: ptool
    });
	
	return grid_report;
    */
})
