(function(params) {

    var id_report = params.id_report;

    if ( id_report ) {
        Baseliner.ci_call( id_report, 'selected_fields', { username : '<% $c->username %>'}, function(res){
            params.fields = res;
            Baseliner.add_tabcomp( '/comp/topic/topic_grid.js', _(params.report_name), params );
        });
    }

})
