package Baseliner::Moose;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    with_meta => ['has_ci', 'has_cis'],
    with_caller => ['service'],
    also      => ['Moose'],
);

sub has_ci {
    my $meta = shift;
    my $name = shift;
    my %options;
    if ( @_ > 0 && @_ % 2 ) {
        $options{isa} = shift;
        $options{is}  = 'rw';
        $options{traits}  = ['CI'];
        if( @_ > 1 ) {  # allow: has_ci 'att' => 'Obj', required=>1;
            %options = ( %options, @_ );
        }
    }
    else {
        %options = @_;
        $options{isa} ||= 'CI';
        $options{is}  ||= 'rw';
        $options{traits} ||= ['CI'];
    }
 
    $meta->add_attribute( $name, %options, );
}

sub has_cis {
    my $meta = shift;
    my $name = shift;
    my %options;
    if ( @_ > 0 && @_ % 2 ) {
        $options{isa} = shift;
        $options{is}  = 'rw';
        $options{traits}  = ['CI'];
        if( @_ > 1 ) {  # allow: has_ci 'att' => 'Obj', required=>1;
            %options = ( %options, @_ );
        }
    }
    else {
        %options = @_;
        $options{isa} ||= 'CIs';
        $options{is}  ||= 'rw';
        $options{traits} ||= ['CI'];
    }
 
    $meta->add_attribute( $name, %options, );
}

=head2 service

Usage:
    
    service do_something => sub {
        my ($self,$c,$config) = @_;
        # my handler stuff... 
    }; 
    
OR:

    service do_something => {
        config  => '...', 
        handler => sub {
            my ($self,$c,$config) = @_;
            # my handler stuff... 
        },
    }; 
   
Service key names will be constructed using the packages basename 
+ the key supplied:

    BaselinerX::CI::nature;

    service scan => 'Scan files' => sub { };

Results in:

    'service.nature.scan' 

=cut
sub service {
    my ($pkg, $key, $value, $code ) = @_;
    my $longkey = $key =~ /\./ ? $key : do {
        my $basepkg = Util->_name_to_id( $pkg =~ /^.*::(.*?)$/ ? $1 : $pkg );
        "$basepkg.$key";
    };
    my $r = ref $value;
    # give it a Service role
    Moose::Util::apply_all_roles( $pkg, 'Baseliner::Role::Service' );
    if( $r eq 'HASH' ) {
        Baseliner::Core::Registry->add( $pkg, "service.$longkey", { type=>'ci', %$value } );
    }
    elsif( !$r && ref( $code ) eq 'CODE' ) {
        Baseliner::Core::Registry->add( $pkg, "service.$longkey", { type=>'ci', name=>$value, handler=>$code } );
    }
    elsif( $r eq 'CODE' ) {
        Baseliner::Core::Registry->add( $pkg, "service.$longkey", { type=>'ci', name=>$longkey, handler=>$value } );
    }
    else {
        Util->_fail( Util->_loc('Invalid type for service in %1: %2 (%3)', $pkg, $r, $longkey ) );
    }
}

1;
