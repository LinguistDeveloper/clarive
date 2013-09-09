package BaselinerX::CI::job;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging);
use Try::Tiny;
with 'Baseliner::Role::CI::Internal';

has id_job       => qw(is rw isa Any); 
has id_rule      => qw(is rw isa Any);
has bl           => qw(is rw isa Any);
has rollback     => qw(is rw isa Bool default 0);
has job_key      => qw(is rw isa Any), default => sub { Util->_md5() };
has job_type     => qw(is rw isa Any default promote);  # promote, demote, static
has job_stash    => qw(is rw isa HashRef), default=>sub{ +{} };
has job_dir      => qw(is rw isa Any lazy 1), default => sub { 
    my ($self) = @_;
    my $job_home = $ENV{BASELINER_JOBHOME} || $ENV{BASELINER_TEMP} || File::Spec->tmpdir();
    File::Spec->catdir( $job_home, $self->name ); 
};  
has root_dir     => qw(is rw isa Any);
has schedtime    => qw(is rw isa Any);
has starttime    => qw(is rw isa Any);
has endtime      => qw(is rw isa Any);
has maxstarttime => qw(is rw isa Any);
has step         => qw(is rw isa Str default CHECK);
has exec         => qw(is rw isa Num default 1);
has status       => qw(is rw isa Any default IN-EDIT);
has contents     => qw(is rw isa Any);
has approval     => qw(is rw isa Any);
has username     => qw(is rw isa Any);
has runner       => qw(is rw isa Any);

sub icon { '/static/images/icons/job.png' }

has_cis 'changesets';

sub rel_type {
    { 
        changesets => [ from_mid => 'job_changeset' ] ,
    };
}

before new_ci => sub {
    my ($self, $master_row, $data ) = @_;
    $self->_create( %$self ) if ref $self eq __PACKAGE__;  # don't do this in job_run
};

# adds extra data to _ci during loading
around load_post_data => sub {
    my ($orig, $class, $mid, $data ) = @_;
    
    return {} unless $mid;
    
    my $row = DB->BaliJob->search({ mid=>$mid }, {})->first;
    my $job_stash = $row->stash;
    my $job_row = +{ $row->get_columns, job_stash=>$job_stash }; 
    
    $job_row->{job_type} = $job_row->{type};
    $job_row->{id_job} = $job_row->{id};
    delete $job_row->{mid};

    # load stash
    $job_row->{job_stash} = 
        try { 
            Util->_load($job_row->{job_stash}) 
        } catch { 
            my $err = shift;
            _log _loc "Error loading job stash: %1", $err;
            +{};
    } if length $job_row->{job_stash};
    if( ref $job_row->{job_stash} ) {
        delete $job_row->{job_stash}{job} 
    } else {
        $job_row->{job_stash} = {};
    }
    
    return $job_row;
};

sub jobid { shift->id_job }

