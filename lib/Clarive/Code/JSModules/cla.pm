package Clarive::Code::JSModules::cla;
use strict;
use warnings;

use Time::HiRes qw(usleep);

use Baseliner::Utils qw(parse_vars :logging _dump _encode_json _decode_json
                    _json_pointer _array _file _dir);
use Clarive::Code::Utils;

sub generate {
    my $self  = shift;
    my $stash = shift;
    my $js    = shift;

    +{
        loadCla => js_sub {
            my $id = shift;
            my $ns = $self->_generate_ns( $id, $stash, $js )
              || die "Clarive standard library namespace not found: $id\n";
            return $ns;
        },
        loadModule => js_sub {
            my $id = shift;

            if ( $id =~ /^cla\/(.+)$/ ) {
                return sprintf q{
                    (function(){
                        module.exports = cla.loadCla("%s");
                    }());
                }, $1;
            }
            elsif (
                my $path = Clarive->app->plugins->locate_path(
                    "modules/$id", "modules/$id.js"
                )
              )
            {
                return scalar _file($path)->slurp( iomode => '<:utf8' );
            }
            else {
                die sprintf(
                    "Could not find module `%s` in the following plugins: %s\n",
                    $id,
                    join( ',',
                        Clarive->app > plugins->all_plugins( name_only => 1 ) )
                );
            }
        },
        each => js_sub {
            my ( $arr, $cb ) = @_;

            return 0 unless ref $arr eq 'ARRAY' || !@$arr;

            my $cnt = 0;
            foreach my $el (@$arr) {
                $cb->( $el, ++$cnt );
            }

            $cnt;
        },
        loc => js_sub {
            my ( $lang, $fmt, @args ) = @_;

            my $handle = Baseliner::I18N->get_handle($lang);
            return $handle->maketext( $fmt, @args );
        },
        lastError => js_sub {
            return $!;
        },
        regex => js_sub {
            my ( $re, $opts ) = @_;
            { __cla_js => 'regex', re => $re, opts => $opts }
        },
        printf => js_sub {
            printf(@_);
        },
        sprintf => js_sub {
            my $fmt = shift;

            sprintf( $fmt, @_ );
        },
        dump => js_sub {
            print Util->_dump(@_);
        },
        parseVars => js_sub {
            my ( $str, $local_stash ) = @_;

            return parse_vars( $str, { %$stash, %{ $local_stash || {} } } );
        },
        sleep => js_sub {
            my $s = shift;
            usleep( $s * 1_000_000 );
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
        configTable => js_sub {
            my ( $key, $value ) = @_;

            @_ == 2
              ? BaselinerX::Type::Model::ConfigStore->set(
                key   => $key,
                value => $value
              )
              : BaselinerX::Type::Model::ConfigStore->get( $key, value => 1 );
        },
        eval => js_sub {
            my ( $lang, $code ) = @_;
            if( $lang =~ /perl|pl/ ) {
                local $@;
                my @ret = do { eval $code };
                _fail "$@" if $@;
                return @ret==1 ? _serialize({}, $ret[0]) : _serialize({}, \@ret);
            }
            elsif( $lang =~ /javascript|js/ ) {
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
    my ($id,$stash,$js) = @_;

    my $pkg = 'Clarive::Code::JSModules::' . $id;

    local $@;

    eval "require $pkg";

    if( $@ ) {
        die( "Error loading module `$id` ($pkg): $@\n" );
    }

    return $pkg->generate( $stash, $js );
}

1;

