package BaselinerX::Job::Controller::Log;
use Moose;
use Baseliner::Utils;
use JavaScript::Dumper;
use Compress::Zlib;
use Try::Tiny;
use JSON::XS;

BEGIN { extends 'Catalyst::Controller' }

sub logs_list : Path('/job/log/list') {
    my ( $self, $c ) = @_;
	my $p = $c->req->params;
    $c->stash->{id_job} = $p->{id_job};
	$c->stash->{service_name} = $p->{service_name};
    $c->stash->{annotate_now} = $p->{annotate_now};
	my $job = $c->model('Baseliner::BaliJob')->find( $p->{id_job} );
	$c->stash->{job_exec} = ref $job ? $job->exec : 1;
    $c->forward('/permissions/load_user_actions');
    $c->stash->{template} = '/comp/log_grid.mas';
}

sub dashboard_log : Path('/job/log/dashboard') {
    my ( $self, $c ) = @_;
	my $p = $c->req->params;
	$c->stash->{id_job} = $p->{id_job};
	$c->stash->{name_job} = $p->{name};

	my $job = $c->model('Baseliner::BaliJob')->find( $p->{id_job} );
	$c->stash->{job_exec} = ref $job ? $job->exec : 1;
    $self->summary( $c );
    $self->services( $c );
	$self->contents( $c );
	$self->outputs( $c );

    $c->stash->{template} = '/comp/dashboard_job.js';
}

sub summary: Private{
    my ( $self, $c ) = @_;
    my $sumary = $c->model('Jobs')->get_summary( jobid => $c->stash->{id_job}, job_exec => $c->stash->{job_exec} );
    $c->stash->{summary} = $sumary;
}

sub services: Private{
    my ( $self, $c ) = @_;
	my $services = $c->model('Jobs')->get_services_status( jobid => $c->stash->{id_job}, job_exec => $c->stash->{job_exec} );
	$c->stash->{services} = $services;
}

sub contents: Private{
	my ($self, $c ) = @_;
	my $contents = $c->model('Jobs')->get_contents ( jobid => $c->stash->{id_job}, job_exec => $c->stash->{job_exec} );
	$c->stash->{contents} = $contents;
}

sub outputs: Private{
	my ($self, $c ) = @_;
	my $outputs = $c->model('Jobs')->get_outputs ( jobid => $c->stash->{id_job}, job_exec => $c->stash->{job_exec} );
	$c->stash->{outputs} = $outputs;
}


sub _select_words {
	my ($self,$text,$cnt)=@_;
	my @ret=();
	for( $text =~ /(\w+)/g ) {
		next if length( $_ ) <= 3;
		push @ret, $_;
		last if @ret >= $cnt;
	}
	return join '_', @ret;
}

sub auto_refresh : Path('/job/log/auto_refresh') {
	my ( $self,$c )=@_;
	my $p = $c->request->parameters;
    my $filter = $p->{filter};
       $filter = decode_json( $filter ) if $filter;
    my $where = { id_job => $p->{ id_job }, 'me.exec' => $p->{ job_exec } || 1 };
    #_log _dump ( $filter );
    $where->{lev} = [ grep { $filter->{$_} } keys %$filter ]
        if ref($filter) eq 'HASH';
    _log _dump $where;
    my $rs = $c->model( 'Baseliner::BaliLog' )->search( $where, { order_by=>'me.id desc', join=>['job'] } );
    my $top = $rs->first;
    my $stop_now = $top->job->status ne 'RUNNING' ? \1 : \0;
    $c->stash->{json} = { count => $rs->count, top_id=>$top->id, stop_now=>$stop_now };  
	$c->forward('View::JSON');
}

