package Baseliner::JS;
use Moose;
use Baseliner::Utils qw(:logging);

has je => qw(is rw isa JE lazy 1 default), sub{ require JE; JE->new };

sub run {
    my ($self,%p) = @_;
    
    my $jstash = $p{stash} 
        ? do{
            Util->_clone($p{stash});
        }
        : {};
    
    Util->_unbless($jstash);

    use JE;
    my $je = JE->new;
    my $api = ClaApiJS->new( _stash=>$jstash );
    $je->bind_class( 
        package => 'ClaApiJS',
        constructor => sub{ return $api },
        unwrap=>'1', 
        methods=>[
            grep !/^(meta|_(.*)|[A-Z]+|new)$/, map { $_->name } ClaApiJS->meta->get_all_methods
        ],
    );
    #   TODO the idea here is to wrap all calls to Cla so we take care of transforming data types
    # $je->bind_class( 
    #     name=>'Cla',
    #     wrapper=>sub { die @_ },
    # );
    
    # XXX not needed just use Cla.stash()
    # $je->new_function( stash => sub {
    #         my ($key,$data) = @_; 
    #         return $api->stash($key,$data);
    # });
    $je->eval(q{
        Cla = new ClaApiJS();
    });
    if( $@ ) {
        _fail _loc 'Error during setup of JS environment: %1', $@;
    }

    return () unless $p{code};
    my @ret = $je->eval($p{code});
    if( $@ ) {
        _fail _loc 'Error during execution of JS: %1', $@;
    }
    
    # merge modified values back into the stash
    $api->merge_modified( $p{stash} ) if( $p{stash} );

    return @ret;
}

sub js_header {
    return join '',<DATA>;
}

sub deref_je { 
   my ($self,$val) = @_;
   return ref($val) =~ /^JE::/
      ? do {
         my $val2 = $val->value;
         my $ref2 = ref $val2;
         return +{ map{ $_=>$self->deref_je($$val2{$_}) } keys $val2 } if $ref2 eq 'HASH'; 
         return [ map{ $self->deref_je($_) } @$val2 ] if $ref2 eq 'ARRAY'; 
         return $val2;
      }
      : $val;
}
sub convert_args {
    my $self = shift;
    map { 
       $self->deref_je($_);
    } @_;
}

=head1 ClaApiJS 

JE data type conversion class wrapper around the Api.
TODO this should be done with a bind_class wrapper, but could not find a way

=cut
package ClaApiJS {
    use Moose;
    extends 'Clarive::Api';
    use Try::Tiny;
    around qr/.*/ => sub {
        my $orig = shift;
        my $self = shift;
        my @args = Baseliner::JS->convert_args(@_);
        $self->$orig( @args );
    };
}

1;
__DATA__

