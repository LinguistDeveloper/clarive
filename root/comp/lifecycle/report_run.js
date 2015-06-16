(function(params) {

    var id_report = params.id_report;

    if ( id_report ) {
        Baseliner.message(_("Wait while retrieving fields list and format for report %1", params.report_name));
        Baseliner.ci_call( id_report, 'selected_fields', { username : '<% $c->username %>'}, function(res){
            params.fields = res;
            console.log(params);
            Baseliner.add_tabcomp( '/comp/topic/topic_grid.js', _(params.report_name), params );
            Baseliner.message(_("Fields retrieved.  Now wait while generating report %1", params.report_name));
        });
    }

})
