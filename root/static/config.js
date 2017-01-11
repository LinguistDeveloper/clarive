require.config({
	paths: {
		jquery: 'jquery/jquery-1.7.1.min',
		jqueryUI: 'jquery/jquery-ui-1.8.17.custom.min',
		bootstrap: 'bootstrap/js/bootstrap',
		extjs: 'ext/ext-all-nochart' + options.debug,
		'ext-base': 'ext/adapter/ext/ext-base' + options.debug,
		'ux-all': 'ext/examples/ux/ux-all' + options.debug,
		global: '/site/globals',
		common: '/site/common',
		tmpl: '/site/tmpl',
		views: '/lib/views',
		gritter: '/static/gritter/js/jquery.gritter.min',
		tabfu: '/site/tabfu',
		help: '/site/help',
		runner: '/site/runner',
		panelResizer: '/site/panelresizer',
		dndTabPanel: '/site/dnd_tabpanel',
		moment: '/static/momentjs/moment-with-locales.min',
		momentTimeZones: '/static/momentjs/moment-timezones.min',
		datePickerPlus: '/static/datepickerplus/ext.ux.datepickerplus-min',
		datePickerPlusLang: '/static/datepickerplus/ext.ux.datepickerplus-lang-' + options.language,
		dataTablesJQuery: '/static/datatables/js/jquery.dataTables.min',
		dataTablesBootstrap: '/static/datatables/js/dataTables.bootstrap',
		excanvas: '/static/flot/excanvas.min',
		jqueryFlot: '/static/flot/jquery.flot',
		jqueryFlotPie: '/static/flot/jquery.flot.pie',
		jqueryFlotOrderBars: '/static/flot/jquery.flot.orderBars',
		Flot: '/static/flot/flot',
		jqueryinjectCSS: '/static/jquery/jquery.injectCSS',
		jit: '/static/jit/jit',
		markDownEditor: '/static/pagedown/Markdown.Editor',
		markDownConverter: '/static/pagedown/Markdown.Converter',
		markDownSanitizar: '/static/pagedown/Markdown.Sanitizer',
		jqueryClEditor: '/static/cleditor/jquery.cleditor.min',
		highlight: '/static/highlightjs/highlight.pack',
		ace: '/static/ace/ace',
		aceLanguage: '/static/ace/ext-language_tools',
		objectDiff: '/static/objectDiff/objectDiff',
		jsYAML: '/static/js-yaml/js-yaml',
		codeMirror: '/static/codemirror/lib/codemirror',
		codeMirrorFormatting: '/static/codemirror/lib/util/formatting',
		codeMirrorHint: '/static/codemirror/lib/util/simple-hint',
		codeMirrorPerl: '/static/codemirror/mode/perl/perl',
		codeMirrorJS: '/static/codemirror/mode/javascript/javascript',
		codeMirrorXML: '/static/codemirror/mode/xml/xml',
		codeMirrorPLSQL: '/static/codemirror/mode/plsql/plsql',
		codeMirrorCSS: '/static/codemirror/mode/css/css',
		codeMirrorMarkdown: '/static/codemirror/mode/markdown/markdown',
		aceEditor: '/site/aceeditor',
		editor: '/site/editors',
		graph: '/site/graph',
		explorer: '/site/explorer',
		portal: '/site/portal/Portal',
		portalColumn: '/site/portal/PortalColumn',
		porlet: '/site/portal/Portlet',
		portalUtil: '/site/portal/PortalUtil',
		fileuploader: '/static/valums/fileuploader',
		superbox: '/static/superbox/superbox',
		latinise: '/static/latinise',
		model: '/site/model',
		kanban: '/site/kanban',
		calendar: '/site/calendar',
		dashboard: '/site/dashboard',
		topicLib: '/comp/topic/topic_lib',
		topicGrid: '/comp/topic/topic_lib_grid',
		fullcalendar: '/static/fullcalendar/fullcalendar.min',
		numberFormat154: '/static/NumberFormat154',
		treegrid: '/static/gridtree/treegrid',
		spinner: '/static/ex.ux.form.spinner/Spinner',
		spinnerStrategy: '/static/ex.ux.form.spinner/SpinnerStrategy',
		prefs: '/site/prefs',
		d3: '/static/d3/d3.min',
		c3: '/static/c3/c3.min',
		calendar: '/static/model/calendar'
	},
	shim: {
		bootstrap: {
			deps: ['jquery'],
			exports: 'bootstrap'
		},
		jqueryUI: {
			deps: ['jquery'],
			exports: 'jqueryUI'
		},
		extjs: {
			deps: ['ext-base'],
			exports: 'Ext'
		},
		global: {
			deps: ['/i18n/js'],
			exports: 'global'
		},
		common: {
			deps: ['gritter', 'ux-all'],
			exports: 'common'
		},
		tabfu: {
			deps: ['common', 'c3', 'd3'],
			exports: 'tabfu'
		},
		momentTimeZones: {
			deps: ['moment'],
			exports: 'momentTimeZones'
		},
		markDownEditor: {
			deps: ['markDownConverter', 'markDownSanitizar'],
			exports: 'markDownEditor'
		},
		markDownSanitizar: {
			deps: ['markDownConverter'],
			exports: 'markDownSanitizar'
		},
		aceLanguage: {
			deps: ['ace'],
			exports: 'aceLanguage'
		},
		jqueryFlotPie: {
			deps: ['jqueryFlot'],
			exports: 'jqueryFlotPie'
		},
		jqueryFlotOrderBars: {
			deps: ['jqueryFlot'],
			exports: 'jqueryFlotOrderBars'
		},
		editor: {
			deps: ['jqueryFlot'],
			exports: 'editor'
		},
		portal: {
			deps: ['tabfu'],
			exports: 'Portal'
		},
		portalUtil: {
			deps: ['portal'],
			exports: 'portalUtil'
		},
		explorer: {
			deps: ['tabfu'],
			exports: 'explorer'
		},
		codeMirrorFormatting: {
			deps: ['codeMirror'],
			exports: 'codeMirrorFormatting'
		},
		codeMirrorHint: {
			deps: ['codeMirror'],
			exports: 'codeMirrorHint'
		},
		codeMirrorPerl: {
			deps: ['codeMirror'],
			exports: 'codeMirrorPerl'
		},
		codeMirrorJS: {
			deps: ['codeMirror'],
			exports: 'codeMirrorJS'
		},
		codeMirrorXML: {
			deps: ['codeMirror'],
			exports: 'codeMirrorXML'
		},
		codeMirrorPLSQL: {
			deps: ['codeMirror'],
			exports: 'codeMirrorPLSQL'
		},
		codeMirrorCSS: {
			deps: ['codeMirror'],
			exports: 'codeMirrorCSS'
		},
		codeMirrorMarkdown: {
			deps: ['codeMirror'],
			exports: 'codeMirrorMarkdown'
		},
		dataTablesBootstrap: {
			deps: ['dataTablesJQuery'],
			exports: 'dataTablesBootstrap'
		},
		model: {
			deps: ['tabfu', 'superbox'],
			exports: 'model'
		},
		kanban: {
			deps: ['portal'],
			exports: 'kanban'
		},
		topicLib: {
			deps: ['model'],
			exports: 'topicLib'
		},
		spinnerStrategy: {
			deps: ['spinner'],
			exports: 'spinnerStrategy'
		},
		views: {
			deps: ['superbox'],
			exports: 'views'
		}
	}
});

