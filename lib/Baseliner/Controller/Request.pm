package Baseliner::Controller::Request;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::Baseline;
use Try::Tiny;
use JSON::XS;

BEGIN {  extends 'Catalyst::Controller' }

register 'action.request.manage' => { name => 'Manage Requests' };

register 'action.job.view_job_approvals' => {name => 'Can view job approvals'};

register 'menu.job.request' => {label    => 'Approvals',
                                url_comp => '/request/main',
                                title    => 'Approvals',
                                icon     => '/static/images/drop-yes.gif',
                              # actions  => ['action.approve.item', 'action.approve.job', 'action.approve.package'],
                                action   => 'action.job.view_job_approvals'};

sub reject : Local : Args(1) {
    my ( $self, $c, $key ) = @_;
    $c->flash->{current_action} = 'reject';
    $self->init_view( $c, $key );
}

sub approve : Local : Args(1) {
    my ( $self, $c, $key ) = @_;
    $c->flash->{current_action} = 'approve';
    $self->init_view( $c, $key );
}

sub init_view {
    my ( $self, $c, $key ) = @_;
    my $request =  $c->model('Request')->get_by_key($key);
    $c->flash->{current_request} = $request;
    $c->stash->{tab_list} = [ {url=>'/comp/request_grid.mas'}];
    
    my $config = $c->registry->get( 'config.request' );	    
    $c->flash->{metadata_request} = $config->metadata; ## lo utilizará el config_form.mas	
    
    $c->flash->{from_email} = 1;	
    $c->forward('/index');
}

sub approve_request : Local {
    my ( $self, $c, $key ) = @_;
    my $p = $c->request->parameters;		
    try {
        _log "Starting approval of request " . $p->{key};
        my $username = $c->username;
        $c->model('Request')->approve_by_key( ns=>$p->{ns}, bl=>$p->{bl}, key=> $p->{key}, id_wiki=>$p->{id_wiki}, wiki_text=>$p->{text}, username=>$username );
        _log "Finished approval of request " . $p->{key};
        $c->stash->{json} = { success => \1 };
    } catch {
        my $err = shift;
        $err =~ s/\\/\\\\/g;
        $err =~ s/\n//g;
        $err =~ s/\r//g;
        $c->stash->{json} = { success => \0, errors=>{ reason => $err } };
    };	
    $c->forward('View::JSON');
}

sub reject_request : Local {
    my ( $self, $c, $key ) = @_;
    my $p = $c->request->parameters;		
    try {		
        my $username = $c->username;
        $c->model('Request')->reject_by_key( ns=>$p->{ns}, bl=>$p->{bl}, key=> $p->{key}, id_wiki=>$p->{id_wiki}, wiki_text=>$p->{text}, username=>$username );
        $c->res->body( '{"success":true}' );
    } catch {
        my $err = shift;
        $err =~ s/\\/\\\\/g;
        $err =~ s/\n//g;
        $err =~ s/\r//g;
        $c->res->body( '{"success":false,"errors":{"reason":"' . $err .'"}}');
    };	
}

sub cancel : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;		
        
    try {		
        my $id = $p->{id};
        my $req = $c->model('Baseliner::BaliRequest')->find($id);
        die _loc('Request ID %1 not found', $id) . "\n" unless ref $req;
        $req->status('cancelled');
        $req->update;
        $c->stash->{json} = {
            success => \1,
            msg => _loc('Request cancelled')
        };
    } catch {
        my $err = shift;
        chop $err;
        $c->stash->{json} = {
            success => \0,
            msg => _loc('Error during request cancel: %1', $err )
        };
    };
    $c->forward('View::JSON');
}

sub rerequest : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;		
    try {		
        my $id = $p->{id};
        $c->model('Request')->rerequest( $id );
        $c->stash->{json} = {
            success => \1,
            msg => _loc('Request Sent')
        };
    } catch {
        my $err = shift;
        chop $err;
        $c->stash->{json} = {
            success => \0,
            msg => _loc('Error during request: %1', $err )
        };
    };
    $c->forward('View::JSON');
}

sub json_bool { # turn true / false into 1 and 0
    !defined $_[0] and return 0;
    $_[0] eq 'true' and return 1;
    return 0;
}

sub list_json : Path('/request/list_json') {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $filter, $cnt ) = @{$p}{qw/start limit query dir sort filter/};
    $start||=0;
    $limit||=50;
    $sort ||='id';
    $dir  ||='desc';
    my $username = $c->username;	

    $p->{manage} = json_bool( $p->{manage} );
    $p->{all} = json_bool( $p->{all} );
    $filter = decode_json( $filter ) if $filter;

        # get requests from the Request Model
        my $list = $c->model('Request')->list(
                pending =>$p->{all} ? 0 : 1,
                action  =>$p->{manage} ? '' : [ $c->model('Permissions')->list( username=>$username, ns=>"any" ) ],
                project =>$p->{manage} ? '' : [ $c->model('Permissions')->user_projects( username=>$username ) ],
                start   =>$start, limit=>999999,
                query   =>'',
                sort    =>$sort,
                dir     => $dir,
                filter  =>$filter,
        );
        my $namespaces = $c->model('Namespaces');
        my @requests;
        my $i=1;
        foreach my $request ( _array $list->{data} ) {
                next if $i <= $start;
                last if $i >= $limit;
                my $req = $c->model('Request')->append_data( $request, model_namespaces=>$namespaces );
 next unless ref $req;
                next if( $p->{query} && !query_array($p->{query},$req->{ns_name},$req->{id},$req->{bl},$req->{name},$req->{requested_on},$req->{requested_by},$req->{finished_on},$req->{finished_by}) );

                $i+=1;
                push @requests, $req;
        }

    $c->stash->{json} = { 
        totalCount=> $list->{total},
        data => \@requests
     };	
    $c->forward('View::JSON');
}

#Solucion temporal para los namespaces
sub get_ns{
    my ($self,$ns) = @_;
    my @search_replace = (
        {search=>'\/',replace=>''},
        {search=>'application',replace=>'('._loc('Application').')'},
        {search=>'harvest.subapplication',replace=>'('._loc('Subapplication').')'},
        {search=>'harvest.package',replace=>'('._loc('Harvest Package').')'},
        {search=>'release',replace=>'('._loc('Release').')'},
    );
    
    my $new_ns = $ns;
    foreach my $sr (@search_replace){
        my $search = $sr->{search};
        my $replace = $sr->{replace};
        if($new_ns =~ m/^$search/){    
              $new_ns =~ s/^$search//g;
               $new_ns .= " $replace";
        }
    }
    return $new_ns;	
}

sub main : Local {
    my ( $self, $c ) = @_;
    $c->stash->{manage} = \1 if $c->model('Permissions')->user_has_action( username=>$c->username, action=>'action.request.manage', bl=>'*' ) ;
    $c->stash->{template} = '/comp/request_grid.mas';
    my $config = $c->registry->get( 'config.request' );	    
    $c->stash->{metadata_request} = $config->metadata; ## lo utilizará el config_form.mas	
}

sub grid : Local {
    my ( $self, $c ) = @_;
    $c->forward('/request/main');
}

1;