sub job_row {
    my ($self, $id_job )=@_;
    DB->BaliJob->find( $id_job // $self->id_job );
}

sub job_update {
    my $self = shift;
    DB->BaliJob->search({ id=>$self->id_job })->update( @_ );
}

sub job_data {
    my ($self)=@_;
    +{ $self->job_row->get_columns };
}

sub create_runner {
    my ($self, %p) =@_; 
    local $Baseliner::CI::_no_record = 1; # prevent _ci in CIs
    my $job_run = BaselinerX::CI::job_run->new( %$self, parent_job=>$self->mid, %p );
    return $job_run;
}

sub _create {
    my ($self, %p )=@_;
    my $bl = $p{bl} || '*';

    my $job_mid = $self->mid;
    my $contents = $p{contents};
    my $config = Baseliner->model('ConfigStore')->get( 'config.job' );
    #FIXME this text based stuff needs to go away
    my $jobType = (defined $p{approval}->{reason} && $p{approval}->{reason}=~ m/fuera de ventana/i)
        ? $config->{emer_window}
        : $config->{normal_window};

    my $status = $p{status} || 'IN-EDIT';
    #$now->set_time_zone('CET');
    my $now = DateTime->now(time_zone=>Util->_tz);
    my $end = $now->clone->add( hours => $config->{expiry_time}->{$jobType} || 24 );

    $p{starttime}||=$now;
    $p{maxstarttime}||=$end;

    ## allow the creation of jobs executed outside Baseliner, with older dates
    my ($starttime, $maxstarttime ) = ( $now, $end );
    ($starttime, $maxstarttime ) = $p{starttime} < $now
        ? ( $now , $end )
        : ($p{starttime} , $p{maxstarttime} );

    $starttime =  $starttime->strftime('%Y-%m-%d %T');
    $maxstarttime =  $maxstarttime->strftime('%Y-%m-%d %T');

    my $type = $p{job_type} || $config->{type};
    
    my $row_data = {
            name         => 'temp' . $$,
            mid          => $job_mid,
            starttime    => $starttime,
            schedtime    => $starttime,
            maxstarttime => $maxstarttime,
            status       => $status,
            step         => $p{step} || 'PRE',
            type         => $type,
            runner       => $p{runner} || $config->{runner},
            id_rule      => $p{id_rule},
            username     => $p{username} || $config->{username} || 'internal',
            comments     => $p{description},
            job_key      => $p{job_key},
            ns           => '/', # not used, deprecated
            bl           => $bl,
    };
    
    # CHECK
    my $ret = Baseliner->model('Rules')->run_single_rule( id_rule=>$p{id_rule}, stash=>{ %p, %$row_data, job_step=>'CHECK' });
    
    # create db row
    my $job = Baseliner->model('Baseliner::BaliJob')->create($row_data);

    # setup name
    my $name = $config->{name}
        || $self->gen_job_name({ mask=>$config->{mask}, type=>$type, bl=>$bl, id=>$job->id });

    _log "****** Creating JOB id=" . $job->id . ", name=$name, mask=" . $config->{mask};
    $config->{runner} && $job->runner( $config->{runner} );
    $config->{chain} && $job->chain( $config->{chain} );

    $job->name( $name );
    $job->update;

    # create a hash stash

    my $log = new BaselinerX::Job::Log({ jobid=>$job->id });

    # publish release names to the log, just in case
    my @original_contents = Util::_unique Util::_array( $contents );
    my $original ='';
    foreach my $it ( Util::_array( $contents ) ) {
        my $ns = Baseliner->model('Namespaces')->get( $it->{ns} );
        try {
            $original .= '<li>' . $ns->ns_type . ": " . $ns->ns_name
                if( $ns->does('Baseliner::Role::Container') );
        } catch { };
    }
    $log->info( _loc('Job elements requested for this job: %1', '<br>'.$original ) )
        if $original;

    # create job items
    my @changesets;  # topic CIs
    if( ref $contents eq 'ARRAY' ) {
        #my $contents = $self->container_expand( $contents );
        my @item_list;
        for my $cs ( Util::_array( $contents ) ) {
            
            # create ci
            my $cs_ci = Baseliner::CI->new( $cs->{mid} );
            push @changesets, $cs_ci;

            $cs->{ns} ||= $cs->{item};
            _throw _loc 'Missing item ns name' unless $cs->{ns};
            my $ns = Baseliner->model('Namespaces')->get( $cs->{ns} );
            my $app = try { $ns->application } catch { '' };
            
            # check contents job status
            _log "Checking if in active job: " . $cs->{ns};
            my $active_job = $self->is_in_active_job( $cs->{ns} );
            _fail _loc("Job element '%1' is in an active job: %2", $cs->{ns}, $active_job->name)
                if ref $active_job;
                    # item => $cs->{ns},
            my $provider=$1 if $cs->{provider} =~ m/^namespace\.(.*)$/g;
            my $job_item_row = $job->bali_job_items->create(
                {
                    data        => _dump( $cs->{data} || $cs->{ns_data} ),
                    item        => $ns->does('Baseliner::Role::Container')?"$provider/".$ns->{ns_name}:$cs->{ns},
                    service     => $cs->{service},
                    provider    => $cs->{provider},
                    id_job      => $job->id,
                    id_project  => $ns->ns_data->{id_project},
                    application => $app,
                }
            );
            #$items->update;
            # push @item_list, '<li>'.$item->{ns}.' ('.$item->{ns_type}.')';
            # push @item_list, '<li>'. ($ns->does('Baseliner::Role::Container')?$ns->{ns_name}:$item->{ns}) . ' ('.$item->{ns_type}.')';
            push @item_list, $cs_ci->topic_name;
        }
        _fail _loc('Missing job contents') unless @item_list > 0;

        # log job items
        if( @item_list > 10 ) {
            my $msg = _loc('Job contents: %1 total items', scalar(@item_list) );
            $log->info( $msg, data=>'==>'.join("\n==>", @item_list) );
        } else {
            # my $item = "";
            # for ( @item_list ) {
                # item .= "$_\n";
                # }
            $log->info(_loc('Job contents: %1', join("\n", map { "<li><b>$_</b></li>" } @item_list)) );
        }
    }

    # add attributes to job ci
    #my $job_ci = _ci( $job_mid );
    $self->name( $name );
    $self->id_job( $job->id );
    $self->status( 'IN-EDIT' );
    $self->changesets( \@changesets );
    $self->ns( 'job/' . $job->id );
#$self->save;
    
    # now let it run
    $log->debug(_loc( 'Approval exists? ' ),data=>_dump  $p{approval});
    if ( exists $p{approval}{reason} ) {
        # approval request executed by runner service
        $job->stash_key( approval_needed => $p{approval} );
    }
    if ( ref $p{job_stash} eq 'HASH' ) {
        while( my ($k,$v) = each %{ $p{job_stash} } ) {
            $job->stash_key( $k => $v );
        }
    }
    $job->status( 'READY' );
    $job->update;
    
    # INIT
    my $ret = Baseliner->model('Rules')->run_single_rule( id_rule=>$p{id_rule}, 
        stash=>{ 
            %$row_data, %{ $p{job_stash} // {} }, 
            job_step=>'INIT' 
        });
    
    return $job;
}


sub gen_job_name {
    my $self = shift;
    my $p = shift;
    my $prefix = $p->{type} eq 'promote' || $p->{type} eq 'static' ? 'N' : 'B';
    return sprintf( $p->{mask}, $prefix, $p->{bl} eq '*' ? 'ALL' : $p->{bl} , $p->{id} );
}

sub is_in_active_job {
    my ($self, $ns )=@_;
    
    my $rs = Baseliner->model('Baseliner::BaliJobItems')->search({ item=> $ns }, { order_by => { '-desc' => 'id_job.id' }, prefetch=>['id_job'] });
    while( my $r = $rs->next ) {
        if(  $r->id_job->is_active ) {
            return $r->id_job;
        }
    }
    return undef;
}


1;

__END__

  active: '1'
  bl: IT
  changesets:
  - '6904'
  ci_class: BaselinerX::CI::job
  ci_form: /ci/job.js
  ci_icon: /static/images/icons/job.png
  collection: job
  comments: ~
  endtime: ~
  exec: '1'
  host: localhost
  id: '608'
  id_rule: '125'
  id_stash: ~
  job_key: 30723acbdc9ee6da62dec00ea4a09c75
  mid: '6918'
  moniker: ~
  name: N.IT-00000608
  now: '0'
  ns: /
  owner: ~
  pid: ~
  request_status: ~
  rollback: '0'
  runner: service.job.runner.rule
  schedtime: 2013-09-06 19:29:34
  starttime: 2013-09-06 19:29:34
  maxstarttime: 2013-09-07 19:29:34
  status: READY
  step: PRE
  ts: 2013-09-06 19:29:34
  type: promote
  username: root
  versionid: '1'