var jsLibMain = [
	'extjs',
	'jqueryUI',
	'global'
];

define(jsLibMain, function() {
	Ext.Ajax.timeout = 60000;

	Ext.QuickTips = function(){
	    var tip,
	        disabled = false;
	        
	    return {
	        
	        init : function(autoRender){
	            if(!tip){
	                tip = new Ext.QuickTip({
	                    elements:'header,body', 
	                    disabled: disabled
	                });

	                if(autoRender !== false){
	                    tip.render(Ext.getBody());
	                }
	            }
	        },
	        
	        
	        ddDisable : function(){
	            
	            if(tip && !disabled){
	                tip.disable();
	            }    
	        },
	        
	        
	        ddEnable : function(){
	            
	            if(tip && !disabled){
	                tip.enable();
	            }
	        },

	        
	        enable : function(){
	            if(tip){
	                tip.enable();
	            }
	            disabled = false;
	        },

	        
	        disable : function(){
	            if(tip){
	                tip.disable();
	            }
	            disabled = true;
	        },

	        
	        isEnabled : function(){
	            return tip !== undefined && !tip.disabled;
	        },

	        
	        getQuickTip : function(){
	            return tip;
	        },

	        
	        register : function(){
	            tip.register.apply(tip, arguments);
	        },

	        
	        unregister : function(){
	            tip.unregister.apply(tip, arguments);
	        },

	        
	        tips : function(){
	            tip.register.apply(tip, arguments);
	        }
	    };
	}();
	
});