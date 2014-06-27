package Baseliner::Controller::Log;
use Moose;
use Baseliner::Utils;
use JavaScript::Dumper;
use Compress::Zlib;
use Try::Tiny;
use JSON::XS;

BEGIN { extends 'Catalyst::Controller' }

sub logs_list : Path('/job/log/list') {
    my ( $self, $c, $mid ) = @_;
    my $p = $c->req->params;
    $c->stash->{mid} = $mid // $p->{mid};
    $c->stash->{service_name} = $p->{service_name};
    $c->stash->{annotate_now} = $p->{annotate_now};
    my $job = ci->new( $p->{mid} );
    $c->stash->{job_exec} = ref $job ? $job->exec : 1;
    $c->forward('/permissions/load_user_actions');
    $c->stash->{template} = '/comp/log_grid.js';
}

sub dashboard_log : Path('/job/log/dashboard') {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $job = ci->new( $p->{mid} );
    $c->stash->{mid} = $job->mid;
    $c->stash->{name_job} = $p->{name} // $job->name;
    $c->stash->{job_exec} = ref $job ? $job->exec : 1;
    $c->stash->{summary} = $job->summary;
    $c->stash->{services} = $job->service_summary( summary=>$c->stash->{summary} );
    $c->stash->{contents} = $job->{job_contents};
    $c->stash->{outputs} = $job->artifacts;
    $c->stash->{template} = '/comp/dashboard_job.html';
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

# used by log_grid to refresh the log
sub auto_refresh : Path('/job/log/auto_refresh') {
    my ( $self,$c )=@_;
    my $p = $c->request->parameters;
    my $mid = ''. $p->{mid};
    my $filter = $p->{filter};
       $filter = decode_json( $filter ) if $filter;
    my $where = { mid => $mid, 'exec' => 0+($p->{job_exec} || 1) };
    #_log _dump ( $filter );
    $where->{lev} = mdb->in( grep { $filter->{$_} } keys %$filter ) if ref($filter) eq 'HASH';
    _log _dump $where;
    my $rs = mdb->job_log->find($where)->sort({ id=>-1 });
    my $top = $rs->next;
    my $job = ci->job->find_one({ mid=>$mid });
    if( $job ) {
        my $stop_now = $job->{status} ne 'RUNNING' ? \1 : \0;
        $c->stash->{json} = { count => $rs->count, top_id=>$top->{id}, stop_now=>$stop_now };  
    } else {
        $c->stash->{json} = { count => $rs->count, top_id=>$top->{id}, stop_now=>\1 };  
    }
    $c->forward('View::JSON');
}

sub log_rows : Private {
    my ( $self,$c, $mid )=@_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $service_name, $filter, $cnt ) = @{$p}{qw/start limit query dir sort service_name filter/};
    $limit||=50;
    ($sort, $dir) = split /\s+/, $sort if $sort =~ /\s/; # sort may have dir in it, ie: "id asc"
    $dir = defined $dir && lc $dir eq 'desc' ? -1 : 1; 
    # include direction in sort, so that both fields follow the same sort
    my $sort_ix = Tie::IxHash->new( $sort ? ( $sort => $dir ) : (), $sort ne 'id' ? ( id=>$dir ):() );
    
    $filter = decode_json( $filter ) if $filter;
    my $config = $c->registry->get( 'config.job.log' );
    my @rows = ();
    $mid //= $p->{mid};
    _fail 'Missing mid' unless length $mid;

    my $job = ci->new( $mid );

    my $where = $mid ? { mid=>"$mid" } : {};

    $where = {};	
    if( $query ) {
        #$where->{'lower(to_char(ts)||text||lev||me.ns||provider||data_name)'} = { like => '%'. lc($query) . '%' };
        $where = mdb->query_build( query=>$query, fields=>[qw(
                ts          
                t
                text		
                ns			
                provider	
                data_name   
                service_key	
                step		
                )]);		
    } else {
        my $job_exec;
        if( exists $p->{job_exec} ) {
            $job_exec = $p->{job_exec};
        } else {
            $job_exec = ref $job ? $job->exec : 1;
        }
        $where->{'exec'} = 0+$job_exec;
        # faster: $from->{join} = [ 'jobexec' ];
    }
    
    if($mid){
        $where->{mid} = $mid;
    }
    $where->{lev} = mdb->in( grep { $filter->{$_} } keys %$filter )
        if ref($filter) eq 'HASH';
    $p->{levels} and $where->{lev} = mdb->in( _array $p->{levels} );
    
    #Viene por la parte de dashboard_log
    if($service_name){
        $where->{service_key} = $service_name;
    }
    #TODO    store filter preferences in a session instead of a cookie, on a by mid basis

    my $rs = mdb->job_log->find( $where );
    $rs->sort( $sort_ix );
    
    #my $pager = $rs->pager;
    #$cnt = $pager->total_entries;

    my $qre = qr/\.\w+$/;
    while( my $doc = $rs->next ) {
        my $more = $doc->{more};
        my $data;
        if( $p->{with_data} || ( defined $more && $more eq 'link' ) ) {
            my $logd = $doc->{data} ? mdb->grid->get( $doc->{data} ) : '';
            $data = $logd ? $logd->slurp : '';
            $data = _html_escape( uncompress($data) || $data );
        }

        my $data_len = $doc->{data_length} || 0;
        my $data_name = $doc->{data_name} || ''; 
        my $file = $data_name =~ $qre
            ? $data_name
            : ( $data_len > ( 4 * 1024 ) )
                ? ( $data_name || $self->_select_words($doc->{text},2) ) . ".txt"
                : '';
        push @rows,
          {
            id       => $doc->{id},
            mid      => $doc->{mid},  # job mid
            id_data  => $doc->{data},  # job mid
            job      => $job->{name},
            text     => Util->_markup( $doc->{text} ),
            step     => $doc->{step},
            prefix   => $doc->{prefix},
            milestone=> $doc->{milestone},
            service_key=> $doc->{service_key},
            exec     => $doc->{exec},
            ts       => $doc->{ts},
            t        => $doc->{t},
            lev      => $doc->{lev},
            module   => $doc->{module},
            section  => $doc->{section},
            ns       => $doc->{ns},
            pid      => $doc->{pid},
            provider => $doc->{provider},
            datalen  => $data_len,
            data     => $data,
            more     => { more=>$more, data_name=> $doc->{data_name}, data=> $data_len ? \1 : \0, file=>$file },
          } #if( ($cnt++>=$start) && ( $limit ? scalar @rows < $limit : 1 ) );
    }
    return ( $job, @rows );
}

