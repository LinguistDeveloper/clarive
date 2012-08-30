package BaselinerX::ChangemanController;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' };

__PACKAGE__->config->{namespace} = 'changeman';

register 'menu.admin.changeman' => {label   => 'Changeman Utils',
                               url_comp     => '/changeman/main.js',
                               title   => 'Changeman Utils',
                               icon    => '/changeman/chm.gif',
                             # actions => ['action.job.create'],
                               action  => 'action.job.create'};
sub commands : Local {
    my ($self,$c) = @_;
    my @data;
    my $p = $c->req->params;
    $c->stash->{ json } = \@data;
    $c->forward( 'View::JSON' );
}

sub files : Local {
    my ($self,$c) = @_;
    use Class::Date;
    my $p = $c->req->params;
    my $query = $p->{query};
    my $sort = $p->{'sort'};
    my $dir = $p->{'dir'} eq 'ASC' ? 1 : -1;

    my @files = BaselinerX::ChangemanUtils->spool_files();
    if( length $query ) {
        $query = qr/$query/i;
        @files = grep { $_->{filename} =~ $query } @files;
    }
    my @data = map {
        my $fn = delete $_->{filename}; 
        my $path = $fn->basename ."";
        my $id = _md5( $path );  # add security to file request
        my $date = $_->{date} gt 0 ? "".Class::Date::date($_->{date}) : '-';
        { bl=>$_->{bl}, app=>$_->{app}, date=>$date, id=>$id, path=> $path,
            mdate => "$_->{mdate}",  # it's a Class::Date
            jobname=>$_->{jobname}, ord=>$_->{ord} }
    } @files; 
    if( $sort eq 'path' && $dir < 0 ) {
        @data = reverse @data;
    } 
    elsif( $sort ne '' ) {
        @data = sort {
            $dir * ( $a->{$sort} cmp $b->{$sort} ) 
        } @data;
    }
    $c->stash->{ json } = { data=>\@data, totalCount=>scalar @data };
    $c->forward( 'View::JSON' );
}

sub file_retrieve : Local {
    my ($self,$c, $fileid) = @_;
    my $p = $c->req->params;

    try {
        my @files = BaselinerX::ChangemanUtils->spool_files();
        @files = grep {
            my $path = $_->{filename}->basename ."";
            $fileid eq _md5( $path )
        } @files; 
        _fail _loc("File id not found: %1", $fileid ) unless @files;
        my $fn = $files[0]->{filename}->basename ;
        _debug "Chm filename retrieve = $fn";
        my $data = BaselinerX::ChangemanUtils->file_retrieve(undef,undef, $fn );
        $c->stash->{ json } = { success=>\1, data=>$data, filename=>"$fn" };
    } catch {
        my $err = shift;
        $c->stash->{ json } = { success=>\0, msg => $err };
    };
    $c->forward( 'View::JSON' );
}

sub file_delete : Local {
    my ($self,$c, $fileid) = @_;
    my $p = $c->req->params;
    my $ids = $p->{ids};

    try {
        # match files to ids
        my @files = BaselinerX::ChangemanUtils->spool_files();
        my @del_files;  # basename of files to delete

        for my $id ( _array $ids ) {
            push @del_files, 
                grep { $id eq _md5( $_ )
                } map { $_->{filename}->basename } @files; 
        }
        _fail _loc("File id not found: %1", $fileid ) unless @del_files;
        my $data = BaselinerX::ChangemanUtils->file_delete(undef,undef, @del_files );
        $c->stash->{ json } = { success=>\1, files=>join(',',@del_files) };
    } catch {
        my $err = shift;
        $c->stash->{ json } = { success=>\0, msg => $err };
    };
    $c->forward( 'View::JSON' );
}

sub events : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my $query = $p->{query};
    my $sort = $p->{'sort'};
    my $dir = $p->{'dir'} eq 'ASC' ? 1 : -1;

    my $repo = $c->model('Baseliner::BaliRepo')->search({ provider=>'changeman.logger' });
    my @evs = map {
        my $r = $_;
        my $data = _load( $r->{data} );
        $r->{msg} = delete $data->{msg} // '-';
        $r->{id} = $r->{ns};
        delete $data->{xml};  # this is big and slow
        delete $data->{data_received};  # big stuff
        delete $data->{logdate};   # ts is enough
        # caller stuff
        my $class = delete $data->{class};
        my $line = delete $data->{line};
        my $file = delete $data->{file};
        my $data_col = do { 
            if( ref $data eq 'HASH' ) {
               [ map {
                   my $v = $data->{$_};
                   my $rr = ref $v;
                   $_ . ': ' . ( $rr eq 'Path::Class::File' ? $v->stringify : $rr ? _dump($v) : $v)
                   }
                  grep { length $data->{ $_ } }
                  keys %{ $data }
               ]
            } else {
                $r->{data}
            }
        };
        { data=>$data_col, ts=>$r->{ts},
            class=>$class, line=>$line, file=>$file,
            msg=>$r->{msg}, id=>$r->{id}, ns=>$r->{ns}
            }
    } $repo->search(undef, { order_by=>{ -desc=>'ts' }, select=>[qw/ns ts data/] })->hashref->all;
    if( length $query ) {
        $query = qr/$query/i;
        @evs = grep { _dump( $_ ) =~ $query } @evs;
    }
    $c->stash->{ json } = { data=>\@evs, totalCount=>scalar @evs };
    $c->forward( 'View::JSON' );
}

