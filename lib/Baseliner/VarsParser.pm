package Baseliner::VarsParser;
use strict;
use warnings;

use Baseliner::Utils qw(_array _throw _loc _damn _name_to_id);

my $RE_START    = qr/\$\{/;
my $RE_END      = qr/\}/;
my $RE_NR_START = qr/\$\{\{/;
my $RE_NR_END   = qr/\}\}/;
my $RE_INSIDE   = qr/[^\}]+/;

my $RE_WITH_CAPTURES = qr{
    (
        (?:
            $RE_NR_START
                ($RE_INSIDE)
            $RE_NR_END
        |
            $RE_START
                ($RE_INSIDE)
            $RE_END
        )
    )
}x;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{throw}   = $params{throw};
    $self->{cleanup} = $params{cleanup};
    $self->{timeout} = $params{timeout} || 30;

    return $self;
}

sub parse_vars {
    my $self = shift;
    my ( $data, $vars ) = @_;

    return $data unless defined $data && length $data && ref $vars;

    $self->{stack} = {};

    my $ret;
    {
        local $SIG{ALRM} = sub { alarm 0; die "parse_vars timeout - data structure too large?\n" };
        alarm( $self->{timeout} );

        $ret = $self->_parse_vars( $data, $vars );
        alarm 0;
    }
    return $ret;
}

our $parse_vars_raw_scope;

sub _parse_vars {
    my $self = shift;
    my ( $data, $vars ) = @_;

    return $data unless defined $data && length $data && ref $vars;

    my $ref = ref $data;

    # Block recursion
    $parse_vars_raw_scope or local $parse_vars_raw_scope = {};
    return () if $ref && exists $parse_vars_raw_scope->{"$data"};
    $parse_vars_raw_scope->{"$data"} = () if $ref;

    my $stack = $self->{stack};

    if ( $ref eq 'HASH' ) {
        my %ret;
        for my $k ( keys %$data ) {
            my $v = $data->{$k};
            $ret{$k} = $self->_parse_vars( $v, $vars );
        }
        return \%ret;
    }
    elsif ( $ref =~ /Baseliner/ ) {
        my $class = $ref;
        my %ret;
        for my $k ( keys %$data ) {
            my $v = $data->{$k};
            $ret{$k} = $self->_parse_vars( $v, $vars );
        }
        return bless \%ret => $class;
    }
    elsif ( $ref eq 'ARRAY' ) {
        return [ map { $self->_parse_vars( $_, $vars ) } @$data ];
    }
    elsif ( $ref eq 'SCALAR' ) {
        return $self->_parse_vars( $$data, $vars );
    }
    elsif ( $ref eq 'MongoDB::OID' ) {
        return $self->_parse_vars( $data->{value}, $vars );
    }
    elsif ($ref) {
        return $self->_parse_vars( _damn($data), $vars );
    }

    # Stringifying and copying just in case
    my $str = "$data";

    # This need a bit of explanation. If we parse a single var
    # it is possible to transform it into a non-scalar structure:
    #
    #    my $array_ref = parse_vars('${foo}', {foo => [1, 2, 3]});
    #
    if ( $str =~ m/^$RE_WITH_CAPTURES$/ ) {
        $str = $self->_parse_var( $1, $2 || $3, $vars );
    }

    # Otherwise we just stringify everything
    #
    #    my $string = parse_vars('${foo} ${bar}', {foo => [1, 2, 3], bar => '123'});
    #
    # This will product smth like 'ARRAY(...) 123'
    #
    else {
        $str =~ s/$RE_WITH_CAPTURES/$self->_parse_var_top($1, $2 || $3, $vars)/ge;
    }

    # Cleanup or throw unresolved vars
    if ( $self->{throw} ) {
        my @unresolved;
        while ( $str =~ s/$RE_NR_START($RE_INSIDE)$RE_NR_END//gs ) {
            push @unresolved, $1;
        }
        push @unresolved, $str =~ m/$RE_START($RE_INSIDE)$RE_END/gs;

        if (@unresolved) {
            _throw _loc( "Unresolved vars: '%1' in %2", join( "', '", sort @unresolved ), $str );
        }
    }
    elsif ( $self->{cleanup} ) {
        $str =~ s/(?:$RE_NR_START$RE_INSIDE$RE_NR_END|$RE_START$RE_INSIDE$RE_END)//g;
    }

    return $str;
}

