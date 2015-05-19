<%perl>
    use Baseliner::Utils;
    my $id = _nowstamp;
</%perl>

(function(params){
    if(!params) params = {};
    params.typeApplication = '<% $c->stash->{typeApplication} %>';
    params.query_id = '<% $c->stash->{query_id} %>';
    params.id_project = '<% $c->stash->{id_project} %>';
    params.category_id = [ <% join',',_unique _array($c->stash->{category_id}) %> ];
    params.status_id = params.status_id ? params.status_id.split(',') 
        : '<% $c->stash->{status_id} %>' ? '<% $c->stash->{status_id} %>' : undefined;

    var report_data = Ext.util.JSON.decode('<% $c->stash->{report_data} %>');
    if( report_data ){
        Ext.apply(params, report_data);
    }
    return Cla.topic_grid(params);
})
