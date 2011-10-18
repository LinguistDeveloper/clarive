=head1 NAME

bali stop - kills services

=cut

my $mode = ( grep /-k(ill)?/, @ARGV ) ? 'kill' : 'stop';

for my $service_name (  @ARGV ) {
    next if $service_name =~ /^-/;  # its an option, ignore
    $service_name =~ s{^service\.}{}g;
    $0 = '';
    print "Looking for service 'service.$service_name'...\n";
    my $found;
    my @ps = grep /bali\.pl/, `ps uwwx`;
    for( @ps ) {
        if( /(service\.)*$service_name/ ) {
            my @fields = split /[\t|\s]+/;
            my $pid = $fields[1];
            if( $pid ) {
                my $msg = ( $mode eq 'stop' ? 'Stopping ' : 'Killing ' ) . "$pid...\n";
                print $msg;
                kill 1,$pid if $mode eq 'stop';
                kill 9,$pid if $mode eq 'kill';
                $found=1;
            }
        } 
    }
    print $found ? "Done.\n" : "No processes found.\n";
}