sub _parse_var_top {
    my $self = shift;
    my ( $str, $k, $vars ) = @_;

    my $result = $self->_parse_var($str, $k, $vars);

    if ($result && ref $result) {
        _throw _loc('Unexpected reference found in %1', $str);
    }
    return $result;
}

sub _parse_var {
    my $self = shift;
    my ( $str, $k, $vars ) = @_;

    my $recursive = 1;
    if ( $str =~ m/^$RE_NR_START/ ) {
        $k =~ s/^{(.*)}$/$1/;
        $recursive = 0;
    }

    my $throw = $self->{throw};
    my $stack = $self->{stack};

    # Control recursion and create a path for a clearer error message
    if ( grep { $_ eq $k } @{ $stack->{path} || [] } ) {
        _throw _loc 'Deep recursion in parse_vars for variable `%1`, path %2', $k,
          '${' . join( '}/${', _array( $stack->{path} ) ) . '}';
    }

    $stack->{path} or local $stack->{path} = [];
    push @{ $stack->{path} }, $k;

    # Just a var
    if ( exists $vars->{$k} ) {
        my $new_k = $vars->{$k};
        $str = $recursive ? $self->_parse_vars( $new_k, $vars ) : $new_k;
        return $str;
    }

    # Dot?
    if ($k =~ /[\.\w]+/) {
        my @keys = split( /\./, $k ) ;
        if ( @keys > 1 ) {
            my $k2 = join( '}->{', @keys );
            if ( eval( 'exists $vars->{' . $k2 . '}' ) ) {
                my $new_k = eval( '$vars->{' . $k2 . '}' );
                $str = $recursive ? $self->_parse_vars( $new_k, $vars ) : $new_k;
                return $str;
            }
        }
    }

    if ( $k =~ /^(uc|lc)\(([^\)]+)\)/ ) {
        my $v = $self->_parse_vars( '${' . $2 . '}', $vars );
        $str = $1 eq 'uc' ? uc($v) : lc($v);
        return $str;
    }

    if ( $k =~ /^to_id\(([^\)]+)\)/ ) {
        my $new_k = $1;
        $str = _name_to_id( $self->_parse_vars( $1, $vars ) );
        return $str;
    }

    if ( $k =~ /^quote_list\(([^\),]+)(?:,(\S))?\)$/ ) {
        my $qt = $3 // '"';    # double quote is default
        $str = join "$qt $qt", _array( $self->_parse_vars( '${' . $1 . '}', $vars ) );
        $str = $qt . $str . $qt;
        return $str;
    }

    if ( $k =~ /^nvl\(([^\)]+),(.+)\)/ ) {
        $str = $vars->{$1} // $2;
        return $str;
    }

    if ( $k =~ /^json\(([^\)]+)\)/ ) {
        $str = Util->_to_json($vars->{$1} || {});
        return $str;
    }

    if ( $k =~ /^yaml\(([^\)]+)\)/ ) {
        $str = Util->_to_json($vars->{$1} || {});
        return $str;
    }

    if ( $k =~ /^ci\(([^\)]+)\)\.(.+)/ ) {
        my $ci = ci->new( $vars->{$1} );
        $str = $ci->can($2) ? $ci->$2 : $ci->{$2};
        return $str;
    }

    if ( $k =~ /^ci\(([^\)]+)\)/ ) {

        # Better than ci->find, this way it fails when mid not found
        $str = ci->new( $vars->{$1} );
        return $str;
    }

    return $str;
}

1;