sub log_html : Path('/job/log/html') {
    my ($self,$c, $job_key ) = @_;
    my $p = $c->request->parameters;

    # load from hash
    if( $job_key ) {
        my $job = ci->job->search_ci( job_key=>$job_key );
        _throw "Job key not found (job_key=$job_key)" unless ref $job;
        $p->{mid} = $job->mid;
        $p->{job_exec} ||= $job->exec;
        $p->{levels} = [ 'info', 'warn', 'error' ];
        $p->{debug} eq 1 and push @{ $p->{levels} }, 'debug';
    }
    # get data
    if( defined $p->{mid} ) {
        # log_rows uses req->parameters ($p) 
        my ($job, @rows ) = $self->log_rows( $c, $p->{mid} );
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
    my $job_key = $job->job_key;
    $c->stash->{json} = {
        totalCount => scalar(@rows),
        data       => \@rows,
        job        => ref $job ? $job : {},
        job_key  => $job_key,
     };	
    # CORE::warn Dump $c->stash->{json};
    $c->forward('View::JSON');
}

sub jesSpool : Path('/job/log/jesSpool') {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    #_log _dump $p;
    $c->stash->{jobStore} = '/job/log/jobList?logId='.$p->{id}.'&jobId='.$p->{jobId}.'&jobName='.$p->{jobName};
    $c->stash->{jobName} = '/job/log/jesFile';
    # $c->stash->{template} = '/comp/repl.mas';
    $c->stash->{template} = '/comp/jes_viewer.mas';
}

sub jobList : Path('/job/log/jobList') {
    my ( $self, $c ) = @_;
    my ( @sites, @jobs, @files, @packages ) = ( (), (), (), () );
    my $p = $c->req->params;
    my $log;

    _log _dump $p;
    my $pkgIcon   = '/static/images/icons/package_green.gif';
    my $siteIcon  = '/static/images/site.gif';
    my $jobIcon   = '/static/images/book.gif';
    my $spoolIcon = '/static/images/page.gif';
    my $infoIcon  = '/static/images/log_i.gif';

    if ( $p->{logId} ) {
        # (log data)->search( { id_log => $p->{logId} }, { order_by => 'path, id' } );
        # search for children of a log
        $log = mdb->jes_log->find({ id_log => 0+$p->{logId}});
    } else {
        # (log data)->search( { mid => $p->{jobId} }, { order_by => 'path, id' } );
        $log = mdb->grid->chunks->find({ mid=>$p->{jobId} })->sort(Tie::IxHash->new( path=>1, id=>1 ));
    }
    my ( $package, $site, $parent, $lastSite, $lastParent, $lastPackage ) =
        ( undef, undef, undef, undef, undef, undef, undef );

    while ( my $rec = $log->next ) {
        _log "Solving $rec->{name}";
        if ( $rec->{name} =~ m{\/(.*)\/.*\/(fin(..))}i ) {
            push @sites,
                {
                id   => "$1$3",
                cls  => 'x-tree-node-leaf',
                icon => $infoIcon,
                leaf => 1,
                text => $2,
                data => $3
                };
            next;
        }

        my ( $root, $packageText, $siteText, $parentText, $file ) = split /\//, $rec->{name};

        $parent = {};
        $parent->{key}  = "/".$packageText."/".$siteText."/".$parentText;
        $parent->{text} = $parentText;

        $site = {
            key  => "/$packageText/$siteText",
            text => $siteText
        };
        $package = {
            key  => "/$packageText",
            text => $packageText
        };

        if ( $parent->{key} ne $lastParent->{key} ) {

            #_log $rec->{name} ."=". _dump $parent . ".." . _dump $lastParent;
            _log "EEEEEEEEEEEEEEE"._dump $parent;
            push @jobs,
                {
                id       => $lastParent->{text} !~ m{siteok|siteko}i ? $lastParent->{id} : '~' . $lastParent->{id},
                cls      => 'x-tree-node',
                icon     => $lastParent->{text} !~ m{siteok|siteko}i ? $jobIcon : $infoIcon,
                needLoad => \1,
                _id       => $rec->{_id},
                leaf     => $lastParent->{text} !~ m{siteok|siteko}i ? 0 : 1,
                text     => $lastParent->{text},
                children => [@files]
                }
                if $lastParent->{text};
            @files      = ();
            $lastParent = {
                text => $parent->{text},
                key  => $parent->{key},
                id   => $parent->{key}
            };
        }
        if ( $site->{key} ne $lastSite->{key} ) {

            # _log $site->{key}." vs ".$lastSite->{key};
            push @sites,
                {
                id       => $lastSite->{key},
                cls      => 'x-tree-node',
                icon     => $siteIcon,
                leaf     => 0,
                text     => $lastSite->{text},
                children => [@jobs]
                }
                if $lastSite->{text};
            @jobs     = ();
            $lastSite = {
                text => $site->{text},
                key  => $site->{key},
                id   => $site->{key}
            };
        }

        if ( $package->{key} ne $lastPackage->{key} ) {
            push @packages,
                {
                id       => $lastPackage->{text},
                cls      => 'x-tree-node',
                icon     => $pkgIcon,
                leaf     => 0,
                text     => $lastPackage->{text},
                children => [@sites]
                }
                if $lastPackage->{text};
            @sites       = ();
            $lastPackage = {
                text => $package->{text},
                key  => $package->{key},
                id   => $package->{key}
            };
        }
        push @files,
            {
            id       => $rec->{_id}->{value},
            cls      => 'x-tree-node-leaf',
            icon     => $spoolIcon,
            leaf     => 1,
            needLoad => 1,
            text     => $file,
            data     => ''
            }
            if length $file > 0 && $parent->{text} !~ m{siteok|siteko}i;
    }
    push @jobs,
        {
        id => $lastParent->{text} !~ m{siteok|siteko}i ? $lastParent->{id} : '~' . $lastParent->{id},
        cls      => 'x-tree-node',
        icon     => $lastParent->{text} !~ m{siteok|siteko}i ? $jobIcon : $infoIcon,
        needLoad => \1,
        leaf     => $lastParent->{text} !~ m{siteok|siteko}i ? 0 : 1,
        text     => $lastParent->{text},
        children => [@files]
        };

    push @sites,
        {
        id       => $lastSite->{key},
        cls      => 'x-tree-node',
        icon     => $siteIcon,
        leaf     => 0,
        text     => $lastSite->{text},
        children => [@jobs]
        }
        if $lastSite->{text};

    push @packages,
        {
        id       => $lastPackage->{text},
        cls      => 'x-tree-node',
        icon     => $pkgIcon,
        leaf     => 0,
        text     => $lastPackage->{text},
        children => [@sites]
        }
        if $lastPackage->{text};

    push my @ret,
        {
        id       => 'first',
        text     => _loc( 'Executed JOBS for <b>%1</b>', $p->{jobName} ),
        cls      => 'x-tree-node',
        leaf     => 0,
        children => [@packages]
        };

    $c->stash->{json} = [@ret];
    $c->forward('View::JSON');
}

sub jesFile : Path('/job/log/jesFile') {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    _log "RRRRRRRRRRRRRRRRRR "._dump $p;
    my ($id) = _array($p->{id});
    # my $log = $c->model('Baseliner::BaliLogData')->search({ id=>$p->{id} })->first;
    my $log = mdb->jes_log->find_one({ _id=>mdb->oid($id) });
    my $data=$log->{data};
    $c->stash->{json} = {data=>$data};
    $c->forward('View::JSON');
}

sub log_data : Path('/job/log/data') {
    my ( $self, $c, $id ) = @_;
    my $p = $c->req->params;
    my $log = mdb->job_log->find_one({ id=> 0+$id || 0+$p->{id} });
    my $logd = $log->{data} ? mdb->grid->get( $log->{data} ) : '';
    my $data = $logd ? $logd->slurp : '';
    if( $data ) {
        $data = uncompress($data) || $data;
        $data = _html_escape( $data );
    }
    $c->res->body( "<pre>" . $data  . " " );
}

sub log_elements : Path('/job/log/elements') {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $job = ci->new( $p->{mid} ); 
    my $job_exec = ref $job ? $job->exec : 1;
    my @items = _array ($job->stash->{items});
    my $data = join "\n", map { $_->status . "\t" . $_->path . " (" . $_->versionid . ")" } @items;
    $data = _html_escape( $data );
    # TODO send this to a comp with a pretty table
    $c->res->body( qq{<pre style="padding: 10px 10px 10px 10px;">$data</pre>} );	
}

sub log_delete : Path('/job/log/delete') {
    my ( $self, $c, $id ) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        mdb->job_log->remove({ id=>0+$id, mid=>''.$p->{mid}, exec=>0+$p->{job_exec} });
        { success=>\1, msg=>_loc( "Deleted" ) };
    } catch {
        { success=>\0, msg=>shift() };
    };
    $c->forward('View::JSON');
}

