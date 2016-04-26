package Clarive::Code::Utils;
use strict;
use warnings;

use Exporter::Tidy default => [
    qw(
        unwrap_types
        js_sub
        from_camel_class
        to_duk_bool
        template_literals
        heredoc
        peek
        pv_address
        to_bytecode
        _serialize
        _map_ci
        _map_methods
        _map_instance
        _to_json
        _bc_sub
      )
];

use Try::Tiny;
use PadWalker qw(closed_over);

use Baseliner::Utils qw(_array _package_is_loaded _to_camel_case _unbless);

our $GLOBAL_ERR;

use Config qw( %Config );
my $ptr_format = do {
    my $ptr_size = $Config{ptrsize};
    $ptr_size == 4 ?
        "L" : $ptr_size == 8 ?
        "Q" :
        die("Unrecognized pointer size");
};

sub to_duk_bool {
    $_[0] ? $JavaScript::Duktape::Bool::true : $JavaScript::Duktape::Bool::false;
}

sub heredoc {
    my $code = shift;

    my $trans = sub {
        my $s = shift;
        $s =~ s/'/\\'/g;
        $s =~ s/\r?\n/\\\n/g;
        "'$s';"
    };
    $code =~ s{<<(['"]?)(\w+)\1;?\r?\n(.*?)\2\r?\n}{$trans->($3)}egs;

    return $code;
}

sub template_literals {
    my $code = shift;

    # Ecmascript ES6 templating
    my $strf = sub {
        my ($str) = @_;

        # escape single-quotes, (?<=[^\\]) means "preceded by \, but don't capture it"
        $str =~ s{(?<=[^\\])'}{\\'}g;

        # convert expression to function
        #    TODO this is too precarious: brackets and single-quotes get messed up
        $str =~ s/(?<=[^\\])\$\{([^\}]+)\}/'+(function(){return($1);})()+'/g;

        # and for the str position 0, can't find a zero-width look behind that works...
        $str =~ s/^\$\{([^\}]+)\}/'+(function(){return($1);})()+'/g;

        # preserve escaped expressions: \${...}
        $str =~ s/\\\$\{([^\}]+)\}/\${$1}/g;

        # turn new lines into escaped new lines,
        #   so that the line number count doesn't change
        $str =~ s{\n}{\\n\\\n}g;

        "'$str'";
    };

    $code =~ s{`([^`]*)`}{$strf->($1)}egs;

    $code;
}

sub unwrap_types {
    my $unwrap;
    $unwrap = sub {
        my $v = shift;
        if( ref $v eq 'HASH' ) {
            if( my $type = $v->{__cla_js} ) {
                my $opts = $v->{opts} ? "(?$v->{opts})" : '';
                my $re = $v->{re} // '';
                return qr/$opts$re/;
            } else {
                return +{ map { $_ => $unwrap->($v->{$_}) } keys %$v };
            }
        }
        elsif( ref $v eq 'ARRAY' ) {
            return [ map { $unwrap->($_) } @$v ];
        }
        else {
            return $v;
        }
    };
    return map { $unwrap->($_) } @_;
}

sub js_sub(&) {
    my $code = shift;
    sub {
        my $duk = shift;
        my @args = unwrap_types( @_ );

        return try {
            $code->(@args);
        } catch {
            $GLOBAL_ERR = shift;
            die "$GLOBAL_ERR\n"; # this msg is probably silent within Duktape
        };
    }
}

sub from_camel_class {
    my ($camel) = @_;

    my $snake = $camel =~ s{([A-Z])}{"_" . lc($1)}ger;
    $snake = substr($snake,1) if $snake =~ /^_/;

    my @attempts = map { [$_, Util->to_ci_class($_)] } ( $camel, $snake );
    my ($classname) = map{ $_->[0] } grep { _package_is_loaded( $_->[1] ) } @attempts;

    die "Could not find a CI class named `$camel`\n" unless $classname;

    $classname;
}

sub peek { unpack 'P'.$_[1], pack $ptr_format, $_[0] }

sub pv_address {
    my $buf = shift;
    return unpack($ptr_format, pack("p", $buf));
}

sub to_bytecode {
    my ($duk,$code) = @_;

    my $ptr = ${ closed_over($code)->{'$ptr'} };
    $duk->push_heapptr($ptr);
    $duk->dump_function();

    my $buf_ptr = $duk->get_buffer( -1, my $len );
    return ( scalar peek( $buf_ptr, $len ), $len );
}

sub _serialize {
    my ( $options, @docs ) = @_;

    $options->{_seen} //= {};

    my @result;
    foreach my $doc (@docs) {
        if ( ref $doc ) {
            $options->{_seen}->{"$doc"}++;

            if ( $options->{_seen}->{"$doc"} > 1 ) {
                push @result, '__cycle_detected__';
                next;
            }
        }

        if ( Scalar::Util::blessed($doc) ) {
            push @result, _map_instance( $doc );
        }
        elsif ( ref $doc eq 'CODE' ) {
            push @result, $options->{to_bytecode} ? _bc_sub( $doc ) : js_sub(\&$doc);
        }
        elsif ( ref $doc eq 'ARRAY' ) {
            my $array = [];
            foreach my $el (@$doc) {
                push @$array, scalar _serialize( $options, $el );
            }

            push @result, $array;
        }
        elsif ( ref $doc eq 'HASH' ) {
            my $hash = {};
            foreach my $key ( keys %$doc ) {
                $hash->{$key} = _serialize( $options, $doc->{$key} );
            }
            push @result, $hash;
        }
        elsif ( $options->{convert_subs} && ref $doc eq 'CODE' ) {
            return 'function() { ... }';
        }
        else {
            push @result, $doc;
        }
    }

    return wantarray ? @result : $result[0];
}

sub _bc_sub {
    my $orig = shift;

    my ($bytecode,$len) = to_bytecode( $Clarive::Code::JS::CURRENT_VM->duk, $orig );

    sub {
        my $self_ci = shift;
        my @args = @_;
        my $duk;

        if( ref $_[0] ne 'JavaScript::Duktape::Vm' ) {
            my $js = Clarive::Code::JS->new( save_vm=>1 );
            #my $vm = JavaScript::Duktape->new;
            #$vm->eval('(function(){ print(111) }())');
            $js->eval_code('');
            $duk = $js->_last_vm->duk;
        } else {
            $duk = $Clarive::Code::JS::CURRENT_VM->duk;
        }

        my $pv_ptr = pv_address( $bytecode );
        $duk->push_external_buffer;
        $duk->config_buffer( -1, $pv_ptr, $len);
        $duk->load_function;
        $duk->push_perl( _serialize({},$self_ci) );
        $duk->push_perl( _serialize({},$_) ) for @args;
        $duk->call(1 + @args );
        my $ret = $duk->to_perl(-1);
        $duk->pop;
        return $ret;
    }
}

sub _map_ci {
    my $name = shift;

    return js_sub {
        my $instance = ci->$name->new(@_);

        return _map_instance($instance);
    }
}

sub _map_instance {
    my ($instance) = @_;

    return unless $instance;

    my @methods = _map_methods($instance);

    my $method_map = {};

    foreach my $method (@methods) {
        my $method_camelized = _to_camel_case($method);
        $method_map->{$method_camelized} = js_sub {
            _serialize( {}, $instance->$method(@_) );
        };
    }

    return $method_map;
}

sub _map_methods {
    my ($instance) = @_;

    my @methods;

    my @current_methods =
      $instance->can('meta')
      ? ( map { +{ name => $_->name, full => $_->fully_qualified_name } }
          $instance->meta->get_all_methods )
      : ( map { +{ name => [ /^.*::(.*?)$/ ]->[0], full => $_ } }
          _array( Class::Inspector->methods( ref $instance, 'full', 'public' ) ) );

    for my $method ( @current_methods ) {
        my $name = $method->{name};

        # Skip private methods
        next if $name =~ m/^_/;

        # Skip special methods like DESTROY
        next if $name =~ m/^[A-Z]/;

        my $full_name = $method->{full};

        # Skip everything that comes from Moose
        next if $full_name =~ m/^(?:Moose|UNIVERSAL)::/;

        push @methods, $name;
    }

    return @methods;
}

sub _to_json {
    my ($what) = @_;

    return 'undefined' unless defined $what;

    my $doc = _serialize( { convert_subs => 1 }, $what );
    return $doc unless ref $doc;

    JSON->new->pretty(1)->canonical(1)->encode($doc);
}

1;
