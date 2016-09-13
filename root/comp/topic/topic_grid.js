<%perl>
    use Baseliner::Utils;
    my $id = _nowstamp;
</%perl>

(function(params){
    if(!params) params = {};
    params.typeApplication = '<% $c->stash->{typeApplication} %>';
    params.query_id = '<% $c->stash->{query_id} %>';
    params.id_project = '<% $c->stash->{id_project} %>';
    params.id_report = '<% $c->stash->{id_report} %>';
    params.category_id = [ <% join',',_unique _array($c->stash->{category_id}) %> ];
    params.status_id = params.status_id ? params.status_id.split(',') : '<% $c->stash->{status_id} %>' ? '<% $c->stash->{status_id} %>' : undefined;
    var no_report_category = '<% $c->stash->{no_report_category} %>';

    var data_fields = Ext.util.JSON.decode('<% $c->stash->{data_fields} %>');
    if (data_fields) {
        Ext.apply(params, data_fields);
    }
    else {
        if (no_report_category) params.fields = '';
    }
    return Cla.topic_grid(params);
})
