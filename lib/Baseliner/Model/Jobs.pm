package Baseliner::Model::Jobs;
use Moose;
BEGIN { extends 'Catalyst::Model' }

use namespace::clean;
use Compress::Zlib;
use Archive::Tar;
use Path::Class;
use Try::Tiny;
use Data::Dumper;
use Class::Date;
use experimental 'autoderef', 'smartmatch';

use Baseliner::Core::Registry ':dsl';
use Baseliner::Sugar;
use Baseliner::Model::Permissions;
use Baseliner::Utils;

register 'action.search.job' => { name => 'Search jobs' };

register 'event.job.rerun' => { name=>'Rerun a job', notify=>{ scope=>['project','bl'] }  };
register 'event.job.reschedule' => { name=>'Reschedule a job', notify=>{ scope=>['project','bl'] }  };
register 'event.job.start' => { name=>'Job start', notify=>{ scope=>['project','bl'] } };
register 'event.job.start_step' => { name=>'Job step start', notify=>{ scope=>['project','bl'] } };
register 'event.job.end' => { name=>'Job end, after POST', notify=>{ scope=>['project','bl','status'] } };
register 'event.job.end_step' => { name=>'Job step end', notify=>{ scope=>['project','bl','status'] } };

our $group_keys = {
    id           => 'jobid',
    mid          => 'mid',
    name         => 'name',
    bl           => 'bl',
    bl_text      => 'bl',
    ts           => 'ts',
    starttime    => 'starttime',
    schedtime    => 'schedtime',
    maxstarttime => 'maxstarttime',
    endtime      => 'endtime',
    when         => 'schedtime',
    comments     => 'comments',
    username     => 'username',
    rollback     => 'rollback',
    has_errors   => 'has_errors',
    has_warnings => 'has_warnings',
    key          => 'job_key',
    step_code    => 'step',
    exec         => 'exec',
    pid          => 'pid',
    owner        => 'owner',
    host         => 'host',
    status_code  => 'status',
    status       => 'status',
    type_raw     => 'job_type',
    type         => 'job_type',
    runner       => 'runner',
    id_rule      => 'id_rule',
    contents     => 'list_contents',
    changesets   => 'job_contents.list_changesets',
    releases     => 'job_contents.list_releases',
    applications => 'job_contents.list_apps',
    natures      => 'job_contents.list_natures'
};

