package Clarive::Cmd::smoke;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

use File::Copy qw(copy);
use Capture::Tiny qw(tee_merged);

our $CAPTION = 'Smoke';

sub run {
    my $self = shift;
    my (%opts) = @_;

    my $smoke_env             = 'smoke';
    my $smoke_db              = 'test_smoke';
    my $smoke_port            =  50000 + (int(rand()*1500) + abs($$)) % 1500;
    my $smoke_conf            = "config/$smoke_env.yml";
    my $smoke_nightwatch_conf = 'ui-tests/smoke.json';

    if (!%{$opts{args}}) {
        $opts{args}->{unit} = 1;
        $opts{args}->{ui} = 1;
    }

    print 'Running smoke tests...', "\n";

    my $unit_exit = 0;

    if ($opts{args} && $opts{args}->{unit}) {
        print "\n";
        print "#" x 80, "\n";
        print "# UNIT TESTS ", "\n";
        print "#" x 80, "\n\n";

        $unit_exit = _system("cla prove");
    }

    my $ui_exit = 0;
    if ($opts{args} && $opts{args}->{ui}) {
        copy 't/data/acmetest.yml', $smoke_conf;
        replace_inplace(
            $smoke_conf,
            qr{dbname: acmetest},
            qq{dbname: $smoke_db}
        );
        replace_inplace(
            $smoke_conf,
            qr{port: \d+},
            qq{port: $smoke_port}
        );

        print "\n";
        print "#" x 80, "\n";
        print "# STARTING WEB SERVER", "\n";
        print "#" x 80, "\n\n";

        _system("cla web-stop --env $smoke_env --port $smoke_port");

        local $ENV{CLARIVE_TEST} = 1;
        local $ENV{CLARIVE_ENV}  = $smoke_env;

        _system("cla web-start --env $smoke_env --port $smoke_port --daemon --init --migrate-yes");

        sleep 5;

        print "\n";
        print "#" x 80, "\n";
        print "# UI TESTS ", "\n";
        print "#" x 80, "\n\n";

        my ($stdout) = tee_merged {
            $ENV{TEST_SELENIUM_HOSTNAME} = "localhost:$smoke_port";
            $ui_exit = _system("cla proveui");
        };

        $ui_exit = 255 if $stdout =~ m/TEST FAILURE/;

        print "\n";
        print "#" x 80, "\n";
        print "# STOPPING WEB SERVER", "\n";
        print "#" x 80, "\n\n";

        _system("cla web-stop --env $smoke_env --port $smoke_port");
    }

    print "\n";

    die "ERROR: Unit tests failed\n" if $unit_exit;
    die "ERROR: UI tests failed\n"   if $ui_exit;

    print "SUCCESS: No smoke detected!\n";
}

sub replace_inplace {
    my ($file, $pattern, $replace) = @_;

    my $input = slurp($file);

    my $output = $input;
    $output =~ s/$pattern/$replace/gsm;

    open my $fh, '>', $file or die $!;
    print $fh $output;
    close $fh;
}

sub slurp {
    my ($file) = @_;

    local $/;
    open my $fh, '<', $file or die $!;
    return <$fh>;
}

sub _system {
    my ($cmd) = @_;

    warn "$cmd\n";

    return system($cmd);
}

1;
__END__

=head1 Smoke

Common options:

=cut