sub log_highlight : Path('/job/log/highlight') {
    my ( $self, $c, $id ) = @_;
    my $p = $c->req->params;
    $id ||= $p->{id};
    my $log = mdb->job_log->find_one({ id=>0+$id });
    _fail _loc 'Log row not found: %1', $id unless $log;
    if( my $viewer_key = $log->{provider} ) {
        if( my $viewer = $c->model('Registry')->get( $viewer_key ) ) {
            # viewer options
        }
    }
    $c->stash->{class} = $log->{data_length} > 1000000 ? '' : $log->{highlight_class} || 'spool';
    $c->stash->{style} = $log->{highlight_style} || 'golden';
    my $logd = mdb->grid->find_one({ _id=>$log->{data} });
    _fail _loc 'Log data not found: %1', $log->{data} unless $logd;
    my $data = $logd->slurp;
    $c->stash->{data} = (uncompress($data) || $data)  . " ";
    $c->stash->{template} = '/site/highlight.html';
}

sub log_file : Path('/job/log/download_data') {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $id = $p->{id};
    my $log = mdb->job_log->find_one({ id=>0+$id });
    _fail _loc 'Log row not found: %1', $id unless $log;
    my $logd = mdb->grid->find_one({ _id=>$log->{data} });
    _fail _loc 'Log data not found: %1', $log->{data} unless $logd;
    my $file_id = $log->{mid}.'-'.$p->{id};
    my $data = $logd->slurp;
    my $filename = $file_id . '-' . ( $p->{file_name} || $log->{data_name} || 'attachment.txt' );
    $c->stash->{serve_filename} = $filename;
    $c->stash->{serve_body} = uncompress($data) || $data;
    $c->forward('/serve_file');
}

sub upload_file : Path('/job/log/upload_file') {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;

    my $mid      = $p->{mid};
    my $filename = $p->{qqfile};
    my $level    = $p->{level} ||= 'info';
    my $text     = $p->{text};
    
    my $f = _file( $c->req->body );
    _log "Uploading to log " . $filename;
    try {
        my $job = ci->new( $mid );
        my $msg = length $text  ? $text : _loc( "User *%1* has uploaded file '%2'", $c->username, $filename);  
        $job->logger->$level( $msg, data=>''.$f->slurp, data_name=>"$filename", more=>'file', username=>$c->username );
        $c->stash->{ json } = { success => \1, msg => _loc( 'File saved to job %1 log: %2', $job->name, $filename ) } ;            
    } catch {
        my $err = shift;
        _error "Error uploading file to job log: " . $err;
        $c->stash->{ json } = { success => \0, msg => $err };
    };
    $c->forward( 'View::JSON' );
}

1;