# used by package_view also !
sub ns_view : Local {
    my ($self,$c) = @_;
    my $ns = $c->req->params->{ns};

    try {
        my $row = $c->model('Baseliner::BaliRepo')->search({ ns=>$ns }, { select=>'data' } )->first;
        my $data = $row->data;
        $c->stash->{ json } = { success=>\1, data=>$data };
    } catch {
        my $err = shift;
        $c->stash->{ json } = { success=>\0, msg => $err };
    };
    $c->forward( 'View::JSON' );
}

# used by package_delete also !
sub ns_delete : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my $ids = $p->{ids};

    try {
        my $cnt = $c->model('Baseliner::BaliRepo')->search({ ns=>$ids })->delete;
        $c->stash->{ json } = { success=>\1, count=>$cnt };
    } catch {
        my $err = shift;
        $c->stash->{ json } = { success=>\0, msg => $err };
    };
    $c->forward( 'View::JSON' );
}

sub packages : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my $query = $p->{query};
    my $sort = $p->{'sort'};
    my $dir = $p->{'dir'} eq 'ASC' ? 1 : -1;

    my $repo = $c->model('Baseliner::BaliRepo')->search({ provider=>'changeman.package' });
    my @pkgs = map {
        my $r = $_;
        my $data = _load( $r->{data} );
        my $info = {
            map {
                $_ => $data->{ $_ }
            }
            grep /(Entorno|item|user)/,
            keys %{ $data || {} }
        };
        my $ns_data = $data->{ns_data};
        { ns=>$r->{ns}, ts=>$r->{ts}, data=>$ns_data, %$info }
    } $repo->search(undef, { order_by=>{ -desc=>'ts' }, select=>[qw/ns ts data/] })->hashref->all;
    if( length $query ) {
        $query = qr/$query/i;
        @pkgs = grep { _dump( $_ ) =~ $query } @pkgs;
    }
    $c->stash->{ json } = { data=>\@pkgs, totalCount=>scalar @pkgs };
    $c->forward( 'View::JSON' );
}


Baseliner::Sugar::event_hook 'event.job.new' => 'after' => sub {
    my $ev = shift;
    my ($self,$c, $job, $job_data ) = @{ $ev->data }{qw/self c job job_data/};
    my $p = $c->req->params;

    my $items = $job_data->{items};
    my $job_name = $job->name;

    # Linked list to job-options in the stash
    my $ll = $p->{check_linked_list} eq 'on' ? 1 : 0;
    $job->stash_key( chm_linked_list => $ll );

    #Procesamos items de Changeman
    if ($p->{job_contents} =~ m{namespace.changeman.package}g) {
        my $cfgChangeman = Baseliner->model('ConfigStore')->get('config.changeman.connection' );
        my $chm = BaselinerX::Changeman->new( host=>$cfgChangeman->{host}, port=>$cfgChangeman->{port} );
        my $ret= $chm->xml_addToJob(job=>$job_name, items=>$items ) ;
        if ($ret->{ReturnCode} ne '00') {
            $job->delete;
            _fail( _loc( "Error creating Changeman Job:<br>%1",$ret->{Message}) );
        } else {
            ##TODO: Si requiere aprobacion de host por refresco de linklist crear la aprobacion
            # $job->bali_job_items->create({item => 'nature/zos'}); 
            my $log = new BaselinerX::Job::Log({ jobid=>$job->id });
            $log->debug(_loc("Changeman package(s) has been associated to SCM job %1", $job_name ));
        }
    }
};

Baseliner::Sugar::event_hook [qw/event.job.cancel event.job.cancel_running/] => sub {
    my $ev = shift;
    my ($self,$c, $job ) = @{ $ev->data }{qw/self c job /};
    # $c is not available if it comes from Model::Jobs

    my $username = try { $c->username } catch { 'internal' };
    my $job_name = $job->name;

    # CANCELAR JOB EN CHANGEMAN SI PROCEDE
    my $cfgChangeman = Baseliner->model('ConfigStore')->get('config.changeman.connection' );
    my $chm = BaselinerX::Changeman->new( host=>$cfgChangeman->{host}, port=>$cfgChangeman->{port}, key=>$cfgChangeman->{key} );
    my $rs_items = Baseliner->model('Baseliner::BaliJobItems')->search({ id_job=>$job->id, provider =>'namespace.changeman.package' } );
    rs_hashref($rs_items);
    my @pkgs;
    while (my $row=$rs_items->next) {
        my $name=$1 if $row->{item} =~ m{changeman.package/(.*)};
        push @pkgs, $name if $name;
    }

    if (scalar @pkgs) { 
        my $ret= $chm->xml_cancelJob(job=>$job->name, items=>@pkgs) ;
        if ($ret->{ReturnCode} ne '00') {
            my $msg = _loc("Job %1 cancelled", $job_name);
            if( $c ) {
                $c->stash->{json} = { success => \1, msg =>$msg  };
            } else {
                _log $msg;
            }
        } else {
            my $msg = _loc("Job %1 cancelled<br>Changeman package(s) desassociated)", $job_name);
            if( $c ) {
                $c->stash->{json} = { success => \1, msg => $msg  };
            } else {
                _throw $msg; 
            }
        }
        $job->update;
        ## Al cancelar el job, quitamos las relaciones de BaliRelationship
        my $relation=Baseliner->model('Baseliner::BaliRelationship')->search({type=>'Changeman.PDS.to.JobId', to_ns=>"job/".$job->id});
        ref $relation && $relation->delete;

        my $log = new BaselinerX::Job::Log({ jobid=>$job->id });
        $log->error(_loc("Job cancelled by user %1", $username));
    } else {
        $job->update;
        my $log = new BaselinerX::Job::Log({ jobid=>$job->id });
        $log->error(_loc("Job cancelled by user %1", $username));
    }
};

1;
