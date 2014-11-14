(function(report){
    if( !report ) report = {};
    var url = report.url || '/comp/topic/topic_grid.js';
    
    Baseliner.ci_call( 'report', 'report_meta', { id_report: report.id_report, id_report_rule: report.id_report_rule }, function(grid_params){
        if( !Ext.isObject(grid_params) ) {
            Baseliner.message( _('Report'), _('Invalid report meta for id %1', report.id_report ) );
            return;
        }
        grid_params = Ext.apply(Ext.apply({ 
            mini_mode: true,
            tab_icon: '/static/images/icons/topic.png'
        }, report), grid_params );
        // console.log( grid_params );
        
        Baseliner.add_tabcomp( url, _(report.report_name || report.id_report), grid_params );
    });
})
