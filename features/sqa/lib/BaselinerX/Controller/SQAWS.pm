package BaselinerX::Controller::SQAWS;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
BEGIN {  extends 'Catalyst::Controller' }

# skip authentication for this controller:
sub begin : Private {
    my ($self,$c) = @_;
    $c->stash->{auth_skip} = 1;
    $c->forward('/begin');
}

sub job_approve : Path('/sqa/job_approve') {
    my ($self,$c)=@_;
    my $p = $c->request->params;
    my $project = $p->{project};
    my $subproject = $p->{subproject};
    my $nature = $p->{nature};
    my $bl = $p->{bl};
    
    _log "Getting approval status for bl => $bl, project => $project, subproject => $subproject, nature => $nature";
    
    my $approval = BaselinerX::Model::SQA->getProjectLastStatus( bl => $bl, project => $project, subproject => $subproject, nature => $nature ); 
    
    $c->stash->{json} = { go => $approval->{value}, link=>$approval->{link}, bl => $bl, project => $project, subproject => $subproject, nature => $nature };
    $c->forward('View::JSON');
}

sub job_config : Path('/sqa/job_config') {
    my ($self,$c)=@_;
    my $p = $c->request->params;
    my $project = $p->{project};
    my $subproject = $p->{subproject};
    my $nature = $p->{nature};
    my $bl = $p->{bl};
    my $value = $p->{value};
    
    _log "Getting project config for bl => $bl, project => $project, subproject => $subproject, nature => $nature, value=>$value";
    
    my $config_value = BaselinerX::Model::SQA->getProjectConfigAll( bl => $bl, project => $project, subproject => $subproject, nature => $nature, value=>$value );
    #my $config_value = BaselinerX::Model::SQA->getProjectConfigAll( project=>$project, bl=> $bl, nature=>'J2EE', subproject=>'aiamain', value=>'block_deployment' ); 
    
    
    _log "Config value: ".$config_value;
    
    _log _dump $p;
    $c->stash->{json} = { value => $config_value };
    
    _log _dump $c->stash->{json};
     
    $c->forward('View::JSON');
}

sub view_html : Path('/sqa/audit_report') {
    my ( $self, $c ) = @_;
    my $p = $c->request->params;
    my $id = $p->{id};
    my $row  = $c->model( 'Baseliner::BaliSqa' )->find( $id );
    my $data = _load $row->data if $row->data;
    my $html = $data->{html};

    $c->res->body( $html );
}

1;
