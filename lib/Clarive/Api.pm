package Clarive::Api;
use Mouse;
use Try::Tiny;
use Baseliner::Utils qw(:logging);

has _stash => qw(is rw isa HashRef default), sub{ +{} };
has modified_keys => qw(is rw isa HashRef default), sub{ +{} };

sub stash {
    my ($self,$key,$data) = @_; 
    return $self->_stash unless length $key;
    return defined $data 
        ? do{ $self->modified_keys->{$key}//=(); $self->_stash->{$key} = $data }
        : $self->_stash->{$key};
}
sub launch {
    my ($self,$key,$config, %p)=@_;
    my $reg = Baseliner->registry->find( $key ) 
        // Baseliner->registry->find( "service.$key" ) 
        // _fail( _loc('Could not find key %1 in registry', $key));
    return $reg->run_container( $p{stash}//$self->_stash, $config );
}
sub run_local {
    my ($self,$p)=@_;
    system $p;
}
sub merge_modified {
    my ($self,$stash) = @_;
    do { 
        $stash->{$_} = $self->_stash->{$_};
    } for keys $self->modified_keys;
}

# auto service api
our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    my ($method) = reverse( split(/::/, $name));
    if( my $reg = ( Baseliner->registry->find("service.$method") || Baseliner->registry->find($method) ) ) {
        return $reg->run_container( $self->_stash, @_ );
    } else {
        return $self->$method(@_);
    }
}
1;