sub log_rows : Private {
	my ( $self,$c )=@_;
    _db_setup;
	my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $service_name, $filter, $cnt ) = @{$p}{qw/start limit query dir sort service_name filter/};
    $limit||=50;
    $filter = decode_json( $filter ) if $filter;
	my $config = $c->registry->get( 'config.job.log' );
	my @rows = ();
    my $job = $c->model('Baseliner::BaliJob')->find( $p->{id_job} );
	my $from = {   order_by=> $sort ? "$sort $dir" : 'me.id',
					#page => to_pages( start=>$start, limit=>$limit ),  
					#rows => $limit,
				#	prefetch => ['job']
                };
	#TODO use the blob 'data' somehow .. change to clob?

	my $where = {};	
	if( $query ) {
		#$where->{'lower(to_char(timestamp)||text||lev||me.ns||provider||data_name)'} = { like => '%'. lc($query) . '%' };
		$where = query_sql_build( query=>$query, fields=>{
			    timestamp   =>'to_char(timestamp)',
			    text		=>'text',
			    ns			=>'ns',
			    provider	=>'provider',
			    data_name   =>'data_name',
				service_key	=>'service_key',
				step		=>'step',
			});		
	} else {
		my $job_exec;
		if( exists $p->{job_exec} ) {
			$job_exec = $p->{job_exec};
		} else {
			$job_exec = ref $job ? $job->exec : 1;
		}
		$where->{'me.exec'} = $job_exec;
		# faster: $from->{join} = [ 'jobexec' ];
	}
	
	if($p->{id_job}){
		$where->{id_job} = $p->{id_job};
	}
    $where->{lev} = [ grep { $filter->{$_} } keys %$filter ]
        if ref($filter) eq 'HASH';
    $p->{levels} and $where->{lev} = [ _array $p->{levels} ];
	
	#Viene por la parte de dashboard_log
	if($service_name){
		$where->{service_key} = $service_name;
	}
    #TODO    store filter preferences in a session instead of a cookie, on a by id_job basis
    #my $job = $c->model( 'Baseliner::BaliJob')->search({ id=>$p->{id_job} })->first;
    my $rs = $c->model( 'Baseliner::BaliLog')->search( $where , $from );
	#my $pager = $rs->pager;
	#$cnt = $pager->total_entries;

	my $qre = qr/\.\w+$/;
	while( my $r = $rs->next ) {
        my $more = $r->more;
        my $data = $p->{with_data} || $more eq 'link'
            ? _html_escape( uncompress( $r->data ) || $r->data ) : '';
        #next if( $query && !query_array($query, $r->job->name, $r->get_column('timestamp'), $r->text, $r->provider, $r->lev, $r->data_name, $data, $r->ns ));
        #if( $filter ) { next if defined($filter->{$r->lev}) && !$filter->{$r->lev}; }

        my $data_len = $r->data_length || 0;
        my $data_name = $r->data_name || ''; 
        my $file = $data_name =~ $qre
            ? $data_name
            : ( $data_len > ( 4 * 1024 ) )
                ? ( $data_name || $self->_select_words($r->text,2) ) . ".txt"
                : '';
        push @rows,
          {
            id       => $r->id,
            id_job   => $r->id_job,
            job      => $r->job->name,
            text     => _markup( $r->text ),
            step     => $r->step,
            prefix   => $r->prefix,
            milestone=> $r->milestone,
            service_key=> $r->service_key,
            exec     => $r->exec,
            ts       => $r->get_column('timestamp'),
            lev      => $r->lev,
            module   => $r->module,
            section  => $r->section,
            ns       => $r->ns,
            provider => $r->provider,
			datalen  => $data_len,
            data     => $data,
            more     => { more=>$more, data_name=> $r->data_name, data=> $data_len ? \1 : \0, file=>$file },
          } #if( ($cnt++>=$start) && ( $limit ? scalar @rows < $limit : 1 ) );
	}
    return ( $job, @rows );
}

