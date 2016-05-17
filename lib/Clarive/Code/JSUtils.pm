package Clarive::Code::JSUtils;
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
      load_module
      _serialize
      _map_ci
      _map_instance
      _bc_sub
      )
];

use Try::Tiny;
use PadWalker qw(closed_over);
use Scalar::Util;
use Class::Inspector;
use JSON::XS;
use JavaScript::Duktape;

use Baseliner::Utils qw(_array _package_is_loaded _to_camel_case _unbless _file _dir);

our $GLOBAL_ERR;

use Config qw( %Config );
my $ptr_format = do {
    my $ptr_size = $Config{ptrsize};
        $ptr_size == 4 ? "L"
      : $ptr_size == 8 ? "Q"
      :                  die("Unrecognized pointer size");
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
        "'$s';";
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

sub unwrap_type {
    my $v = shift;

    if ( ref $v eq 'HASH' ) {
        if ( my $type = $v->{__cla_js} ) {
            if ( $type eq 'regex' ) {
                return qr/$v->{re}/;
            }
            else {
                return Util->_load( pack( 'H*', $v->{obj} ) );
            }
        }
        else {
            return { map { $_ => unwrap_type( $v->{$_} ) } keys %$v };
        }
    }
    elsif ( ref $v eq 'ARRAY' ) {
        return [ map { unwrap_type($_) } @$v ];
    }
    else {
        return $v;
    }
}

sub unwrap_types {
    map { unwrap_type($_) } @_;
}

sub js_sub(&) {
    my $code = shift;

    return sub {
        my @args = unwrap_types(@_);

        $code->(@args);
    };
}

sub from_camel_class {
    my ($camel) = @_;

    my $snake = $camel =~ s{([A-Z])}{"_" . lc($1)}ger;
    $snake =~ s{^_}{};

    my @attempts = map { [ $_, Util->to_ci_class($_) ] } ( $camel, $snake );
    my ($classname) = map { $_->[0] } grep { _package_is_loaded( $_->[1] ) } @attempts;

    die "Could not find a CI class named `$camel`\n" unless $classname;

    return $classname;
}

sub peek { unpack 'P' . $_[1], pack $ptr_format, $_[0] }

sub pv_address {
    my $buf = shift;

    return unpack( $ptr_format, pack( "p", $buf ) );
}

sub to_bytecode {
    my ( $duk, $code ) = @_;

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

        if ( ref $doc eq 'Regexp' ) {
            push @result, { __cla_js => 'regex', re => "$doc" };
        }
        elsif ( Scalar::Util::blessed($doc) ) {
            if ( $options->{wrap_blessed} ) {
                push @result, { __cla_js => ref($doc), obj => scalar unpack( 'H*', Util->_dump($doc) ) };
            }
            else {
                push @result, _map_instance($doc);
            }
        }
        elsif ( ref $doc eq 'CODE' ) {
            push @result, $options->{to_bytecode} ? _bc_sub($doc) : js_sub( \&$doc );
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
        else {
            push @result, $doc;
        }
    }

    return wantarray ? @result : $result[0];
}

sub _bc_sub {
    my $orig = shift;

    my ( $bytecode, $len ) = to_bytecode( $Clarive::Code::JS::CURRENT_VM->duk, $orig );

    return sub {
        my $self = shift;
        my @args = @_;
        my $duk;

        # uncoverable condition false
        my $vm = $Clarive::Code::JS::CURRENT_VM ||= JavaScript::Duktape->new;

        $duk = $vm->duk;

        #if ( ref $_[0] ne 'JavaScript::Duktape::Vm' ) {
        #    my $js = Clarive::Code::JS->new( save_vm => 1 );

        #    $js->eval_code('');
        #    $duk = $js->_last_vm->duk;
        #}
        #else {
            #$duk = $Clarive::Code::JS::CURRENT_VM ? $Clarive::Code::JS::CURRENT_VM->duk || JavaScript::Duktape::Vm->new;
            #}

        my $pv_ptr = pv_address($bytecode);
        $duk->push_external_buffer;
        $duk->config_buffer( -1, $pv_ptr, $len );
        $duk->load_function;

        $duk->push_perl( _serialize( {}, $self ) );
        $duk->push_perl( _serialize( {}, $_ ) ) for @args;
        $duk->pcall_method( 0 + @args );

        my $ret = $duk->to_perl(-1);
        $duk->pop;

        return $ret;
    };
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

    my @all_methods =
      $instance->can('meta')
      ? ( map { +{ name => $_->name, full => $_->fully_qualified_name } } $instance->meta->get_all_methods )
      : ( map { +{ name => [/^.*::(.*?)$/]->[0], full => $_ } }
          _array( Class::Inspector->methods( ref $instance, 'full', 'public' ) ) );

    my @attributes = $instance->can('meta') ? map { { name => $_->name } } $instance->meta->get_all_attributes : ();
    push @all_methods, @attributes;

    my @methods;
    for my $method (@all_methods) {
        my $name = $method->{name};

        # Skip private methods
        next if $name =~ m/^_/;

        # Skip special methods like DESTROY
        next if $name =~ m/^[A-Z]/;

        my $full_name = $method->{full};

        # Skip everything that comes from Moose
        next if $full_name && $full_name =~ m/^(?:Moose|UNIVERSAL)::/;

        push @methods, $name;
    }

    return @methods;
}

sub load_module {
    my $id = shift;

    if ( $id =~ /^cla\/(.+)$/ ) {
        return sprintf q{
            (function(){
                module.exports = cla.loadCla("%s");
            }());
        }, $1;
    }
    elsif ( my $item = Clarive->app->plugins->locate_first( "modules/$id.js", "modules/$id" ) ) {
        return scalar _file( $item->{path} )->slurp( iomode => '<:utf8' );
    }
    else {
        die sprintf( "Could not find module `%s` in the following plugins: %s\n",
            $id, join( ',', Clarive->app->plugins->all_plugins( id_only => 1 ) ) );
    }
}

1;
