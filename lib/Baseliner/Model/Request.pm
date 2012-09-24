package Baseliner::Model::Request;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
no Moose;
use Baseliner::Utils;
use Digest::MD5;
use Try::Tiny;

with 'Baseliner::Role::Service';

sub generate_key {
    return Digest::MD5::md5_hex( _now . rand() . $$ );
}

register 'action.approve.item' => {
    name => 'Approve Items',
};

register 'config.request' => {
          name=> _loc('Approve'),
          metadata=> [
                      { id=>'ns', label=>_loc('Namespace'),  type=>'hidden'},
                      { id=>'bl', label=>_loc('Baseline'),  type=>'hidden'},
                      { id=>'id', label=>_loc('Id'),  type=>'hidden'},
                      { id=>'key', label=>_loc('Key'),  type=>'hidden'},
                      { id=>'id_wiki', label=>_loc('WikiId'),  type=>'hidden'},
                      { id=>'text_wiki', label=>'Comentarios del solicitante', type=>'textarea', extjs =>{width=>'250',height=>'70', readOnly=>\1} },                      
                      { id=>'text', label=>'Comentarios del aprobador', type=>'textarea', extjs =>{width=>'250',height=>'70'} },                      
          ]
};

register 'service.request.save_data' => {
    name => 'Migrate ns data from request into data field',
    handler=>sub{
        my $rs = Baseliner->model('Baseliner::BaliRequest')->search;
        my $cnt = 1;
        my $len = $rs->count;
        while( my $r = $rs->next ) {
            _log sprintf "Started on request %s (%d/%d)", $r->id, $cnt++, $len;
            $r->save_data;
            _log sprintf "Finished request %s", $r->id;
        }
    }
};

=head2 request

    $m->request(
        name   => 'Approval of job N.DESA1029210',  # this will become the subject
        action => $action,   # look for people who can approve this
        data   => {  reason=>'promoting to prod' },  # send it to the template
        template => '/email/another.html',
        ns     => $item, 
        bl     => $bl, 
    );

=cut
sub request {
    my ($self, %p ) = @_;

    $p{action} || die 'Missing parameter action';
    $p{ns} || die 'Missing parameter ns';
    $p{bl} ||= '*';

    my $username = $p{requested_by} || $p{username} || 'internal';

    # look for existing requests
    my $list = $self->list( ns=>$p{ns}, action=>$p{action} );
    my @pending = _array( $list->{data} );

    # cancel pending requests, if any...
    foreach my $req_data( @pending ) {
        my $r = Baseliner->model('Baseliner::BaliRequest')->find( $req_data->{id} );	
        next unless ref $r; 
        $r->status('cancelled');
        $r->finished_by($username);
        $r->finished_on(_now_ora);
        $r->update;
    }

    # freeze data
    my $data;
    if( $p{data} ) {
        try {
            $data = _dump( $p{data} );
        } catch {
            _log "Error trying to freeze request data: " . shift;
        };
    }

    #Para incluir las observaciones y asociarlas al wiki del request
    my $id_wiki = undef;	
    if($p{comments_job}){
        $p{comments_job}=~s{<p>}{\n}g;
        $p{comments_job}=~s{</p>}{}g;
        my $rwiki = Baseliner->model('Baseliner::BaliWiki')->create({text=>$p{comments_job}, username=>$username, modified_on=> _now});				
        $rwiki->update;
        $id_wiki = $rwiki->id;
    }
    
    # request new
    my $key = $self->generate_key;
    my $request = Baseliner->model('Baseliner::BaliRequest')->create(
        {
            ns           => $p{ns},
            action       => $p{action},
            requested_on => _now_ora,
            requested_by => $username, 
            key          => $key,
            data         => $data,
            callback     => $p{callback},
            id_wiki		 => $id_wiki,
            item   		 => $p{item},   # item overwrite
        }
    );
    
    my $name = $p{name} || _loc('Request %1', _now . ':' . $request->id );
    $request->name( $name );
    $request->id_job( $p{id_job} ) if $p{id_job};
    $request->update;
   
    # update relationship
    Baseliner->model('Namespaces')->store_relationship( $p{ns} );

    try {
        $self->notify_request( $request, %p );
    } catch {
        _log "Error notifying request: " . shift;
    };

    return $request;
}

=head2 list

report rows that have a pending request

