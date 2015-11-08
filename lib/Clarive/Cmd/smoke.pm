package Clarive::Cmd::smoke;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

use File::Copy qw(copy);

our $CAPTION = 'Smoke';

sub run {
    my $self = shift;
    my (%opts) = @_;

    my $smoke_env             = 'smoke';
    my $smoke_port            = 9999;
    my $smoke_conf            = "config/$smoke_env.yml";
    my $smoke_nightwatch_conf = 'ui-tests/smoke.json';

    print 'Running smoke tests...', "\n";

    print "\n";
    print "#" x 80, "\n";
    print "# UNIT TESTS ", "\n";
    print "#" x 80, "\n\n";

    my $unit_exit = system("prove t");

    copy 't/data/acmetest.yml', $smoke_conf;
    replace_inplace(
        $smoke_conf,
        qr{dbname: acmetest},
        qq{dbname: $smoke_env}
    );

    print "\n";
    print "#" x 80, "\n";
    print "# STARTING WEB SERVER", "\n";
    print "#" x 80, "\n\n";

    system("cla-env web-stop --env $smoke_env --port $smoke_port");

    system("cla-env web-start --env $smoke_env --port $smoke_port --daemon --init --migrate-yes");

    sleep 5;

    print "\n";
    print "#" x 80, "\n";
    print "# UI TESTS ", "\n";
    print "#" x 80, "\n\n";

    copy 'ui-tests/nightwatch.json.example', $smoke_nightwatch_conf;
    replace_inplace(
        $smoke_nightwatch_conf,
        qr{"launchUrl"\s*:\s*".*?"},
        qq{"launchUrl" : "http://localhost:$smoke_port"}
    );

    my $ui_exit = system("$ENV{NODE_MODULES}/nightwatch/bin/nightwatch -c $smoke_nightwatch_conf -e phantomjs");

    print "\n";
    print "#" x 80, "\n";
    print "# STOPPING WEB SERVER", "\n";
    print "#" x 80, "\n\n";

    system("cla-env web-stop --env $smoke_env --port $smoke_port");

    print "\n";

    die "ERROR: Unit tests failed\n" if $unit_exit;
    die "ERROR: UI tests failed\n"   if $ui_exit;

    print "SUCCESS: No smoke detected!\n";
}

sub replace_inplace {
    my ($file, $pattern, $replace) = @_;

    my $input = slurp($file);

    my $output = $input;
    $output =~ s/$pattern/$replace/;

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

1;
__END__

=head1 Smoke

Common options:

=cut