sub monitor {
    my ( $self, $p ) = @_;

    my $username = $p->{username};

    my ( $start, $limit, $query, $query_id, $dir, $sort, $filter, $groupby, $groupdir, $cnt )
        = @{$p}{qw/start limit query query_id dir sort filter groupBy groupDir/};
    $start ||= 0;
    $limit ||= 50;
    $groupby //= '';

    $sort ||= 'starttime';
    $dir = !$dir ? -1 : lc $dir eq 'desc' ? -1 : 1;

    my @order_by;
    if ( length($groupby) ) {
        $groupdir = $groupdir eq 'ASC' ? 1 : -1;
        @order_by = (
            $group_keys->{$groupby} => ( $groupby eq 'when' ? -1 : $groupdir ),
            $group_keys->{$sort} => $dir
        );
    }
    else {
        @order_by = ( $group_keys->{$sort} => $dir );
    }

    $start = $p->{next_start} if $p->{next_start} && $start && $query;

    my $page = to_pages( start => $start, limit => $limit );

    my $where = {};
    my @mid_filters;
    if ( length($query) ) {
        _debug "Job QUERY=$query";
        my @mids_query;
        if ( $query !~ /\+|\-|\"|\:/ ) {
            $query =~ s{(\w+)\*}{job "$1"}g;
            $query =~ s{([\w\-\.]+)}{"$1"}g;
            $query =~ s{\+(\S+)}{"$1"}g;
            $query =~ s{""+}{"}g;
            @mids_query = map { $_->{obj}{mid} } _array(
                mdb->master_doc->search(
                    query   => $query,
                    limit   => 1000,
                    project => { mid => 1 },
                    filter  => { collection => 'job' }
                )->{results}
            );
        }
        if ( !@mids_query ) {
            mdb->query_build( where => $where, query => $query, fields => [ keys %$group_keys ] );
        }
        else {
            push @mid_filters, { mid => mdb->in(@mids_query) };
        }
    }

    my $permissions = Baseliner::Model::Permissions->new;

    if ( !$permissions->is_root($username) ) {
        my $user  = ci->user->find_one( { name => $username } );
        my @roles = keys $user->{project_security};
        my @bl    = map {
            map { $_->{bl} }
                grep { $_->{bl} if ( $_->{action} eq 'action.job.viewall' ) }
                _array( $_->{actions} )
        } mdb->role->find( { id => { '$in' => \@roles } } )->fields( { actions => 1, _id => 0 } )->all if (@roles);
        my @ids_project = $permissions->user_projects_with_action(
            username => $username,
            action   => 'action.job.viewall',
            level    => 1,
            bl       => \@bl
        );

        $where->{bl} = mdb->in(@bl) if ( @bl && !( '*' ~~ @bl ) );
        $where->{projects} = mdb->in( sort @ids_project );
    }

    if ( length $p->{job_state_filter} ) {
        my @job_state_filters = do {
            my $job_state_filter = Util->_decode_json( $p->{job_state_filter} );
            _unique grep { $job_state_filter->{$_} } keys %$job_state_filter;
        };
        $where->{status} = mdb->in( \@job_state_filters );
    }

    if ( length $p->{filter_nature} ) {
        $where->{natures} = mdb->in( _array( $p->{filter_nature} ) );
    }

    if ( length $p->{filter_bl} ) {
        $where->{bl} = $p->{filter_bl};
    }

    if ( length $p->{filter_type} ) {
        $where->{job_type} = $p->{filter_type};
    }

    $query_id ||= '';
    if ( $query_id ne '-1' ) {
        my @jobs = split( ",", $query_id );
        $where->{'mid'} = mdb->in( \@jobs );
    }

    $where->{'$and'} = \@mid_filters if @mid_filters;

    if ($filter) {
        $filter = Util->_decode_json($filter);
        my $where_filter = {};
        for my $fi ( _array($filter) ) {
            my $val = $fi->{value};
            if ( $fi->{type} eq 'date' ) {
                $val = Class::Date->new($val)->string;
                my $oper = $fi->{comparison};
                if ( $oper eq 'eq' ) {
                    $where_filter->{ $fi->{field} }
                        = { '$gt' => $val, '$lt' => ( Class::Date->new($val) + '1D' )->string };
                }
                else {
                    $where_filter->{ $fi->{field} }{ '$' . $oper } = $val;
                }
            }
            elsif ( $fi->{type} eq 'string' ) {
                $where_filter->{ $fi->{field} } = qr/$val/i;
            }
        }
        $where = { %$where, %$where_filter };
    }

    my $rs = mdb->master_doc->find( { collection => 'job', %$where } )->sort( mdb->ixhash(@order_by) );

    if ( $p->{list_only} ) {
        return ( 0, $rs->fields( { mid => 1 } )->next );
    }

    $cnt = $rs->count;
    $rs->limit($limit)->skip($start) unless $limit eq -1;

    my %rule_names = map { $_->{id} => $_ } mdb->rule->find->fields({ id=>1, rule_name=>1 })->all;

    my @rows;
    my $now = _dt();
    my $today = DateTime->new( year=>$now->year, month=>$now->month, day=>$now->day, , hour=>0, minute=>0, second=>0);
    my $ahora = DateTime->new( year=>$now->year, month=>$now->month, day=>$now->day, , hour=>$now->hour, minute=>$now->minute, second=>$now->second );

    local $Baseliner::CI::mid_scope = {};

    for my $job ( $rs->all ) {
        my $step             = _loc( $job->{step} );
        my $status           = _loc( $job->{status} );
        my $type             = _loc( $job->{job_type} );
        my @changesets       = ();
        my $job_contents     = $job->{job_contents} // {};
        my $last_log_message = $job->{last_log_message};

        my $when = '';
        my $day;
        my $sdt = parse_dt( '%Y-%m-%d %H:%M:%S', $job->{starttime} // $job->{ts} );
        my $dur = $today - $sdt;
        $sdt->{locale} = DateTime::Locale->load( $p->{language} || 'en' );
        $day
            = $dur->{months} > 3 ? [ 90, _loc('Older') ]
            : $dur->{months} > 2 ? [ 80, _loc( '%1 Months', 3 ) ]
            : $dur->{months} > 1 ? [ 70, _loc( '%1 Months', 2 ) ]
            : $dur->{months} > 0 ? [ 60, _loc( '%1 Month',  1 ) ]
            : $dur->{days} >= 21 ? [ 50, _loc( '%1 Weeks',  3 ) ]
            : $dur->{days} >= 14 ? [ 40, _loc( '%1 Weeks',  2 ) ]
            : $dur->{days} >= 7  ? [ 30, _loc( '%1 Week',   1 ) ]
            : $dur->{days} == 6  ? [ 7,  _loc( $sdt->day_name ) ]
            : $dur->{days} == 5  ? [ 6,  _loc( $sdt->day_name ) ]
            : $dur->{days} == 4  ? [ 5,  _loc( $sdt->day_name ) ]
            : $dur->{days} == 3  ? [ 4,  _loc( $sdt->day_name ) ]
            : $dur->{days} == 2  ? [ 3,  _loc( $sdt->day_name ) ]
            : $dur->{days} == 1  ? [ 2,  _loc( $sdt->day_name ) ]
            : $dur->{days} == 0  ? $sdt < $today
                ? [ 2, _loc( $sdt->day_name ) ]
                : $sdt > $ahora ? [ 0, _loc('Upcoming') ]
            : [ 1, _loc('Today') ]
            : [ 0, _loc('Upcoming') ];
        $when = $day->[0];
        my ($last_exec) = sort { $b cmp $a } keys %{ $job->{milestones} };

        my $can_restart
            = $permissions->user_has_action( username => $username, action => 'action.job.restart', bl => $job->{bl} );
        my $can_cancel
            = $permissions->user_has_action( username => $username, action => 'action.job.cancel', bl => $job->{bl} );
        my $can_delete
            = $permissions->user_has_action( username => $username, action => 'action.job.delete', bl => $job->{bl} );

        push @rows,
            {
            id        => $job->{jobid},
            mid       => $job->{mid},
            name      => $job->{name},
            bl        => $job->{bl},
            bl_text   => $job->{bl},
            ts        => $job->{ts},
            starttime => ( $groupby eq 'starttime' ? substr( $job->{starttime}, 0, 10 ) : $job->{starttime} ),
            schedtime => ( $groupby eq 'schedtime' ? substr( $job->{schedtime}, 0, 10 ) : $job->{schedtime} ),
            maxstarttime =>
                ( $groupby eq 'maxstarttime' ? substr( $job->{maxstarttime}, 0, 10 ) : $job->{maxstarttime} ),
            endtime => ( $groupby eq 'endtime' ? substr( $job->{endtime}, 0, 10 ) : $job->{endtime} ),
            comments            => $job->{comments},
            username            => $job->{username},
            rollback            => $job->{rollback},
            has_errors          => $job->{has_errors},
            has_warnings        => $job->{has_warnings},
            approval_expiration => $job->{maxapprovaltime},
            key                 => $job->{job_key},
            last_log            => $last_log_message,
            when                => $when,
            ago                 => Util->ago( $job->{schedtime} ),
            day                 => ucfirst( $day->[1] ),
            step                => $step,
            step_code           => $job->{step},
            exec                => $job->{'exec'},
            pid                 => $job->{pid},
            owner               => $job->{owner},
            host                => $job->{host},
            status              => $status,
            status_code         => $job->{status},
            type_raw            => $job->{job_type},
            type                => $type,
            runner              => $job->{runner},
            job_family          => $job->{job_family} || 'pipeline',
            id_rule             => $job->{id_rule},
            rule_name           => _loc( 'Rule: %1 (%2)', $rule_names{ $job->{id_rule} }{rule_name}, $job->{id_rule} ),
            contents => [ _array( $job_contents->{list_releases}, $job_contents->{list_changesets} ) ],
            changesets    => $job_contents->{list_changesets}    || [],
            changeset_cis => $job_contents->{list_changeset_cis} || [],
            cs_comments   => $job_contents->{cs_comments}        || {},
            releases      => $job_contents->{list_releases}      || [],
            applications  => $job_contents->{list_apps}          || [],
            natures       => $job_contents->{list_natures}       || [],
            pre_start => $last_exec ? $job->{milestones}->{$last_exec}->{PRE}->{start} || " " : " ",
            pre_end   => $last_exec ? $job->{milestones}->{$last_exec}->{PRE}->{end}   || " " : " ",
            run_start => $last_exec ? $job->{milestones}->{$last_exec}->{RUN}->{start} || " " : " ",
            run_end   => $last_exec ? $job->{milestones}->{$last_exec}->{RUN}->{end}   || " " : " ",
            can_restart => $can_restart,
            can_cancel  => $can_cancel,
            can_delete  => $can_delete,
            progress    => $self->_calculate_progress($job),
            };
    }
    return ( $cnt, @rows );
}

sub _calculate_progress {
    my $self = shift;
    my ($job) = @_;

    return '100%' if $job->{status} eq 'FINISHED';

    my $progress = 'n/a';

    my $rule = mdb->rule->find_one({id => "$job->{id_rule}"});
    if ($rule) {
        my $rule_tree_json = $rule->{rule_tree};
        my $rule_tree = Util->_decode_json( $rule_tree_json );

        my $total = 0;
        foreach my $step (@$rule_tree) {
            $total += @{ $step->{children} };
        }

        my $now = mdb->job_log->find(
            {
                mid        => $job->{mid},
                lev        => 'debug',
                stmt_level => 1,
            }
        )->count;

        if ($total) {
            my $percentage = int(($now / $total) * 100);
            $progress = " $percentage% ($now/$total)";
        }
    }

    return $progress;
}


with 'Baseliner::Role::Search';
with 'Baseliner::Role::Service';

sub search_provider_name { 'Jobs' };
sub search_provider_type { 'Job' };
sub search_query {
    my ($self, %p ) = @_;

    $p{limit} //= 100;
    $p{query_id} = -1;
    my ($cnt, @rows ) = Baseliner->model('Jobs')->monitor(\%p);
    return map {
        my $r = $_;
        #my $summary = join ',', map { "$_: $r->{$_}" } grep { defined $_ && defined $r->{$_} } keys %$r;
        my @text =
            grep { length }
            map { "$_" }
            map { _array( $_ ) }
            grep { defined }
            map { $r->{$_} }
            keys %$r;
        chomp @text;
        +{
            title => $r->{name},
            info  => $r->{ts},
            text  => join(', ', @text ),
            url   => [ $r->{mid}, $r->{name}, undef, undef, '/static/images/icons/job.svg' ],
            type  => 'log'
        }
    } @rows;
}

sub get {
    my ($self, $id ) = @_;
    my $where = $id =~ /^[0-9]+$/ ? {jobid => "$id"} : {name => "$id"};
    return ci->job->find_one($where);
}

sub status {
    my ($self,%p) = @_;
    my $jobid = $p{jobid} or _throw 'Missing jobid';
    my $status = $p{status} or _throw 'Missing status';
    my $job = ci->find( ns=>'job/'.$jobid );
    $job->status( $status );
    $job->save;
}

sub export {
    my ($self,%p) = @_;
    exists $p{mid} or _throw 'Missing job id';
    return eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 60;
        $p{format} ||= 'raw';
        my $job = ci->new( $p{mid} ) or _throw "Job id $p{id} not found";

        my $data = _dump({ job=>$job });
        alarm 0;
        return $data if $p{format} eq 'raw';
        return compress($data) if $p{format} eq 'zip';

        my $tar = Archive::Tar->new or _throw $!;
        # dump
        $tar->add_data( 'data.txt', $data );
        # job files
        my $name = $job->{name};
        my $inf = Baseliner->model('ConfigStore')->get( 'config.job.runner' );
        my $job_dir = File::Spec->catdir( $inf->{root}, $name );
        if( -e $job_dir ) {
            #$tar->setcwd( $inf->{root} );
            my @files;
            Path::Class::dir( $job_dir )->recurse(callback=>sub{
                my $f = shift;
                return if $f->is_dir;
                push @files, "" . $f->relative($inf->{root});
            });
            chdir $inf->{root};
            $tar->add_files( @files );
        }
        my $tmpfile = File::Spec->catdir( $inf->{root}, "job-export-$name.tgz" );
        return $tar->write unless $p{file};
        $tar->write($tmpfile,COMPRESS_GZIP);;
        return $tmpfile;
    };
    if( $@ eq "alarm\n" ) {
        _log "*** Job export timeout: $p{id}";
    }
    return undef;
}


sub get_contents {
    my ( $self, %p ) = @_;
    defined $p{jobid} or _throw "Missing jobid";
    my $result;

    my $job = _ci( ns=>'job/' . $p{jobid} );
    my $job_stash = $job->job_stash;
    my @changesets = _array( $job->changesets );
    my $changesets_by_project = {};
    my @natures = map { $_->name } _array( $job->natures );
    my $items = $job_stash->{items};
    for my $cs ( @changesets ) {
        my @projs = _array $cs->projects;
        push @{ $changesets_by_project->{$  projs[0]->{name}} }, $cs;
    }
    $result = {
        packages => $changesets_by_project,
        items => $items,
        technologies => \@natures,
    };

    return $result;

} ## end sub get_contents

sub user_can_search {
    my ($self, $username) = @_;
    return Baseliner::Model::Permissions->user_has_action( username => $username, action => 'action.search.job');
}

sub build_field_query {
    my ($self,$query,$where) = @_;
    mdb->query_build( where=>$where, query=>$query, fields=>['name', 'bl','final_status', 'final_step', 'list_contents','username','job_contents.list_apps', 'job_contents.list_changesets', 'job_contents.list_natures', 'job_contents.list_releases'] );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
