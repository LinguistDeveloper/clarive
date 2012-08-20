//INFORMACIÓN DEL CONTROL DE VERSIONES
//
//	CAM .............................. SCM
//	Pase ............................. N.TEST0000054318
//	Fecha de pase .................... 2011/11/22 13:08:29
//	Ubicación del elemento ........... /SCM/FICHEROS/UNIX/baseliner/features/sqa/root/comp/sqa/grid.js
//	Versión del elemento ............. 2
//	Propietario de la version ........ q74612x (Q74612X - RICARDO MARTINEZ HERRERA)
<%args>
	$action_view_general
	$action_new_analysis
	$action_project_config
	$action_global_config
	$action_request_recalc
	$action_request_analysis
	$action_sqa_config
	$action_sqa_project
	$action_sqa_subproject
	$action_sqa_subprojectnature
	$action_sqa_packages
	$action_delete_analysis
	$global_run_sqa_test
	$global_run_sqa_ante
	$global_run_sqa_prod
	$global_block_deployment_test
	$global_block_deployment_ante
	$global_block_deployment_prod
	$sqa_url
	$scm_url
</%args>
(function(){
	//Cargamos la página de checking para crear la cookie de acceso a la interfaz de producto y no pida login al acceder a los informes
	//document.all.FrameDownload.src = 'http://wbetest.bde.es/sqamain';
	
	Baseliner.help_push( { title:_("SQA Help"), path: "sqa" } );
	
	document.title = "SCM_SQA - Baseliner";
	var ps = 25;
	
	String.prototype.startsWith = function(str) 
	{return (this.match("^"+str)==str)}

	var global_run_sqa_test = '<% $global_run_sqa_test %>';	
	var global_run_sqa_ante = '<% $global_run_sqa_ante %>';	
	var global_run_sqa_prod = '<% $global_run_sqa_prod %>';	
	var global_block_deployment_test = '<% $global_block_deployment_test %>';	
	var global_block_deployment_ante = '<% $global_block_deployment_ante %>';	
	var global_block_deployment_prod = '<% $global_block_deployment_prod %>';	

	var gridType = 'NAT';
	var gId;
	var myMask = new Ext.LoadMask(Ext.getBody(), {msg:_("Please wait...")});
	
	var reader=new Ext.data.JsonReader({
		root: 'data' , 
		remoteSort: true,
		totalProperty:"totalCount", 
		id: 'id' 
		},
		[ 
			{  name: 'id' },
			{  name: 'ns' },
			{  name: 'bl' },
			{  name: 'status' },
			{  name: 'project' },
			{  name: 'actions' },
			{  name: 'tsstart', type: 'date', dateFormat: 'd/m/Y H:i:s' },
			{  name: 'tsend', type: 'date', dateFormat: 'd/m/Y H:i:s' },
			{  name: 'result' },
			{  name: 'qualification' },
			{  name: 'global' },
			{  name: 'subapp' },
			{  name: 'nature' },
			{  name: 'has_html' },
			{  name: 'links' },
			{  name: 'packages' },
			{  name: 'type' },
			{  name: 'id_project' },
			{  name: 'tests_errors' },
			{  name: 'tests_coverture' },
			{  name: 'url_errors' },
			{  name: 'url_coverture' },
			{  name: 'run_sqa_test' },
			{  name: 'block_deployment_test' },
			{  name: 'run_sqa_ante' },
			{  name: 'block_deployment_ante' },
			{  name: 'run_sqa_prod' },
			{  name: 'block_deployment_prod' },
			{  name: 'trend' }
		]
	);

	var store = new Ext.data.GroupingStore({
		id: 'id',
		autoload: false,
        reader: reader,
        remoteGroup: true,
        baseParams: { limit: ps },
        remoteSort: true,
        url: '/sqa/grid_json',
        groupField: 'project'
    //    groupOnSort: true
    });

    var paging = new Ext.PagingToolbar({
        store: store,
        pageSize: ps,
        displayInfo: true,
        displayMsg: '<% _loc('Rows {0} - {1} of {2}') %>',
        emptyMsg: "No hay registros disponibles"
    });

	paging.on('beforechange', function(){ refresh_stop(); });

    var next_start = 0;
    
    store.on('load', function(s,recs,opt) {
        //console.log( s );
        next_start = s.reader.jsonData.next_start;
        //store.baseParams.next_start = next_start;
        //alert(next_start);
		gridType = store.reader.jsonData.gridType;
		//alert("Tipo: " + gridType);
		myMask.hide();        
    });

    paging.on("beforechange", function(p,opts) {
        opts.next_start = next_start;
    });
    
    var first_load = true;
    
	store.on("beforeload", function (s){
        if( first_load ) {
        	myMask.show();
            first_load = false;
        }
		s.baseParams.type = gridType;
	});
	
	
	
    <& /comp/search_field.mas &>

    var search_field = new Ext.app.SearchField({
		store: store,
		params: {start: 0, limit: ps, type: gridType },
		emptyText: '<% _loc('<Enter your search string>') %>'
	});
    var render_icon = function(value,metadata,rec,rowIndex,colIndex,store) {
		var icon = '/static/images/scm/release.gif';
		
		if ( rec.data.type == 'CAM') {
			icon = '/static/images/silk/world.png';
		} else if ( rec.data.type == 'SUB' ) {
			icon = '/static/images/scm/project.gif';
		} else if ( rec.data.type == 'NAT' ) {
			icon = '/static/images/scm/subapp.gif';
		} else {
			icon = '/static/images/scm/package.gif';
		}

		
		return "<img alt='"+ rec.id_project +"' border=0 src='"+icon+"' />";
		//return "<div style='float: left; margin-top: 2'><img alt='"+ rec.id +"' border=0 src='"+icon+"' /></div><div style='font-family: Tahoma; font-size:10pt; margin-top: 4'><b>" + value + "</b></div>" ;
    };

    var render_item = function(value,metadata,rec,rowIndex,colIndex,store) {
		return "<b>" + value + "</b>" ;
    };

    var render_html_link = function(value,metadata,rec,rowIndex,colIndex,store) {
    	var id = rec.data.id;
    	if(value !=1) return "";
    	if (rec.data.type != 'NAT' && rec.data.status != 'SCM ERROR' && rec.data.status != 'SQA ERROR') return ""; 
    	return "<a target='_blank' href='/sqa/view_html/" + id + "'><img border=0 src='/static/images/preview.png'/></a>";
    };

    var render_qual = function(value,metadata,rec,rowIndex,colIndex,store) {

		if( rec.data.status != 'OK' && rec.data.status != 'FAILURE' ) {
			return " ";
		} else {
			if ( !value || value == '' || value.len == 0) value = ' ';
			return "<div style='font-family: Tahoma; font-size:8pt; margin-top: 0'><b>" + value + "</b></div>" ;
		}
    };

    var render_result = function(value,metadata,rec,rowIndex,colIndex,store) {
		var img;
		if( rec.data.status == 'running' ) {
			img = '/static/images/indicator.gif';
			value = _('Running');
		} else {
			if( rec.data.type == 'NAT' && value == 'FAILURE' ) img='/static/images/silk/flag_red.png';
			else if ( rec.data.type == 'NAT' && value == 'OK' ) img='/static/images/silk/flag_green.png';
			else if ( rec.data.type == 'NAT' ) img='/static/images/icons/help.png';
			else img = '';
		}
		if ( img != '') return "<img src='"+img+"' border=0 /><b>" + _(value) + "</b>" ;
		else return "";
    };
    
    var render_trend = function(value,metadata,rec,rowIndex,colIndex,store) {
		var img;
		
		if( rec.data.trend == '?' ) {
			img = '';
		} else if( rec.data.trend == '1' ) {
			img = '/static/images/silk/arrow_up.png';
		} else if ( rec.data.trend == '0' ){
			img = '/static/images/silk/arrow_refresh.png';
		} else {
			img = '/static/images/silk/arrow_down.png';
		}	
		if ( img != '') return "<img src='"+img+"' border=0 />" ;
		else return "";
    };
    
    var render_status = function(value,metadata,rec,rowIndex,colIndex,store) {
		var img;
		if( rec.data.status == 'running' ) {
			img = '/static/images/indicator.gif';
			value = _('Running');
		} else {
			if( value == 'FAILURE' ) {
				img='/static/images/silk/action_stop.png';
				value = 'ERROR';
			} else if( value == 'OK' ) { 
				img='/static/images/silk/accept.png';
				value = 'END';
			} else {
				img='/static/images/icons/help.png';
			}
		}
		return "<img src='"+img+"' border=0><b>" + _(value) + "</b>" ;
    };
    
    var render_tests_errors = function(value,metadata,rec,rowIndex,colIndex,store) {
    	var id = rec.data.id;

    	if ( !rec.data.tests_errors ) return _("NO TESTS"); 
    	return "<a target='_blank' href='" + rec.data.url_errors + "'>" + rec.data.tests_errors + "</a>";
    };

    var render_tests_coverture = function(value,metadata,rec,rowIndex,colIndex,store) {
    	var id = rec.data.id;

    	if ( !rec.data.tests_coverture ) return _("NO TESTS"); 
    	return "<a target='_blank' href='" + rec.data.url_coverture + "'>" + rec.data.tests_coverture + "</a>";
    };
    
    var render_config_options = function(value,metadata,rec,rowIndex,colIndex,store) {
		var ret;
		if( value == 'Y' ) {
			ret = "<img src='/static/images/silk/accept.png' border=0>" ;
		} else if( value == 'N' ) {
			ret = "<img src='/static/images/silk/delete.png' border=0>" ;
		} else {
			ret = value;
		}
		return ret;
    };


	
% if ( $action_request_analysis ) {	
    var button_request_analysis = new Ext.Toolbar.Button({
		text: _('Request analysis'),
		hidden: true,
		icon:'/static/images/silk/control_play_blue.png',
		cls: 'x-btn-text-icon',
		handler: function() {
			var sm = grid.getSelectionModel(); 
			myMask.show();
			if (sm.hasSelection()) {
				var rec = sm.getSelected();
				if (rec.data.type == 'NAT') {
					gNature = rec.data.nature;
					gProject = rec.data.project;
					gSubapp = rec.data.subapp;
					gBl = rec.data.bl;
					gId = rec.data.id;
					projects_check();
				} else if (rec.data.type == 'SUB') {
					if (confirm(_("Plase, confirm that you want to request the analysis of every nature of ") + rec.data.subapp)) {
					
						Baseliner.ajaxEval( '/sqa/request_subapp_projects', 
								{ bl: rec.data.bl, project: rec.data.project, subapp_id: rec.data.id_project }, 
								function(response) {
									if ( response.success ) {
										Baseliner.message( _('SUCCESS'), _('analysis requested') );
										store.load({params:{type: gridType, limit: ps }});
									} else {
										Baseliner.message( _('ERROR'), _('analysis not requested') );
									}
								}
						);					
					}
					myMask.hide();
				} else if (rec.data.type == 'CAM') {
					if (confirm(_("Plase, confirm that you want to request the analysis of every subproject of ") + rec.data.project)) {
						Baseliner.ajaxEval( '/sqa/request_cam_projects', 
								{ bl: rec.data.bl, project: rec.data.project, project_id: rec.data.id_project }, 
								function(response) {
									Baseliner.message( _('SUCCESS'), _('analysis requested') );
									store.load({params:{type: gridType, limit: ps }});
								}
						);					
					}
					myMask.hide();
				}

			} else {
				Baseliner.message( _('ERROR'), _('Please select a row') );
			};
		}
    });
    
	var request_analysis = function(project_name) {
		
		//alert("Estoy en request_analysis");

		Baseliner.ajaxEval( '/sqa/request_analysis', 
			{ project_id: gId, project_name: project_name, bl: gBl, nature: gNature, project: gProject, subapp: gSubapp }, 
			function(response) {
				Baseliner.message( _('SUCCESS'), _('analysis requested') );
				store.load({params:{type: gridType, limit: ps }});
				myMask.hide();
			}
		);
	};
% }

% if ( $action_delete_analysis ) {	
    var button_delete_analysis = new Ext.Toolbar.Button({
		text: _('Delete analysis'),
		icon:'/static/images/silk/table_delete.png',
		cls: 'x-btn-text-icon',
		hidden: true,
		handler: function () {
    		delete_analysis()
    	}
    });
	var delete_analysis = function() {
		var sm = grid.getSelectionModel();
		var selected = sm.getSelected();
		
		if (confirm(_("Plase, confirm that you want to delete the analysis of ") + selected.data.project )) {
			Baseliner.ajaxEval( '/sqa/delete_analysis',
				{ id: selected.data.id },
				
					function(response) {
						Baseliner.message( _('SUCCESS'), _('Analysis deleted') );
						store.load({params:{type: gridType, limit: ps }});
						myMask.hide();
					}
			);
		};
		hide_all_buttons();
	};
% }

% if ( $action_new_analysis ) {	
    var button_new_analysis = new Ext.Toolbar.Button({
		text: _('New analysis'),
		icon:'/static/images/silk/icon_wand.gif',
		cls: 'x-btn-text-icon',
		hidden: true,
		handler: function () {
    		new_analysis()
    	}
    });
% }

% if ( $action_project_config ) {	
    var button_remove_config = new Ext.Toolbar.Button({
		text: _('Remove config'),
		icon:'/static/images/silk/page_delete.gif',
		cls: 'x-btn-text-icon',
		hidden: true,
		handler: function () {
			var sm = grid.getSelectionModel(); 

			if (sm.hasSelection()) {
				if (confirm(_("Please, confirm that you want to remove the SQA configuration for the project"))) {
					remove_config();
					button_remove_config.hide();
				}
			} else {
				Baseliner.message( _('ERROR'), _('Please select a row') );
			};	
    }
    });
			
	var remove_config = function() {
		var sm = grid.getSelectionModel();
		var selected = sm.getSelected();
		
		Baseliner.ajaxEval( '/sqa/remove_config',
			{ project_id: selected.data.id }, 
			function(response) {
				Baseliner.message( _('SUCCESS'), _('Configuration deleted') );
				store.load({params:{type: gridType, limit: ps }});
				myMask.hide();
			}
		);
	};

    var button_edit_config = new Ext.Toolbar.Button({
		text: _('Edit config'),
		icon:'/static/images/silk/page_edit.gif',
		cls: 'x-btn-text-icon',
		hidden: true,
		handler: function () {
			var sm = grid.getSelectionModel();
			var selected = sm.getSelected();

			if (sm.hasSelection()) {
				edit_config(selected.data.id);
			} else {
				Baseliner.message( _('ERROR'), _('Please select a row') );
			};	
    }
    });

% }

% if ( $action_global_config ) {	

    var button_global_config = new Ext.Toolbar.Button({
		text: _('Edit global'),
		icon:'/static/images/silk/page_white_world.png',
		cls: 'x-btn-text-icon',
		hidden: true,
		handler: function () {
			edit_config('global');
		}
    });

% }

% if ( $action_request_recalc ) {	
    var button_request_recalc = new Ext.Toolbar.Button({
		text: _('Request recalc'),
		hidden: true,
		icon:'/static/images/silk/chart_curve_go.png',
		cls: 'x-btn-text-icon',
		handler: function() {
			var sm = grid.getSelectionModel(); 
			myMask.show();
			if (sm.hasSelection()) {
				recalc();
			} else {
				Baseliner.message( _('ERROR'), _('Please select a row') );
			};
			
		}
    });
        
	var recalc = function() {
		var sm = grid.getSelectionModel();
		var selected = sm.getSelected();
		
		var subapp;
		var nature;
		var level;

		if ( !selected.data.subapp ){
			subapp = '*none';
			nature = '*none';
			level = 'CAM';
		} else if ( !selected.data.nature ){
			subapp = selected.data.subapp;
			nature = '*none';
			level = 'Subaplicacion';
		} else {
			subapp = selected.data.subapp;
			nature = selected.data.nature;
			level = 'Recalc';
		}


		Baseliner.ajaxEval( '/sqa/request_recalc',
			{ project_id: selected.data.id, bl: selected.data.bl, nature: nature, project: selected.data.project, subapp: subapp, level: level }, 
			function(response) {
				Baseliner.message( _('SUCCESS'), _('analysis recalculated') );
				store.load({params:{type: gridType, limit: ps }});
				myMask.hide();
			}
		);
	};
% }

	var user_manual = {
		text: _('User manual'),
		icon:'/static/images/silk/book.png',
		handler: function () {
			window.open('/static/manuals/user_manual.pdf', 'SCM_SQA');
		}
	};
	
	var sqa_rules = {
		text: _('Checking rules'),
		icon:'/static/images/silk/book.png',
		handler: function () {
			window.open('<% $sqa_url %>/reglas', 'SCM_SQA');
		}
	};
	
	var checking_portal = {
			text: _('Checking portal'),
			icon:'/static/images/silk/link.png',
			handler: function () {
				window.open('<% $sqa_url %>', 'SCM_SQA');
			}
	};
	
	var scm_portal = {
			text: _('SCM Portal'),
			icon:'/static/images/silk/link.png',
			handler: function () {
				window.open('<% $scm_url %>', 'SCM_SQA');
			}
	};

	var docs_menu = new Ext.Toolbar.Button({
	    text: _('Documents'),
	    icon: '/static/images/silk/help.png',
	    menu: [user_manual, sqa_rules, checking_portal, scm_portal]
    });

	//---------- Refreshments
    var task = {
        run: function() {
				refresh_button_off();
				try {
					store.load({params:{type: gridType, limit: ps }});
				} catch(e) { }
		},
        interval: 30000
    };
    var autorefresh = new Ext.util.TaskRunner();
	var refresh_set = function( item, checked  ) {
		if( checked && item.value>0 ) {
			task.interval = item.value * 1000;
			autorefresh.start(task); 
		} 
		else if( checked && item.value<1 ) {
			autorefresh.stop( task );
		}
	};
	var refresh_button_on = function() { refresh_button.getEl().setOpacity( .3 ); };
	var refresh_button_off = function() { refresh_button.getEl().setOpacity( 1 ); };
	var refresh_menu = new Ext.menu.Menu({
			items: [
				{ text: _('Stopped'), value: 0, checked: true, group: 'refresh', checkHandler: refresh_set },
				{ text: _('%1 seconds', 15), value: 15, checked: true, group: 'refresh', checkHandler: refresh_set },
				{ text: _('%1 seconds', 30), value: 30, checked: true, group: 'refresh', checkHandler: refresh_set },
				{ text: _('%1 minute', 1), value: 60, checked: true, group: 'refresh', checkHandler: refresh_set },
				{ text: _('%1 minutes', 5), value: 300, checked: true, group: 'refresh', checkHandler: refresh_set }
			]
	});
	var refresh_button = new Ext.Toolbar.Button({
					text: _loc('Refresh'),
					icon: '/static/images/icons/time.gif', 
					cls: 'x-btn-text-icon',
					menu: refresh_menu
	});
	var refresh_stop = function() {
		refresh_menu.items.first().setChecked(true);
		autorefresh.stop(task);
	};
	
	var tbar = new Ext.Toolbar({ items: [ _('Search') + ': ', ' ',
					search_field, 
//					status_combo,
					{ xtype:'button', icon:'/static/images/silk/action_refresh.gif', text:_('Refresh'), handler:function()
						{
							store.load({ params: { query: search_field.getRawValue(), type: gridType, limit: ps } }); 
							gview.refresh();
						}
					},

% if ( $action_request_analysis ) {	
					button_request_analysis,
%}

% if ( $action_request_recalc ) {	
					button_request_recalc, 
%}
% if ( $action_delete_analysis ) {
	button_delete_analysis,
%}
% if ( $action_new_analysis ) {	
					button_new_analysis,
%}
% if ( $action_project_config ) {
					button_remove_config,
					button_edit_config,
%}
% if ( $action_global_config ) {
					button_global_config,
%}
					'->',
					docs_menu,
					refresh_button
				]
	}); 
	// create the grid
	var gview = new Ext.grid.GroupingView({
        forceFit: true,
        enableRowBody: true,
        autoWidth: true,
        autoSizeColumns: true,
        deferredRender: true,
        startCollapsed: false,
        hideGroupedColumn: true
        //groupTextTpl: '{[ values.rs[0].data["' + grouping + '"] ]}'
	});

	var grid = new Ext.grid.GridPanel({
		title: _('Portal de Calidad'),
		header: false,
% unless( $c->debug ) {		
		stateId: 'sqa_grid',
		stateful: false,
% }		
		layout   : 'fit',
		region   : 'center',
		split    : true,
	    frame    : false,
		stripeRows: true,
		autoScroll: true,
		autoDestroy: true,
		autoWidth: true,
		autoSizeColumns: true,
		deferredRender: true,
		store: store,
		view: gview,
		height: 300,
		viewConfigxx: [{
				forceFit: true,
				enableRowBody:true,
				showPreview:true,
				getRowClass : function(record, rowIndex, p, store){
						p.body = '<p>'+record.data.name+'</p>';
						return 'x-grid3-row-expanded';
				}
		}],
		selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		//loadMask:'false',
		columns: [
			{ header: _('Level'), id:'icon', width: 30, dataIndex: 'icon', hidden: false, sortable: true, renderer: render_icon },	
			{ header: _('Baseline'), id: 'bl', width: 80, dataIndex: 'bl', sortable: true, tooltip: _("State in the life cycle of the source code for this analysis") },	
			{ header: _('Project'), id: 'project', width: 40, dataIndex: 'project', sortable: true, renderer: render_item, tooltip: _("Name of the project") },
			{ header: _('ID Project'), id: 'id_project', width: 40, dataIndex: 'id_project', sortable: true, renderer: render_item, tooltip: _("ID of the project"), hidden: true },
			{ header: _('Subapplication'), id: 'subapp', width: 70, dataIndex: 'subapp', sortable: true, tooltip: _("Name of the subproject") },
			{ header: _('Nature'), id: 'nature', width: 70, dataIndex: 'nature', sortable: true, tooltip: _("Nature of the subproject") },
			{ header: _('Metrics'), id: 'global', width: 150, dataIndex: 'global', sortable: false, menuDisabled: true, tooltip: _("Summary of the results extracted from the audit report") },
			{ header: _('Start'), id:'tsstart', width: 80, dataIndex: 'tsstart', xtype: 'datecolumn', format: 'd/m/Y H:i:s', sortable: true, tooltip: _("Date and time when the analysis started") },
			{ header: _('End'), id: 'tsend', width: 80, dataIndex: 'tsend', xtype: 'datecolumn', format: 'd/m/Y H:i:s', sortable: true, tooltip: _("Date and time when the analysis finished") },
			{ header: _('Qualification'), id: 'qualification', width: 100, dataIndex: 'qualification', sortable: true, renderer: render_qual, tooltip: _("Qualification of the analysis.  The value is the GLOBAL indicator of the report") },
			{ header: _('Result'), id: 'result', width: 100, dataIndex: 'result', sortable: true , renderer: render_result, tooltip: _("Result of the analysis") },
			{ header: _('HTML Report'), id: 'has_html', width: 130, dataIndex: 'has_html' , renderer: render_html_link, menuDisabled: true, tooltip: _("Link to the results or error report") },
			{ header: _('Packages'), id: 'packages', width: 130, dataIndex: 'packages' , hidden: true, tooltip: _("List of packages included in the analysis") },
			{ header: _('Reports'), id: 'links', width: 70, dataIndex: 'links' , hidden: true, tooltip: _("Links to the reports with the results of the analysis by programming language") },
			{ header: _('analysis status'), id: 'status', width: 100, dataIndex: 'result', sortable: true , renderer: render_status, hidden: true, tooltip:_("Status of the last analysis") },
			{ header: _('HTML Report'), id: 'has_html2', width: 130, dataIndex: 'has_html' , renderer: render_html_link, menuDisabled: true, hidden: true, tooltip: _("Link to the results or error report") },
			{ header: _('%Errors'), id: 'tests_errors', width: 70, dataIndex: 'tests_errors' , renderer: render_tests_errors, menuDisabled: true, tooltip: _("% of unit tests failed") },
			{ header: _('%Coverture'), id: 'tests_coverture', width: 70, dataIndex: 'tests_coverture' , renderer: render_tests_coverture, menuDisabled: true, tooltip: _("% of code coverture of the tests") },
			{ header: _('Run SQA') + '(TEST)', id: 'run_sqa_test', width: 50, dataIndex: 'run_sqa_test' , align: 'center', renderer: render_config_options, hidden: true, menuDisabled: false, tooltip: _("Run SQA or not") },
			{ header: _('Run SQA') + '(ANTE)', id: 'run_sqa_ante',width: 50, dataIndex: 'run_sqa_ante' , align: 'center', renderer: render_config_options, hidden: true, menuDisabled: false, tooltip: _("Run SQA or not") },
			{ header: _('Run SQA') + ' (PROD)', id: 'run_sqa_prod', width: 50, dataIndex: 'run_sqa_prod' , align: 'center', renderer: render_config_options, hidden: true, menuDisabled: false, tooltip: _("Run SQA or not") },
			{ header: _('Block deployment') + '(TEST)', id: 'block_deployment_test', width: 50, dataIndex: 'block_deployment_test' , align: 'center', renderer: render_config_options, hidden: true, menuDisabled: false, tooltip: _("Block or not") },
			{ header: _('Block deployment') + '(ANTE)', id: 'block_deployment_ante', width: 50, dataIndex: 'block_deployment_ante' , align: 'center', renderer: render_config_options, hidden: true, menuDisabled: false, tooltip: _("Block or not") },
			{ header: _('Block deployment') + '(PROD)', id:  'block_deployment_prod', width: 50, dataIndex: 'block_deployment_prod' , align: 'center', renderer: render_config_options, hidden: true, menuDisabled: false, tooltip: _("Block or not") },
			{ header: _('Trend'), id: 'trend', width: 50, dataIndex: 'trend' , align: 'center', renderer: render_trend, hidden: false, menuDisabled: false, tooltip: _("Trend respect to the previous analysis") },
			{ header: _('Namespace'), id: 'ns', width: 80, dataIndex: 'ns', hidden: true }
		],     
		tbar: tbar,
		bbar: paging
	});
	
	
	grid.on("rowclick", function(grid, rowIndex, e ) {
		
		var r = grid.getStore().getAt(rowIndex);

		var actions = r.data.actions;

		myMask.show();

		hide_all_buttons();
		
		Baseliner.ajaxEval( '/sqa/get_row_permissions', { project_id: r.data.id_project, type: gridType }, 
			function(response) {
				if ( response.success ) {
					//Baseliner.message( _('HELLO'), _('The value is %1', response.permissions.edit_config ) );
					if ( gridType.startsWith('CFG') ) {
% if ( $action_project_config) {
						if ( response.permissions.edit_config == 0 ) {
							button_edit_config.hide();
							button_remove_config.hide();
						} else {
							button_edit_config.show();
							button_remove_config.show();
						}
%}
					} else if ( gridType == 'PKG' ) {
					} else {
						//Baseliner.message( _('HELLO'), _('The value is %1', response.permissions.button_request_recalc ) );
% if ( $action_new_analysis ) {
						
						if ( gridType == 'NAT' ) {
							button_new_analysis.show() ;
						}
%}
% if ( $action_delete_analysis) {
						if ( response.permissions.delete_analysis == 0 ) {
							button_delete_analysis.hide();
						} else {
							button_delete_analysis.show();
						}						
%}
% if ( $action_request_recalc) {
						if ( response.permissions.request_recalc == 0 ) {
							button_request_recalc.hide();
						} else {
							if ( r.data.result != 'BUILD ERROR' ) {
								button_request_recalc.show();
							}
						}						
%}
% if ( $action_request_analysis) {
						if ( response.permissions.request_analysis == 0 ) {
							button_request_analysis.hide();
						} else {
							if( r.get('nature') != 'JAVABATCH' ) button_request_analysis.show();
						}						
%}

					}
				} else {
					Baseliner.message( _('ERROR'), _('Error getting row permissions') );
				}
				tbar.doLayout();
				myMask.hide();
			}

		);

// % if ( $action_request_analysis ) {
// 		button_request_analysis.hide();
// %}


	});
	

	
	// grid.on("rowdblclick", function(grid, rowIndex, e){
	// 	if ( gridType.startsWith('CFG')) {
	// 		var sm = grid.getSelectionModel();
	// 		var r = sm.getSelected();

	// 		edit_config(r.data.id);
	// 	}
	// });

	var edit_config = function(project_id){
		var sm = grid.getSelectionModel();
		var r;
		if ( sm.hasSelection() ){
			r = sm.getSelected();
		}

		var run_sqa_test;
		var run_sqa_ante;
		var run_sqa_prod;
		var block_deployment_test;
		var block_deployment_ante;
		var block_deployment_prod;
		
		
		if ( project_id == 'global') {
			run_sqa_test = global_run_sqa_test;
			run_sqa_ante = global_run_sqa_ante;
			run_sqa_prod = global_run_sqa_prod;
			block_deployment_test = global_block_deployment_test;
			block_deployment_ante = global_block_deployment_ante;
			block_deployment_prod = global_block_deployment_prod;		
		} else {
			run_sqa_test = r.data.run_sqa_test;
			run_sqa_ante = r.data.run_sqa_ante;
			run_sqa_prod = r.data.run_sqa_prod;
			block_deployment_test = r.data.block_deployment_test;
			block_deployment_ante = r.data.block_deployment_ante;
			block_deployment_prod = r.data.block_deployment_prod;					
		}

		var chk_run_sqa_test = new Ext.form.Checkbox({
			fieldLabel: _('Run SQA'),
			name: 'chk_run_sqa_test',
			checked: run_sqa_test=='Y'?true:false
		});
		var chk_run_sqa_ante = new Ext.form.Checkbox({
			fieldLabel: _('Run SQA'),
			name: 'chk_run_sqa_ante',
			checked: run_sqa_ante=='Y'?true:false
		});
		var chk_run_sqa_prod = new Ext.form.Checkbox({
			fieldLabel: _('Run SQA'),
			name: 'chk_run_sqa_prod',
			checked: run_sqa_prod=='Y'?true:false
		});
		var chk_block_deployment_test = new Ext.form.Checkbox({
			fieldLabel: _('Block deployment'),
			name: 'chk_block_deployment_test',
			checked: block_deployment_test=='Y'?true:false
		});
		var chk_block_deployment_ante = new Ext.form.Checkbox({
			fieldLabel: _('Block deployment'),
			name: 'chk_block_deployment_ante',
			checked: block_deployment_ante=='Y'?true:false
		});
		var chk_block_deployment_prod = new Ext.form.Checkbox({
			fieldLabel: _('Block deployment'),
			name: 'chk_block_deployment_prod',
			checked: block_deployment_prod=='Y'?true:false
		});
		var fproject_id = new Ext.form.Hidden({
			name: 'fproject_id',
			value: project_id
		});
		
		var fieldsTest = new Ext.form.FieldSet({
			title: 'TEST',
			columnWidth: 0.33,
			collapsible: false,
			items: [ chk_run_sqa_test, chk_block_deployment_test ]
		});
		
		var fieldsAnte = new Ext.form.FieldSet({
			title: 'ANTE',
			columnWidth: 0.33,
			collapsible: false, 
			items: [ chk_run_sqa_ante, chk_block_deployment_ante ]
		});
		
		var fieldsProd = new Ext.form.FieldSet({
			title: 'PROD',
			columnWidth: 0.33,
			collapsible: false, 
			items: [ chk_run_sqa_prod, chk_block_deployment_prod ]
		});
		
		var project_config_form = new Ext.FormPanel({
			frame: true,
			layout: 'column',
			url:'/sqa/update_config',
			bodyStyle:'padding:5px 5px 0',
		    defaults: {      // defaults applied to items
		        layout: 'form',
		        border: false,
		        bodyStyle: 'padding:4px',
		        halign: 'center'
		    },
            buttons: [
                {
                    text: _('Accept'),
                    type: 'submit',
                    handler: function() {
        				var ff = project_config_form.getForm();
        				ff.submit({
        						success: function(form, action) { 
        							if ( project_id == 'global' ) {
        								global_run_sqa_test = chk_run_sqa_test.checked?'Y':'N';
        								global_run_sqa_ante = chk_run_sqa_ante.checked?'Y':'N';
        								global_run_sqa_prod = chk_run_sqa_prod.checked?'Y':'N';
        								global_block_deployment_test = chk_block_deployment_test.checked?'Y':'N';
        								global_block_deployment_ante = chk_block_deployment_ante.checked?'Y':'N';
        								global_block_deployment_prod = chk_block_deployment_prod.checked?'Y':'N';
        							}
        							store.load({params:{type: gridType, limit: ps }});
        							win.close(); 
        						},
        						failure: function(form, action) { 
        							Ext.Msg.alert(_('Failure'), action.result.msg);
        						}
        				});
        			}
                },
                {
                    text: _('Cancel'),
                    handler: function(){ win.close(); }
                }
            ],
			items: [ fieldsTest, fieldsAnte, fieldsProd, fproject_id ]
		});
		
		var windowtitle = 'pp';
		if (project_id == 'global') {
			windowtitle = _("Global configuration");
		} else {
			windowtitle = _("Configuration of ") + r.data.project + ' ' + r.data.subapp + ' ' + r.data.nature;
		}
		var win = new Ext.Window({
			layout: 'fit', 
			autoScroll: true,
			title: windowtitle,
			height: 170, width: 480, 
			items: [ project_config_form ]
		});
		win.show();
	}
	
	grid.on('groupchange', function(){
		//alert("aaa");
	});
	
	var selected;
	

	var cnt;
	var project_id;
	
	var new_analysis = function() {

		var bl_store = new Ext.data.SimpleStore({
			fields: ['bl_text'],
			data: [ ['DESA'],['TEST'], ['ANTE'], ['PROD'] ]
		});
		
		var bl_combo = new Ext.form.ComboBox({
			name: 'bl',
			hiddenName: 'bl',
			fieldLabel: _('Baseline'),
			store: bl_store,
			displayField: 'bl_text',
			valueField: 'bl_text',
			lazyRender: false,
			value: '',
			mode: 'local',
			editable: true,
			triggerAction: 'all'
		});
		
		var store_projects_new = new Ext.data.JsonStore({ 
			root: 'data' ,
			remoteSort: true,
			totalProperty: 'totalCount',
			baseParams: { all: true },
			url: '/sqa/harvest_all_projects',
			fields: [ 
						{  name: 'id' },
						{  name: 'project' }
					]		
		});
		

		var project_combo = new Ext.form.ComboBox({
			   name: 'id', 
			   hiddenName: 'id',
			   fieldLabel: _("Project"),
			   mode: 'remote',
			   store: store_projects_new,
			   valueField: 'id',
			   displayField:'project', 
			   editable: true,
			   forceSelection: true,
			   triggerAction: 'all',
			   allowBlank: false,
			   minChars: 1,
			   typeAhead: false
		});
		
		project_combo.on('select', function(){		
			project_id = project_combo.getValue();
			subproject_combo.clearValue();
			store_subprojects.baseParams = { project:project_id  };
			store_subprojects.load();
		});
		
		var store_subprojects = new Ext.data.JsonStore({ 
			root: 'data' ,
			remoteSort: true,
			totalProperty: 'totalCount',
			id: 'id',
			autoLoad: true, 
			baseParams: { },
			url: '/sqa/harvest_subprojects',
			fields: [ 
						{  name: 'id' },
						{  name: 'project' }
					]		
		});
		

		var subproject_combo = new Ext.form.ComboBox({
			   name: 'id', 
			   hiddenName: 'id',
			   fieldLabel: _('Subproject'),
			   mode: 'remote', 
			   store: store_subprojects,
			   valueField: 'id',
			   displayField:'project', 
			   editable: true,
			   forceSelection: true,
			   triggerAction: 'all',
			   allowBlank: false,
			   minChars: 1,
			   typeAhead: false
		});

		subproject_combo.on('select', function(){		
			project_id = subproject_combo.getValue();
			nature_combo.clearValue();
			store_nature.baseParams = { project:project_id  };
			store_nature.load();
		});


		var store_nature = new Ext.data.JsonStore({
			root: 'data' ,
			remoteSort: true,
			totalProperty: 'totalCount',
			id: 'id',
			autoLoad: true, 
			baseParams: { },
			url: '/sqa/subproject_natures',
			fields: [ 
						{  name: 'id' },
						{  name: 'nature' }
					]		
		});
		
		var nature_combo = new Ext.form.ComboBox({
			name: 'id',
			hiddenName: 'id',
			fieldLabel: _('Nature'),
			store: store_nature,
			displayField: 'nature',
			valueField: 'id',
			mode: 'remote',
			displayField:'nature', 
			editable: true,
			forceSelection: true,
			triggerAction: 'all',
			allowBlank: false,
			minChars: 1,
			typeAhead: false
		});

		var new_analysis_form = new Ext.FormPanel({
			frame: true,
            buttons: [
                {
                    text: _('Accept'),
                    type: 'submit',
                    handler: function(){
                        var bl = bl_combo.getValue();
                        var project = project_combo.getRawValue();
                        var subapp = nature_combo.getValue();
                        var nature = nature_combo.getRawValue();
                        subapp = subapp.replace('(' + nature + ')','');

						if( bl == undefined || bl == '' ) {
							alert (_("Select a baseline"));
						} else if( project == undefined || project == '' ) {
                        	alert (_("Select a project"));
						} else if( (subapp == undefined || subapp == '') && nature != 'ORACLE' && nature != 'FICHEROS' && nature != 'ECLIPSE' ) {
                        	alert (_("Select a subproject"));
						} else if( nature == undefined || nature == '' ) {
                        	alert (_("Select a nature"));
						} else {
							//alert("Estoy en el else");
	                        win.close();
	            			myMask.show();
							gNature = nature;
							gProject = project;
							if (nature != 'ORACLE' && nature != 'FICHEROS' && nature != 'ECLIPSE') {
								gSubapp = subapp;
							} else {
								gSubapp = project;
							}
							gBl = bl;
							projects_check();
						}
                    }
                },
                {
                    text: _('Cancel'),
                    handler: function(){ win.close(); }
                }
            ],
			items: [ bl_combo, project_combo, subproject_combo, nature_combo ]
		});
		var win = new Ext.Window({
			layout: 'fit', 
			autoScroll: true,
			title: _("Select a project"),
			height: 200, width: 300, 
			items: [ new_analysis_form ]
		});
		win.show();
	};
	
	
	
	var projects_check = function() {
			
			var store_projects = new Ext.data.JsonStore({ 
				root: 'data' ,
				remoteSort: true,
				totalProperty: 'totalCount',
				id: 'id',
				autoLoad: false, 
				baseParams: { all: true, bl: gBl },
				url: '/sqa/harvest_projects',
				fields: [ 
							{  name: 'id' },
							{  name: 'project' }
						]		
			});
			store_projects.load( { params: {nature: gNature, project: gProject, subapp: gSubapp, bl: gBl } });	

			var aStore = new Ext.data.SimpleStore({ 
				fields: [ 
							'id',
							'project'
						]
			});
			
			store_projects.on('load', function(ds, records){
				cnt = store_projects.getCount();
				//alert(store_projects.getCount());
				aStore.add(records);
				if( cnt < 1 ) {
					alert(_("There are no projects for that application"));
				}
				else if( cnt == 1 ) {
					var miProject;
					store_projects.each( function(record) { miProject=record.data.project; });
					//alert(miProject);
					request_analysis( miProject );
				}
				else {
					var rel_combo = new Ext.form.ComboBox({
						   name: 'id', 
						   hiddenName: 'id',
						   fieldLabel: _("Projects"),
						   mode: 'local', 
						   store: aStore,
						   valueField: 'project',
						   displayField:'project', 
//						   editable: false,
						   forceSelection: false,
						   triggerAction: 'all',
						   allowBlank: false,
						   width: 300
					});

					var rel_form = new Ext.FormPanel({
						frame: true,
			            buttons: [
			                {
			                    text: _('Select project'),
			                    type: 'submit',
			                    handler: function(){
			                        var project_name = rel_combo.getValue();
									if( project_name == undefined || project_name == '' ) {
										return;
									}
									//alert( project_name );
									win.close();
									request_analysis( project_name );
			                    }
			                },
			                {
			                    text: _('Cancel'),
			                    handler: function(){ win.close(); }
			                }
			            ],
						items: [ rel_combo ]
					});
					var win = new Ext.Window({
						layout: 'fit', 
						autoScroll: true,
						title: _("Select project to analyze") + " (" + _(gBl) + ")",
						height: 150, width: 450, 
						items: [ rel_form ]
					});
					win.show();
				}
				myMask.hide();
			});
	};	
	//return grid;
	var root = new Ext.tree.TreeNode();
    var tSQA = new Ext.tree.TreeNode({text:_('SCM-SQA'), draggable : false, expanded:true, expandable:true, leaf:false, icon: '/static/images/silk/rosette.png' });
    root.appendChild( tSQA );
    
% if ( $action_sqa_config ) {
    var tConfig = new Ext.tree.TreeNode({text:_('Config'), id: 'config', draggable : false, expanded:true, expandable:true, leaf:false, icon: '/static/images/silk/cog.png' });
    root.appendChild( tConfig );
    var tConfigProject = new Ext.tree.TreeNode({text:_('Project'), id: 'config.project', draggable : false, expandable:false, leaf:true, icon: '/static/images/silk/world.png' });
    tConfig.appendChild( tConfigProject );
    var tConfigSubproject = new Ext.tree.TreeNode({text:_('Subproject'), id: 'config.subproject', draggable : false, expandable:false, leaf:true, icon: '/static/images/scm/project.gif' });
    tConfig.appendChild( tConfigSubproject );
    var tConfigNature = new Ext.tree.TreeNode({text:_('Project/Nature'), id: 'config.nature', draggable : false, expandable:false, leaf:true, icon: '/static/images/silk/rainbow.png' });
    tConfig.appendChild( tConfigNature );
    var tConfigSubprojectNature = new Ext.tree.TreeNode({text:_('SubapNature'), id: 'config.subprojectnature', draggable : false, expandable:false, leaf:true, icon: '/static/images/scm/subapp.gif' });
    tConfig.appendChild( tConfigSubprojectNature );
%}


% if ( $action_view_general ) {
	var tGeneral = new Ext.tree.TreeNode({text:_('General'), id: 'general', draggable : false, expanded:true, expandable:true, leaf:false, icon: '/static/images/silk/folder_magnify.png' });
	tSQA.appendChild( tGeneral );
% if ( $action_sqa_project ) {
		var tCAM = new Ext.tree.TreeNode({text:_('Project'), id: 'cam', draggable : false, expandable:false, leaf:true, icon: '/static/images/silk/world.png' });
		tGeneral.appendChild( tCAM );
%}
% if ( $action_sqa_subproject ) {
		var tSubproject = new Ext.tree.TreeNode({text:_('Subproject'), id: 'subproject', draggable : false, expandable:false, leaf:true, icon: '/static/images/scm/project.gif' });
		tGeneral.appendChild( tSubproject );
%}
% if ( $action_sqa_subprojectnature ) {
		var tNature = new Ext.tree.TreeNode({text:_('SubapNature'), id: 'subprojectnature', draggable : false, expandable:false, leaf:true, icon: '/static/images/scm/subapp.gif' });
		tGeneral.appendChild( tNature );
%}
%}
	

% if ( $action_sqa_packages ) {
	var tPackages = new Ext.tree.TreeNode({text:_('Packages'), id: 'packages', draggable : false, expandable:false, leaf:true, icon: '/static/images/scm/packages.gif' });
    tSQA.appendChild( tPackages );
%}
    
    var tree = new Ext.tree.TreePanel({
        region: 'west',
        title: _("Navigator"),
        width: 195,
        expanded: true,
        animate : true,          
        collapsible: true,
        split: true,
        rootVisible: false,
        autoScroll : true,          
        containerScroll : true,          
        root : root,
        useArrows: true,
        dropConfig : { appendOnly : true }     
    });
    
    var columnas = grid.getColumnModel();
	var hidecol = function( cols, st ) {
		var columnas = grid.getColumnModel();
		for( var i=0; i < cols.length; i++) {
			var ix = columnas.getIndexById(cols[i]);
			//alert( ix );
			if( ix != -1 ) {
				columnas.setHidden( ix, st );
			}
		}
	};

    tree.on('click', function(n,e) {
		var node = n.id;
		//alert(node);
		
		
		myMask.show();

		store.removeAll();
		hide_all_buttons();
		
		if ( node == 'general' ){
			hidecol( ['icon','bl','subapp','nature','global','tsstart','tsend','qualification','result','has_html','test_errors','tests_coverture','trend'], false);
			hidecol( ['packages','links','has_html2','run_sqa_test','run_sqa_ante','run_sqa_prod','block_deployment_test','status','block_deployment_ante','block_deployment_prod'], true);


			gridType = '';
		} else if ( node == 'subprojectnature' ){
			hidecol( ['bl','subapp','nature','global','tsstart','tsend','qualification','result','has_html','tests_errors','tests_coverture','trend'], false);
			hidecol( ['icon','packages','links','has_html2','run_sqa_test','run_sqa_ante','run_sqa_prod','status','block_deployment_test','block_deployment_ante','block_deployment_prod'], true);

% if ( $action_new_analysis ) {
			button_new_analysis.show();
%}

			gridType = 'NAT';
			 
    	} else if ( node == 'cam' ) {
			hidecol( ['bl','global','tsstart','tsend','qualification','trend'], false);
			hidecol( ['icon','subapp','nature','status','packages','links','result','has_html','has_html2','tests_errors','tests_coverture','run_sqa_test','run_sqa_ante','run_sqa_prod','block_deployment_test','block_deployment_ante','block_deployment_prod'], true);
			
			gridType = 'CAM';
			
		} else if (node == 'subproject') {
			hidecol( ['bl','subapp','global','tsstart','tsend','qualification','trend'], false);
			hidecol( ['icon','nature','status','packages','links','has_html','result','has_html2','run_sqa_test','run_sqa_ante','run_sqa_prod','block_deployment_test','block_deployment_ante','block_deployment_prod','tests_errors','tests_coverture'], true);
			
			gridType = 'SUB';
			
		} else if (node == 'packages') {
			hidecol( ['bl','tsstart','tsend','packages','links','status'], false);
			hidecol( ['icon','nature','global','subapp','qualification','result','tests_errors','tests_coverture','trend','has_html','has_html2','run_sqa_test','run_sqa_ante','run_sqa_prod','block_deployment_test','block_deployment_ante','block_deployment_prod'], true);

			gridType = 'PKG';
		} else if ( node == 'config' ) {
			hidecol( ['icon','nature','subapp','run_sqa_test','run_sqa_ante','run_sqa_prod','block_deployment_test','block_deployment_ante','block_deployment_prod'], false);
			hidecol( ['global','bl','tsstart','tsend','packages','qualification','links','result','status','tests_errors','tests_coverture','trend','has_html','has_html2'], true);

% if ( $action_global_config ) {
			button_global_config.show();
%}
 
			gridType = 'CFG';
			
		} else if ( node == 'config.nature' ) {
			hidecol( ['nature','run_sqa_test','run_sqa_ante','run_sqa_prod','block_deployment_test','block_deployment_ante','block_deployment_prod'], false);
			hidecol( ['icon','global','bl','subapp','qualification','tsstart','tsend','packages','links','result','status','tests_errors','tests_coverture','trend','has_html','has_html2'], true);

% if ( $action_global_config ) {
			button_global_config.show();
%}
			gridType = 'CFGNAT';
			
		} else if ( node == 'config.project' ) {
			hidecol( ['run_sqa_test','run_sqa_ante','run_sqa_prod','block_deployment_test','block_deployment_ante','block_deployment_prod'], false);
			hidecol( ['icon','global','nature','subapp','bl','qualification','tsstart','tsend','packages','links','result','status','tests_errors','tests_coverture','trend','has_html','has_html2'], true);

% if ( $action_global_config ) {
			button_global_config.show();
%}
			gridType = 'CFGCAM';
			
		} else if ( node == 'config.subproject' ) {
			hidecol( ['subapp','run_sqa_test','run_sqa_ante','run_sqa_prod','block_deployment_test','block_deployment_ante','block_deployment_prod'], false);
			hidecol( ['icon','global','nature','bl','qualification','tsstart','tsend','packages','links','result','status','tests_errors','tests_coverture','trend','has_html','has_html2'], true);

% if ( $action_global_config ) {
			button_global_config.show();
%}
			gridType = 'CFGSUB';
			
		} else if ( node == 'config.subprojectnature' ) {
			hidecol( ['nature','subapp','run_sqa_test','run_sqa_ante','run_sqa_prod','block_deployment_test','block_deployment_ante','block_deployment_prod'], false);
			hidecol( ['icon','global','bl','qualification','tsstart','tsend','packages','links','result','status','tests_errors','tests_coverture','trend','has_html','has_html2'], true);

% if ( $action_global_config ) {
			button_global_config.show();
%}
			gridType = 'CFGSNA';
			
		}
		store.load({params:{start:0 , type: gridType, limit: ps }});
		//alert(gridType);
    });

   
    grid.on("activate", function() {
        if( first_load ) {
        	myMask.show();
        	alert("activate");
            first_load = false;
        }
    });
	// After page load

	store.load({params:{start:0 , type: gridType, limit: ps },callback: function(){
		myMask.hide();
	} }); 
    
    var panel = new Ext.Panel({
        title: _('SQA'),
        layout: 'border',
        items: [ tree, grid ]
    });
    
    var hide_all_buttons = function () {
% if ( $action_delete_analysis ) {
			button_delete_analysis.hide();
%}
% if ( $action_new_analysis ) {
			button_new_analysis.hide();
%}
% if ( $action_request_analysis ) {
			button_request_analysis.hide();
%}
% if ( $action_project_config ) {
			button_remove_config.hide();
			button_edit_config.hide();
%}
% if ( $action_global_config ) {
			button_global_config.hide();
%}
% if ( $action_request_recalc ) {
			button_request_recalc.hide();
%}    
    };
    return panel;
})();