sub log_html : Path('/job/log/html') {
    my ($self,$c, $job_key ) = @_;
    my $p = $c->request->parameters;

    # load from hash
    if( $job_key ) {
        my $job = $c->model('Baseliner::BaliJob')->search({ key=>$job_key })->first;
        _throw "Job key not found (key=$job_key)" unless ref $job;
        $p->{id_job} = $job->id;
        $p->{job_exec} ||= $job->exec;
        $p->{levels} = [ 'info', 'warn', 'error' ];
        $p->{debug} eq 1 and push @{ $p->{levels} }, 'debug';
    }
    # get data
    if( defined $p->{id_job} ) {
        # log_rows uses req->parameters ($p) 
        my ($job, @rows ) = $self->log_rows( $c );
        # prepare template
        $c->stash->{rows} = \@rows;
        $c->stash->{job_name} = $job->name;
        $c->stash->{job_exec} = $job->exec;
        $c->stash->{job_exec_total} = $job->exec;
        $c->stash->{job_key} = $job_key;
        $c->stash->{template} = '/comp/log.html';
    } else {
        $c->res->status( 404 );
    }
}

sub logs_json : Path('/job/log/json') {
    my ( $self,$c )=@_;
    my $p = $c->request->parameters;
    my ($job, @rows ) = $self->log_rows( $c );
    my $job_key = $job->key;
	$c->stash->{json} = {
        totalCount => scalar(@rows),
        data       => \@rows,
        job        => { ref $job ? $job->get_columns : () },
        job_key  => $job_key,
     };	
    # CORE::warn Dump $c->stash->{json};
	$c->forward('View::JSON');
}

# sub log_data : Path('/job/log/data') {
#     my ( $self, $c, $id ) = @_;
#     _db_setup;
# 	my $p = $c->req->params;
# 	my $log = $c->model('Baseliner::BaliLog')->search({ id=> $id || $p->{id} })->first;
# 	$c->res->body( "<pre>" . (uncompress($log->data) || $log->data)  . " " );
# }

sub jesSpool : Path('/job/log/jesSpool') {
    my ( $self, $c ) = @_;
    _db_setup;
    my $p = $c->req->params;
    _log _dump $p;
    $c->stash->{jobStore} = '/job/log/jobList?id='.$p->{id}.'&job='.$p->{job};
    $c->stash->{jobName} = '/job/log/jesFile';
    # $c->stash->{template} = '/comp/repl.mas';
    $c->stash->{template} = '/comp/jes_viewer.mas';
}

sub jobList : Path('/job/log/jobList') {
    my ( $self, $c ) = @_;
    my (@jobs, @leaf)=((),());
    my $p = $c->req->params;
    # _log _dump $p;
    my $jobIcon='/static/images/jobIcon.png';
    my $spoolIcon='/static/images/spoolIcon.png';
    _db_setup;
    my $log = $c->model('Baseliner::BaliLogData')->search({ id_log=> $p->{id} }, { order_by=>'id asc' });
    my $lastParent=undef;
    while (my $rec=$log->next) {
        my ($null,$site,$parent,$file)=split /\//, $rec->name;
        if ($parent  ne $lastParent) {
            push @jobs,
                {
                id       => $lastParent,
                cls      => 'x-tree-node',
                icon     => $jobIcon,
                leaf     => 0,
                text     => $lastParent,
                children => [@leaf]
                } if $lastParent;
            @leaf=();
            $lastParent=$parent;
            }
        push @leaf,
            {
            id       => $rec->id,
            cls      => 'x-tree-node-leaf',
            icon     => $spoolIcon,
            leaf     => 1,
            needLoad => 1,
            text     => $file,
            data     => ''
            };
        }
    push @jobs,
      {
      id       => $lastParent,
      cls      => 'x-tree-node',
      icon     => $jobIcon,
      leaf     => 0,
      text     => $lastParent,
      children => [@leaf]
      };

    push my @ret,
        {
        id       => 'first',
        text     => _loc('Executed JOBS for %1', $p->{job} ),
        cls      => 'x-tree-node',
        leaf     => 0,
        children     => [@jobs]
        };

    $c->stash->{json} = [ @ret ];
    $c->forward('View::JSON');
    }

sub jesFile : Path('/job/log/jesFile') {
    my ( $self, $c ) = @_;
    _db_setup;
    my $p = $c->req->params;
    my $log = $c->model('Baseliner::BaliLogData')->search({ id=>$p->{id} })->first;
    my $data=$log->data;
    $c->stash->{json} = {data=>$data};
    $c->forward('View::JSON');
}