=cut
sub list {
    my ($self, %p ) = @_;

    my $where = {};
    length $p{query} and $where = query_sql_build( query=>$p{query},
        fields=>[ qw/id bl name requested_on requested_by finished_on finished_by data/ ] );
    if( ref $p{filter} ) {
        my $status = [ grep { $p{filter}->{$_} } keys %{ $p{filter} } ]; 
        $where->{status} = $status;
    } else {
        $p{pending} and $where->{status} = [ 'pending', 'notified' ];
    }
    $where->{ns} = $p{ns} if exists $p{ns};
    $p{username} and $where->{username} = $p{username};
    #_log Dumper $p{action} ;
    $p{action} and $where->{action} = $p{action};
    my $from = {};
    $p{dir} ||= 'asc';
    $from->{order_by} = $p{sort} ? { "-$p{dir}" => "me.$p{sort}" } : { -desc => "me.id" };
    #$from->{order_by} = 'me.' . $from->{order_by} unless $from->{order_by} =~ /^me/;
    if( exists($p{start}) && exists($p{limit}) ) {
        my $page = to_pages( start=>$p{start}, limit=>$p{limit} );
        $from->{page} = $page;
        $from->{rows} = $p{limit};
    }
    if( $p{project} ) {
        my @user_apps = _array $p{project};
        unless( grep { $_ eq '/' } @user_apps ) { # if it has a global group permission, ignore
            $where->{'id_project.ns'} = \@user_apps;
            $from->{'join'} = { 'projects' => 'id_project' };
        }
    }
    #$from->{select} = [qw//];
    #$from->{prefetch} = [ 'bali_request' ];
    # XXX this is not really needed, clob loading is due to slow drivers (instantclient?)
    $from->{select} = [
        map { s/ //g; $_ } 
            split /,/,
            'id, ns, bl, requested_on, finished_on, status, finished_by, requested_by, action, id_parent, key, name, type, item, id_wiki, id_job, callback, id_message'
    ] if $p{no_data};
    my $rs = Baseliner->model('Baseliner::BaliRequest')->search($where, $from);
    rs_hashref( $rs ) unless $p{row};
    return $rs if $p{rs};
    my @requests = $rs->all;

    return @requests if wantarray;
    my $cnt = scalar @requests;
    my $total = $rs->is_paged ? $rs->pager->total_entries : $cnt;
    return { count=>$cnt, total=>$total, data=>\@requests };
}

=head2 rerequest

Request again

=cut
sub rerequest {
    my ($self, $id ) = @_;
    my $req = Baseliner->model('Baseliner::BaliRequest')->find($id);
    die _loc("Request ID %1 not found", $id ) unless ref $req;
    # clone
    my $new_req = $req->copy({ status=>'pending' });
    $new_req->update;	

    # resend notifications
    $self->notify_request( $new_req );
    return $new_req;
}

sub is_status {
    my ($self, %p ) = @_;
    _check_parameters( \%p, qw/ns status/ ); 
    my $status = $self->last_status;
    return defined $status ? $status eq $p{status} : undef;
}

sub top {
    my ($self, %p ) = @_;
    return Baseliner->model('Baseliner::BaliRequest')->search({ ns=>$p{ns} }, { order_by=> { -desc =>'me.id' } } )->first;
}

sub last_status {
    my ($self, %p ) = @_;
    my $row = $self->top( %p );
    return ref $row ? $row->status : undef;
}

sub fill_items{
    my ($self, @requests ) = @_;
    foreach my $request (@requests){
        $request->{items} = join("," , $self->items_for_request($request));
    }
}

sub items_for_request{
    my ($self, $request ) = @_;
    use Baseliner::Core::DBI;
    my $db = Baseliner::Core::DBI->new({ model=>'Baseliner' });    
    my @items = ($request->{id_job}) ? $db->array(qq{
            SELECT item
            FROM BALI_JOB_ITEMS  
            WHERE ID_JOB = $request->{id_job}            
    }):undef;	
    
    return @items;
}

# make sure all requests have a project relationship
sub enforce_pending {
    for my $req ( Baseliner->model('Baseliner::BaliRequest')->search({ status=>'pending' })->all ) {
        Baseliner->model('Namespaces')->store_relationship( $req->ns );
    }
}

sub notify_request {
    my ($self, $request, %p ) = @_;
    use Encode;
    
    _throw 'Missing request object' unless ref $request;

    my $action = $p{action} || $request->action;
    my $ns = $p{ns} || $request->ns;
    my $bl = $p{bl} || $request->bl;
    my $key = $request->key || _throw 'Missing approval key';
    my @users;

    # find parents
    my $request_item = Baseliner->model('Namespaces')->get( $request->ns );
    my @items = _array $request->ns; # for now, just one item per request
    my @parents;
    for my $item ( @items ) {
        my $obj = Baseliner->model('Namespaces')->get( $item );
        try {
            push @parents, $obj->parents; 
        } catch {
           #dont care 
        };
    }
    push @items, @parents;
    for my $item ( @items ) {
        push @users, Baseliner->model('Permissions')->list(
            role_filter => $p{role_filter},
            action      => $action,
            ns          => $item,
            bl          => $bl,
        );
    }
    @users = grep { $_ ne 'root' } _unique @users;

    _debug "Notifying users: " . join ',',@users;

    _throw _loc(
        "No users found for action %1 and namespace(s) %2",
        $action . ( $p{role_filter} ? " (Role $p{role_filter})" : "" ),
        join( ", ", @items )
    ) unless @users;

    my %vars = exists $p{vars} ? %{ $p{vars} || {} } :  %p;

    my $data = _load( $request->data )
        if $request->data;

    if( ref $data eq 'HASH' ) {
        foreach my $k ( keys %$data ) {
            $vars{$k} = $data->{$k};
        }
    }

    # Get user info
    my $u = Baseliner->model('Users')->get( $request->requested_by );
    my $realname = $u->{realname} || $request->requested_by ;

    my @users_with_realname = map { 
        my $ud = Baseliner->model('Users')->get( $_ );
        my $rn = $ud->{realname};
        $rn = encode("iso-8859-15", $rn);
        $rn =~ s{Ã\?}{Ñ}g;
        $rn =~ s{Ã±}{ñ}g;
        utf8::downgrade($rn);
        $rn ? "$_ ($rn)" : $_;
        } @users;
    
    # Queue email 
    my $items = join ' ', @items;
    my $msg = Baseliner->model('Messaging')->notify(
        to      => { users => [ _unique(@users) ] },
        subject => $request->name,
        sender  => $request->requested_by,
        carrier => 'email',
        template => $p{template} || 'email/approval.html',
        template_engine => $p{template_engine} || 'mason',
        vars => {
            subject      => $request->name,
            items        => [ $p{items} || $request_item->ns_name || $ns ],
            from         => _loc('Approval Request'),
            reason       => $request->data_hash->{reason},
            requested_by => $request->requested_by,
            requested_to => [ _unique(@users_with_realname) ] ,
            realname     => $realname,
            url_approve  => _notify_address . "/request/approve/$key",
            url_reject   => _notify_address . "/request/reject/$key",
            %vars,
        }
    );

    # save the message id in the request record
    $request->id_message( $msg->id ) if ref $msg;
    $request->update;
}

sub status_by_key {
    my ( $self, %p ) = @_;

    # order by id desc just in the remote case there is duplicate 'keys'
    my $rs = Baseliner->model('Baseliner::BaliRequest')->search({ key => $p{key} }, { order_by=>{ -desc => 'me.id' } });
    my $request = $rs->first;

    _throw _loc('Could not find a request for %1', $p{key} ) unless ref $request;
    _throw _loc( 'Request %1 has been %2', $request->id, _loc($request->status) )
      if ( $request->status ne 'pending' );

    my $rwiki = Baseliner->model('Baseliner::BaliWiki')->create({
            text        => $p{wiki_text},
            username    => $p{username},
            modified_on => _now,
            id_wiki     => $p{id_wiki}
    });

    $rwiki->update;

    $request->status( $p{status} );
    $request->id_wiki($rwiki->id);
    $request->finished_on( _now );
    $request->finished_by( $p{username} );
    $request->update;		
        
    my $request_item = Baseliner->model('Namespaces')->get( $request->ns );
    my $itemname = $request_item->ns_name || $request->ns;
    my $status = ucfirst _loc( $p{status} );

    # Get user info
    my $u = Baseliner->model('Users')->get( $p{username} );
    my $realname = $u->{realname} || $p{username};

    my $msg = Baseliner->model('Messaging')->notify(
        to       => { users => [ $request->requested_by ] },
        subject  => "$status $itemname",
        sender   => $p{username},
        carrier  => 'email',
        template => 'email/action.html',
        template_engine => $p{template_engine} || 'mason',
        vars     => {
            observaciones => $p{wiki_text},
            items         => $itemname,
            reason        => $request->data_hash->{reason},
            requested_by  => $request->requested_by,
            realname      => $realname,
            status        => $status,
            subject       => "Estado de la aprobación del item $itemname: <b>$status</b>",
            template      => "/email/action.html",
            username      => $p{username},
            to            => [ $request->requested_by ],
        }
    );

    # callback
    try {
        $self->callback( service=>$request->callback, request=>$request );
    } catch {
    };
}

sub callback {
    my ( $self, %p ) = @_;
    my $service = $p{service};
    my $request = $p{request};
    my $data;
    $data = _load( $request->data )
        if $request->data;
    Baseliner->model('Services')->launch( $service, data=>$data, request=>$request, quiet=>1);
}

sub cancel_for_job {
    my ( $self, %p ) = @_;
    my $id = $p{id_job} or _throw 'Missing job id';
    my $reqs = Baseliner->model('Baseliner::BaliRequest')->search({ id_job=>$id });
    while( my $req = $reqs->next ) {
        #TODO create a request log and write to it: request cancelled due to job cancellation
        $req->status('cancelled');
        $req->update;
    }
}

sub approve_by_key {
    my ( $self, %p ) = @_;
    $self->status_by_key( ns=>$p{ns}, bl=>$p{bl}, key=>$p{key}, username=>$p{username}, id_wiki=>$p{id_wiki}, wiki_text=>$p{wiki_text}, status=>'approved' );
}

sub reject_by_key {
    my ( $self, %p ) = @_;
    $self->status_by_key( ns=>$p{ns}, bl=>$p{bl}, key=>$p{key}, username=>$p{username}, id_wiki=>$p{id_wiki}, wiki_text=>$p{wiki_text}, status=>'rejected' );
}

sub get_by_key {
    my ($self, $key ) = @_;
    my $rs = Baseliner->model('Baseliner::BaliRequest')->search({key=>$key})->first;
    my %row = $rs->get_columns;
    my $request = $self->append_data( \%row );
    return (ref $rs) ? $request : undef;
}

=head2 append_ns_data( $request_row )

Additional request fields from related ns.

   my $request = $self->append_data( $request_row_hash );

   * ns_name
   * ns_icon

Returns augmented request row.

=cut
sub append_ns_data {
    my ($self, $request, %p ) = @_;
    my $req = $request;
    my $namespaces = $p{model_namespaces} || Baseliner->model('Namespaces'); # for perf
    # get the request ns
    my $ns = try { $namespaces->get( $request->{ns} ) } catch { };
    unless( ref $ns ) {
        _log _loc "Error: request %1 has an invalid namespace %2", $request->{id}, $request->{ns};
        return;
    }
    # get the request ns name and icon
    $req->{ns_name} =  $ns->ns_name . " (" . $ns->ns_type . ")";
    $req->{ns_icon} =  try { $ns->icon } catch { '' };
    return $req;
}

=head2 append_data

Process row data and add additional fields.

   my $request = $self->append_data( $request_row_hash );

   * localize request type
   * app and rfc from request data

Returns augmented request row.

=cut
sub append_data {
    my ($self, $request, %p ) = @_;
    my $req = $request;
    my $namespaces = $p{model_namespaces} || Baseliner->model('Namespaces'); # for perf
    my $ns = try { $namespaces->get( $request->{ns} ) } catch { };
    unless( ref $ns ) {
        _log _loc "Error: request %1 has an invalid namespace %2", $request->{id}, $request->{ns};
        return;
    }
    my $ns_icon = try { $ns->icon } catch { '' };
    $req->{ns_name} =  $ns->ns_name . " (" . $ns->ns_type . ")";
    $req->{ns_icon} =  try { $ns->icon } catch { '' };
    $req->{type} =  _loc($request->{type} );
    #my $row = Baseliner->model('Baseliner::BaliRequest')->search({ id=> $request->{id} })->first;
    if( $request->{data} ) {
        my $data = _load( $request->{data} );
        if( ref $data eq 'HASH' ) {
            $req->{app} = (ns_split($data->{app}))[1];
        } else {
            _log "Invalid request data for request " . $req->{id};
        }
    } else {
        _log "No request data for request " . $req->{id};
    }
    return $req;
}

=head2 approvals_active

Report if daemon is active. If daemons are not active, all approval checking is disabled.

Being active is not the same having the daemon started or stopped.
This is controlled by the C<config.approval.active> variable.

=cut
sub approvals_active {
    my ($self)=@_;
    my $config = Baseliner->model('ConfigStore')->get('config.approval' );
    return defined $config->{active} ? $config->{active} : 0;
}

=head1 DESCRIPTION

pending => create request, but not notified
notified => request notified
cancelled => request cancelled or overwritten by a new one
approved => ok
rejected => nok

=cut
1;
