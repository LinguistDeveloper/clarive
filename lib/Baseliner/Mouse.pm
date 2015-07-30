package Baseliner::Mouse;
use strict; 
use v5.14;
use Mouse::Exporter;
use Mouse ();
use Function::Parameters ();
#use Baseliner::Role::CI ();

sub import {
    my $pkg = caller;
    {
        no strict;
        # with_meta
        for my $meth ( qw(has_ci has_cis has_array) ) {
            *{ $pkg . '::' . $meth } = sub { @_ = ($pkg->meta, @_); goto \&{ __PACKAGE__ . '::' . $meth } };
        }
        # with_caller
        for my $meth( qw(service) ) {
            *{ $pkg . '::' . $meth } = sub { @_ = (scalar caller(), @_); goto \&{ __PACKAGE__ . '::' . $meth } };
        }
        # as_is
        for my $meth( qw(miss) ) {
            *{ $pkg . '::' . $meth } = \&{ __PACKAGE__ . '::' . $meth };
        }
    }
    eval "package $pkg; use Mouse;";
    Function::Parameters->import( ':strict' );
};

#Mouse::Exporter->setup_import_methods(
#    with_meta => ['has_ci', 'has_cis', 'has_array' ],
#    with_caller => ['service'],
#    also      => ['Mouse', 'Function::Parameters'],
#    as_is => ['missing'],
#);

sub miss {
    die "Missing parameter " . join ',',@_;
}

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

sub has_array {
    my $meta = shift;
    my $name = shift;
    my %options;
    if ( @_ > 0 && @_ % 2 ) {
        $options{isa} = shift;
        $options{is}  = 'rw';
        $options{traits}  = ['Array'];
        if( @_ > 1 ) {  # allow: has_array 'att' => 'Obj', required=>1;
            %options = ( %options, @_ );
        }
    }
    else {
        %options = @_;
        $options{isa} ||= 'ArrayRef';
        $options{is}  ||= 'rw';
        $options{traits} ||= ['Array'];
    }
    $options{default} //= sub{ [] };
    #$options{handles} //= { qw(elements elements push push map map grep grep first first get get join join count count is_empty is_empty sort sort), };
    $options{handles} //= {};
    $options{handles}{"${name}_$_"} = $_ for qw/elements push map grep first join count is_empty/;
 
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
    Mouse::Util::apply_all_roles( $pkg, 'Baseliner::Role::Service' );
    if( $r eq 'HASH' ) {
        my $h = { type=>'ci', %$value };
        $h->{handler} = $code if ref $code eq 'CODE';
        Baseliner::Core::Registry->add( $pkg, "service.$longkey", $h );
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

