package mdb;
our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    my @a = reverse( split(/::/, $name));
    my $db = $Clarive::_mdb //( $Clarive::_mdb = do{
        my $conf = $Clarive::app->config->{mongo};
        my $class = $conf->{class} // 'Baseliner::Mongo'; 
        eval "require $class";
        Util->_fail('Error loading mdb class: '. $@ ) if $@ ;
        $class->new( $conf );
    });
    my $class = ref $db;
    my $method = $class . '::' . $a[0];
    @_ = ( $db, @_ );
    goto &$method;
}

1;
