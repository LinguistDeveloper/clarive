package BaselinerX::Type::Service::Container::Job::Logger;

our $AUTOLOAD;

sub AUTOLOAD {
    shift;
    my $name = $AUTOLOAD;
    my @a    = reverse(split(/::/, $name));
    my $lev  = $a[0];
    my ($cl, $fi, $li) = caller(0);
    Util->_log_me($lev // 'info', $cl, $fi, $li, @_);
}

1;