sub log_data : Path('/job/log/data') {
    my ( $self, $c, $id ) = @_;
    _db_setup;
	my $p = $c->req->params;
	my $log = $c->model('Baseliner::BaliLog')->search({ id=> $id || $p->{id} })->first;
    my $data = uncompress($log->data) || $log->data;
    $data = _html_escape( $data );
    $c->res->body( "<pre>" . $data  . " " );
}

sub log_elements : Path('/job/log/elements') {
    my ( $self, $c ) = @_;
	my $p = $c->req->params;
	my $job = $c->model('Baseliner::BaliJob')->find(  $p->{id_job} );
	
	my $job_exec = ref $job ? $job->exec : 1;
	my $contents = $c->model('Jobs')->get_contents ( jobid => $p->{id_job}, job_exec => $job_exec);	
	
	my $data;
	my @elements = _array ($contents->{elements});
	for my $element (@elements){
		$data = $data . $element->{status} . "\t" . $element->{path} . '/' . $element->{name} ."\n";
	}
	$data = _html_escape( $data );
    $c->res->body( "<pre>" . $data  . " " );	
}

sub log_delete : Path('/job/log/delete') {
    my ( $self, $c, $id ) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        my $log = $c->model('Baseliner::BaliLog')->search({ id_job=>$p->{id_job}, exec=>$p->{job_exec} })->delete;
        { success=>\1, msg=>_loc( "Deleted" ) };
    } catch {
        { success=>\0, msg=>shift() };
    };
    $c->forward('View::JSON');
}

sub log_highlight : Path('/job/log/highlight') {
    my ( $self, $c, $id ) = @_;
    _db_setup;
	my $p = $c->req->params;
	my $log = $c->model('Baseliner::BaliLog')->search({ id=> $id || $p->{id} })->first;
    if( my $viewer_key = $log->provider ) {
        if( my $viewer = $c->model('Registry')->get( $viewer_key ) ) {
            # viewer options
        }
    }
	$c->stash->{class} = $log->data_length > 1000000 ? '' : $log->{highlight_class} || 'spool';
	$c->stash->{style} = $log->{highlight_style} || 'golden';
	$c->stash->{data} = (uncompress($log->data) || $log->data)  . " ";
	$c->stash->{template} = '/site/highlight.html';
}

sub log_data_search : Path('/job/log/data_search') {
    my ( $self, $c ) = @_;
    _db_setup;
	my $p = $c->req->params;
	my $log = $c->model('Baseliner::BaliLog')->search({ id=> $p->{id} })->first;
	$c->stash->{log_data} = uncompress($log->data) || $log->data;
	$c->stash->{template} = '/comp/log_search.mas';
}

sub log_file : Path('/job/log/download_data') {
    my ( $self, $c ) = @_;
    _db_setup;
	my $p = $c->req->params;
	my $log = $c->model('Baseliner::BaliLog')->search({ id=> $p->{id} })->first;
    my $file_id = $log->id_job.'-'.$p->{id};
    my $filename = $file_id . '-' . ( $p->{file_name} || $log->data_name || 'attachment.txt' );
    $c->stash->{serve_filename} = $filename;
    $c->stash->{serve_body} = uncompress($log->data) || $log->data;
	$c->forward('/serve_file');
}

sub annotate : Path('/job/log/annotate') {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $level = $p->{level} ||= 'info';
    try {
        _throw 'Missing text' unless $p->{text};
        my $text = $p->{text};
        $text = substr($text, 0, 2048 );
        #$text = '<b>' . $c->username . '</b>: ' . $p->{text};
        my %args = ( jobid=>$p->{jobid} );
        $args{job_exec} = $p->{job_exec} if $p->{job_exec} > 0;
        Baseliner->model('Jobs')->log(  %args  )->comment( $text, data=>$p->{data}, username=>$c->username );
        $c->stash->{json} = { success=>\1 };
    } catch {
        $c->stash->{json} = { success=>\0, msg=>shift };
    };
    $c->forward('View::JSON');
}

1;
