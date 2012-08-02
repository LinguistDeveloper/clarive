package Baseliner::Role::Exception;
use Moose::Role;
use Carp;
use Baseliner::Utils;

has 'message' => ( is=>'ro', isa=>'Str', required=>1 );
has 'rc' => ( is=>'ro', isa=>'Int' );
has 'data' => ( is=>'ro', isa=>'Any' );
has 'caller' => ( is=>'ro', isa=>'Str' );
has 'stack' => ( is=>'ro', isa=>'Str' );

sub BUILDARGS {
    my $class = shift;
    my $p = _parameters(@_);

    my ($package, $filename, $line) = caller 2;

    $p->{caller} = "$package $filename;$line";
    $p->{stack} = Carp::longmess;

    return $p;
}

1;
