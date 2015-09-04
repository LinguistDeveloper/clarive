package Clarive::Cmd::perf;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION = 'Perf';

use IO::Handle;
use Socket;
use WWW::Mechanize;
use Time::HiRes qw(gettimeofday tv_interval);
use Baseliner::Utils qw(_load);

sub run {
    my $self = shift;
    my (%opts) = @_;

    die "--file is required\n" unless my $file = $opts{args}->{file};

    my $forks = $opts{args}->{forks} || 1;
    my $time  = $opts{args}->{time};
    my $loop  = $time ? -1 : ($opts{args}->{loop}  || 1);

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

    for ( 1 .. $forks ) {
        socketpair( my $child, my $parent, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
          || die "socketpair: $!";

        $child->autoflush(1);
        $parent->autoflush(1);

        push @pairs,
          {
            child  => $child,
            parent => $parent
          };
    }

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
                $self->_do( $parent_fh, scenarios => \@scenarios, loop => $loop );
            };

            print $parent_fh "DONE\n";
            close $parent_fh;

            exit(0);
        }
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

    $self->_benchmark( \%pids, forks => $forks, time => $time );
}

sub _benchmark {
    my $self = shift;
    my ($pids, %params) = @_;

    my $start = [gettimeofday];
    my $total_elapsed   = 0;
    my $scenarios       = 0;
    my $requests        = 0;
    my $failed_requests = 0;

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
                    elsif ( $line =~ m/REQUEST ELAPSED=(.*)/ ) {
                        $total_elapsed += $1;
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
    my $rps = sprintf( '%0.3f', $total_elapsed ? $requests / $total_elapsed : 0 );
    my $tpr = sprintf( '%0.3f', $requests ? $total_elapsed / $requests: 0);

    print "done\n\n";

    print <<"";
    Concurrency level:        $params{forks}
    Time taken for tests      $elapsed [s]
    Time taken for requests   $total_elapsed [s]
    Complete scenarios        $scenarios
    Complete requests:        $requests
    Failed requests:          $failed_requests
    Requests per second:      $rps [#/s]
    Time per request:         $tpr [s]

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

    my $datas = $params{scenarios};

    my $mech = WWW::Mechanize->new( onerror => sub { } );

    while (1) {
        foreach my $data (@$datas) {
            my $env = $data->{request}->{env};

            my $url = "http://$env->{SERVER_NAME}:$env->{SERVER_PORT}$env->{PATH_INFO}";
            $url .= "?$env->{QUERY_STRING}" if length $env->{QUERY_STRING};
            my $method = $env->{REQUEST_METHOD};

            my @params;
            if ( $method eq 'POST' ) {
                push @params, Content => $data->{request}->{body};
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

            print $fh "REQUEST ELAPSED=$request_elapsed\n";
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

=cut
