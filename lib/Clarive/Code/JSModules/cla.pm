package Clarive::Code::JSModules::cla;
use strict;
use warnings;

use Encode ();
use Try::Tiny;
use Class::Load qw(load_class);
use Baseliner::Utils qw(parse_vars :logging _dump _encode_json _decode_json
  _json_pointer _array);
use BaselinerX::Type::Model::ConfigStore;
use Clarive::Code::Utils;

sub generate {
    my $self  = shift;
    my $stash = shift;
    my $js    = shift;

    return {
        loadCla => js_sub {
            my $id = shift;

            return $self->_generate_ns( $id, $stash, $js );
        },
        loadModule => js_sub {
            my $id = shift;

            load_module($id);
        },
        each => js_sub {
            my ( $arr, $cb ) = @_;

            return 0 unless ref $arr eq 'ARRAY';

            my $cnt = 0;
            foreach my $el (@$arr) {
                js_sub( \&$cb )->( $el, ++$cnt );
            }

            $cnt;
        },
        lastError => js_sub {
            return $!;
        },
        regex => js_sub {
            my ( $re, $opts ) = @_;
            { __cla_js => 'regex', re => $re, opts => $opts }
        },
        printf => js_sub {
            printf map { Encode::encode( 'UTF-8', $_ ) } @_;
        },
        sprintf => js_sub {
            my $fmt = shift;

            return sprintf( $fmt, @_ );
        },
        parseVars => js_sub {
            my ( $str, $local_stash ) = @_;

            return parse_vars( $str, { %$stash, %{ $local_stash || {} } } );
        },
        stash => js_sub {
            my ( $pointer, $value ) = @_;

            return $stash if @_ == 0;

            @_ == 2
              ? _json_pointer( $stash, $pointer, $value )
              : _json_pointer( $stash, $pointer );
        },
        config => js_sub {
            my ( $pointer, $value ) = @_;

            @_ == 2
              ? _json_pointer( Clarive->app->config, $pointer, $value )
              : _json_pointer( Clarive->app->config, $pointer );
        },
        eval => js_sub {
            my ( $lang, $code ) = @_;
            if ( $lang =~ /perl|pl/ ) {
                local $@;
                my @ret = do { eval $code };
                _fail "$@" if $@;
                return @ret == 1 ? _serialize( {}, $ret[0] ) : _serialize( {}, \@ret );
            }
            elsif ( $lang =~ /javascript|js/ ) {
                my $ret = $js->eval_code($code);
                return $ret;
            }
            else {
                die "Could not eval, language not available: $lang\n";
            }
        },
    };
}

sub _generate_ns {
    my $self = shift;
    my ( $id, $stash, $js ) = @_;

    my $pkg = 'Clarive::Code::JSModules::' . $id;

    try {
        load_class($pkg);
    }
    catch {
        my $error = shift;

        die("Error loading module `$id` ($pkg): $error\n");
    };

    return $pkg->generate( $stash, $js );
}

1;
