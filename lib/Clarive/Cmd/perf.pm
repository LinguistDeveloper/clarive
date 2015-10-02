package Clarive::Cmd::perf;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION = 'Perf';

use IO::Handle;
use Socket;
use WWW::Mechanize;
use Time::HiRes qw(gettimeofday tv_interval);
use Baseliner::Utils qw(_load);
use Baseliner::RequestRecorder::Vars;

sub run {
    my $self = shift;
    my (%opts) = @_;

    die "--file is required\n" unless my $file = $opts{args}->{file};

    my $forks                = $opts{args}->{forks} || 1;
    my $time                 = $opts{args}->{time};
    my $loop                 = $time ? -1 : ( $opts{args}->{loop} || 1 );
    my $with_request_details = !!$opts{args}->{'with-request-details'};
    my $with_group_details   = !!$opts{args}->{'with-group-details'};

    my $vars_by_fork  = {};
    my $vars_by_group = {};

    open my $fh, '<', $file or die "Can't open file '$file': $!\n";
    my @cases = split /\s*\*\*\* \d+\.\d+ \*\*\*\s*/ms, do { local $/; <$fh> };
    close $fh;

    print 'Parsing scenarios...';

    my @scenarios;
    foreach my $case (@cases) {
        next unless $case;

        push @scenarios, _load $case;
    }

    print "done\n\n";

    my @pairs;
    my %pids;

    print "Forking....";

    for my $fork ( 1 .. $forks ) {
        socketpair( my $child, my $parent, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
          || die "socketpair: $!";

        $child->autoflush(1);
        $parent->autoflush(1);

        push @pairs,
          {
            child  => $child,
            parent => $parent
          };

        if (my $eval_file = $opts{args}->{'vars-eval'}) {
            my $eval_cb = do $eval_file or die $@;

            $vars_by_fork->{$fork} = ref $eval_cb eq 'CODE' ? $eval_cb->($fork) : $eval_cb;

            if (my $group = $vars_by_fork->{$fork}->{-group}) {
                $vars_by_group->{$group} = {%{$vars_by_fork->{$fork}}};
                delete $vars_by_group->{$group}->{-group};
            }
        }
    }

    my $id = 1;
    foreach my $pair (@pairs) {
        if ( my $pid = fork ) {
            close $pair->{parent};

            $pair->{pid} = $pid;
        }
        else {
            die "cannot fork: $!" unless defined $pid;

            close $pair->{child};

            my $parent_fh = $pair->{parent};

            print $parent_fh "READY\n";

            while ( defined( my $line = <$parent_fh> ) ) {
                if ( $line =~ m/GO/ ) {
                    last;
                }
            }

            eval {
                $self->_do(
                    $parent_fh,
                    id        => $id,
                    scenarios => \@scenarios,
                    loop      => $loop,
                    vars      => $vars_by_fork->{$id}
                );

                1;
            } or do {
                warn $@;
            };

            print $parent_fh "DONE\n";
            close $parent_fh;

            exit(0);
        }

        $id++;
    }

    $SIG{INT} = sub {
        print "Killing children...";

        $self->_kill_children( \%pids );

        print "done\n\n";
    };
    $SIG{CHLD} = sub { };

    foreach my $pair (@pairs) {
        my $child_fh = $pair->{child};

        chomp( my $line = <$child_fh> );

        if ( $line =~ m/READY/ ) {
            $pids{ $pair->{pid} } = $pair;

            next;
        }
    }

    print "done\n\n";

    foreach my $pid ( keys %pids ) {
        my $child_fh = $pids{$pid}->{child};

        print $child_fh "GO\n";
    }

    $self->_benchmark(
        \%pids,
        forks                => $forks,
        time                 => $time,
        scenarios            => \@scenarios,
        vars_by_group        => $vars_by_group,
        vars_by_fork         => $vars_by_fork,
        with_request_details => $with_request_details,
        with_group_details   => $with_group_details,
    );
}

sub _benchmark {
    my $self = shift;
    my ($pids, %params) = @_;

    my $start                           = [gettimeofday];
    my $total_elapsed                   = 0;
    my $total_elapsed_per_request       = {};
    my $total_elapsed_per_group_request = {};
    my $scenarios                       = 0;
    my $requests                        = 0;
    my $failed_requests                 = 0;

    my $with_request_details = $params{with_request_details};
    my $with_group_details   = $params{with_group_details};
    my $vars_by_fork         = $params{vars_by_fork};
    my $vars_by_group        = $params{vars_by_group};

    print "Benchmarking (be patient)....";

    eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        if ($params{time}) {
            alarm $params{time};
        }

        while (%$pids) {
            foreach my $pid ( keys %$pids ) {
                my $pair = $pids->{$pid};

                my $child_fh = $pair->{child};
                next unless $child_fh;

                my $is_done;

                my $read = sysread($child_fh, my $buffer, 4096);

                while ( $buffer =~ m/(.*?)\n/g ) {
                    my $line = $1;

                    if ( $line =~ m/DONE/ ) {
                        $is_done = 1;

                        last;
                    }
                    elsif ( $line =~ m/REQUEST SUCCESS/ ) {
                        $requests++;
                    }
                    elsif ( $line =~ m/REQUEST FAILED/ ) {
                        $failed_requests++;
                    }
                    elsif ( $line =~ m/REQUEST=(.*?) ELAPSED=(.*) GROUP=(.*)/ ) {
                        $total_elapsed_per_request->{$1}->{elapsed} += $2;
                        $total_elapsed_per_request->{$1}->{requests}++;

                        $total_elapsed_per_group_request->{$3}->{$1}->{elapsed} += $2;
                        $total_elapsed_per_group_request->{$3}->{$1}->{requests}++;

                        $total_elapsed += $2;
                    }
                    elsif ( $line =~ m/SCENARIO/ ) {
                        $scenarios++;
                    }
                    else {
                        warn "UNKNOWN $line";
                    }
                }

                next unless $is_done;

                close $child_fh;

                waitpid( $pair->{pid}, 0 );

                delete $pids->{$pid};
            }
        }

        alarm(0);
    };
    if ($@) {
        die unless $@ eq "alarm\n";

        $self->_kill_children($pids);
    }

    my $elapsed = sprintf( '%0.3f', tv_interval($start));
    my $rps = $self->_calculate_rps( $requests, $total_elapsed );
    my $tpr = $self->_calculate_tpr( $total_elapsed, $requests );

    print "done\n\n";

    print <<"";
    Concurrency level:        $params{forks}
    Time taken for tests:     $elapsed [s]
    Time taken for requests:  $total_elapsed [s]
    Complete scenarios:       $scenarios
    Complete requests:        $requests
    Failed requests:          $failed_requests
    Requests per second:      $rps [#/s]
    Time per request:         $tpr [s]

    print "\n\n";

    if ($with_request_details) {
        print "Per request statistics:\n\n";

        my $stats_by_order = [sort { $a <=> $b } keys %$total_elapsed_per_request];
        $self->_per_request_info($stats_by_order, $total_elapsed_per_request, $params{scenarios});

        print "\n\n";
        print "Ordered by elapsed time\n\n";

        my $stats_by_elapsed =
          [ sort { $total_elapsed_per_request->{$b}->{elapsed} <=> $total_elapsed_per_request->{$a}->{elapsed} }
              keys %$total_elapsed_per_request ];
        $self->_per_request_info($stats_by_elapsed, $total_elapsed_per_request, $params{scenarios});

        print "\n\n";
    }

    if ($with_group_details && keys %{$total_elapsed_per_group_request} > 1) {
        print "Statistics by groups\n\n";

        foreach my $group (sort keys %{$total_elapsed_per_group_request}) {
            print "Group: $group\n\n";

            print "    Variables:\n\n";
            foreach my $var (sort keys %{$vars_by_group->{$group}}) {
                my $value = $vars_by_group->{$group}->{$var};
                $value = '******' if $var eq 'password';
                print "        $var: '$value'\n";
            }
            print "\n\n";

            my $total_group_requests = 0;
            my $total_group_elapsed = 0;
            foreach my $index (keys %{$total_elapsed_per_group_request->{$group}}) {
                my $request = $total_elapsed_per_group_request->{$group}->{$index};

                $total_group_elapsed += $request->{elapsed};
                $total_group_requests++;
            }

            my $rps = $self->_calculate_rps( $total_group_requests, $total_group_elapsed );
            my $tpr = $self->_calculate_tpr( $total_group_elapsed, $total_group_requests );

            my $forks = 0;
            foreach my $fork_id (keys %$vars_by_fork) {
                my $fork_vars = $vars_by_fork->{$fork_id};
                $forks++ if $fork_vars->{-group} && $fork_vars->{-group} eq $group;
            }

            print <<"";
    Concurrency level:        $forks
    Time taken for requests:  $total_group_elapsed [s]
    Complete requests:        $total_group_requests
    Requests per second:      $rps [#/s]
    Time per request:         $tpr [s]

            print "\n\n";

            my $stats_by_order = [sort { $a <=> $b } keys %{$total_elapsed_per_group_request->{$group}}];
            $self->_per_request_info($stats_by_order, $total_elapsed_per_request, $params{scenarios});

            print "\n\n";
        }
    }
}

sub _calculate_rps {
    my $self = shift;
    my ($requests, $elapsed) = @_;

    return sprintf( '%0.3f', $elapsed ? $requests / $elapsed : 0 );
}

sub _calculate_tpr {
    my $self = shift;
    my ($elapsed, $requests) = @_;

    return sprintf( '%0.3f', $requests ? $elapsed / $requests: 0);
}

sub _per_request_info
{
    my $self = shift;
    my ($stats, $timings, $scenarios) = @_;

    print "        Elapsed [s]  Requests per second [#/s]  Time per request [s]  URL\n\n";
    foreach my $index (@$stats) {
        my $number  = sprintf '%3d',  $index + 1;
        my $elapsed = sprintf '%7.03f', $timings->{$index}->{elapsed};
        my $requests = $timings->{$index}->{requests};

        my $rps = sprintf( '%18.03f', $elapsed  ? $requests / $elapsed : 0 );
        my $tpr = sprintf( '%25.03f', $requests ? $elapsed / $requests : 0 );

        my $data = $scenarios->[$index];
        my $env = $data->{request}->{env};

        my $method = $env->{REQUEST_METHOD};
        $method .= ' ' if length $method < 4;
        my $info = "$method $env->{PATH_INFO}";
        $info .= "?$env->{QUERY_STRING}" if length $env->{QUERY_STRING};

        print "   $number: $elapsed $rps $tpr           $info\n";
    }
}

sub _kill_children
{
    my $self = shift;
    my ($pids) = @_;

    while (%$pids) {
        foreach my $pid (keys %$pids) {
            kill 1, $pid;

            waitpid( $pid, 0 );

            #print $pid, ' ';

            delete $pids->{$pid};
        }
    }
}

sub _do {
    my $self = shift;
    my ( $fh, %params ) = @_;

    my $id    = $params{id};
    my $datas = $params{scenarios};

    my $mech = WWW::Mechanize->new( onerror => sub { } );

    my $group = delete $params{vars}->{'-group'} || 'default';
    my $vars = Baseliner::RequestRecorder::Vars->new(vars => $params{vars}, quiet => 1);
    while (1) {
        my $request_num = 0;
        foreach my $data (@$datas) {
            my $env = $data->{request}->{env};

            my $url = "http://$env->{SERVER_NAME}:$env->{SERVER_PORT}$env->{PATH_INFO}";
            $url .= "?$env->{QUERY_STRING}" if length $env->{QUERY_STRING};
            my $method = $env->{REQUEST_METHOD};

            $url = $vars->replace_vars($url);

            my @params;
            if ( $method eq 'POST' ) {
                my $body = $vars->replace_vars($data->{request}->{body});
                push @params, Content => $body;
            }

            if ( my $with = $env->{'HTTP_X_REQUESTED_WITH'} ) {
                push @params, 'X-Requested-With' => $with;
            }

            if ( my $content_type = $env->{'CONTENT_TYPE'} ) {
                push @params, 'Content-Type' => $content_type;
            }

            my $mech_method = lc $method;

            my $request_time = [gettimeofday];

            my $response = $mech->$mech_method( $url, @params );
            if ( $response->code =~ m/^5/ ) {
                print $fh "REQUEST FAILED\n";
            }
            else {
                print $fh "REQUEST SUCCESS\n";
            }

            my $request_elapsed = tv_interval($request_time);

            print $fh "REQUEST=$request_num ELAPSED=$request_elapsed GROUP=$group\n";

            if (my $captures = $data->{response}->{captures}) {
                $vars->extract_captures($captures, $response->content);
            }

            $request_num++;
        }

        print $fh "SCENARIO\n";

        if ($params{loop} != -1) {
            $params{loop}--;

            last unless $params{loop};
        }
    }
}

1;
__END__

=head1 Perf

Common options:

    --file <file>           file to replay
    --loop <loop>           how many times to run a scenario
    --forks <forks>         parallel requests
    --time <time>           seconds to run the tests
    --vars-eval <file>      file to run for getting vars

    --with-request-details  show statistics by every request
    --with-group-details    show statistics by every group

Details

    For capturing and settings variables see `replay` documentation.

    Grouping
    --------

    If it is needed to group the forks for displaying more
    granular statistics one can set a special `-group` variable.

        sub {
            my ($fork_id) = @_;

            my $vars = {};

            if ( $fork_id == 1 ) {
                $vars->{-group}   = 'admin user';
                $vars->{login}    = 'admin';
                $vars->{password} = 'password';
            }
            else {
                $vars->{-group}   = 'normal user';
                $vars->{login}    = 'user';
                $vars->{password} = 'password';
            }

            return $vars;
          }

=cut
