package Clarive::Code::JS;
use v5.10;
use Moose;

BEGIN { $ENV{PERL_INLINE_DIRECTORY} = "$ENV{CLARIVE_BASE}/local/lib/_Inline" }

use JSON ();
use Storable ();
use Try::Tiny;
use Scalar::Util qw(blessed);
use JavaScript::Duktape;

use Baseliner::Mongo ();
use BaselinerX::Type::Model::ConfigStore;
use Baseliner::Utils qw(parse_vars packages_that_do _to_camel_case
                    :logging _load _dump _encode_json _decode_json
                    _json_pointer _array _file _dir );

use Clarive::Code::Utils;

has app           => qw(is rw isa Maybe[Clarive::App] weak_ref 1);
has options       => qw(is rw isa HashRef), default => sub { +{} };
has dump_code     => qw(is rw isa Bool default 0);
has enclose_code  => qw(is rw isa Bool default 0);
has strict_mode   => qw(is rw isa Bool default 0);
has allow_pragmas => qw(is rw isa Bool default 0);

has current_file      => qw(is rw isa Str), default=>'EVAL';

has extend_cla    => qw(is rw isa HashRef default),sub{+{}};
has global_ns     => qw(is rw isa HashRef default),sub{+{}};

has save_vm  => qw(is rw isa Bool default 0);
has _last_vm => qw(is rw isa Any);

has prefix => qw(is rw isa Str required 1 lazy 1), default => sub{
    my $self = shift;

    my $prefix = <<"EOF";
Duktape.modSearch = function (id) {
    var res = cla.loadModule(id);
    return res;
};
EOF
    $prefix .= qq{"use strict";\n} if $self->strict_mode;

    $prefix;
};

has _prefix_lines => qw(is rw isa Num lazy 1), default => sub{
    my $self = shift;
    scalar split /\n/, $self->prefix;
};

our $CURRENT_VM;

sub initialize {
    my $self = shift;
    my ($stash) = @_;

    if( my $last_vm = $self->_last_vm ) {
        return $last_vm;
    }

    # create / load / save JS vm
    my $js_duk = $self->_last_vm || JavaScript::Duktape->new;
    if( $self->save_vm ) {
        $self->_last_vm( $js_duk );
    }

    $js_duk->set(
        toJSON => js_sub {
            my ($what,$opts) = @_;

            return _to_json($what,$opts);
        }
    );

    $js_duk->set( __filename=>$self->current_file );
    $js_duk->set( __dirname =>$self->current_dir );

    require Clarive::Code::JSModules::console;
    my $console_ns = Clarive::Code::JSModules::console->generate($stash,$self);
    $js_duk->set( console=>$console_ns );

    # cla ns setup
    require Clarive::Code::JSModules::cla;
    my $cla_ns = Clarive::Code::JSModules::cla->generate($stash,$self);
    foreach my $ns ( keys %{ $self->extend_cla } ) {
        $cla_ns->{$ns} = $self->extend_cla->{$ns};
    }
    $js_duk->set( cla => $cla_ns );

    # top level ns setup
    foreach my $ns ( keys %{ $self->global_ns } ) {
        $js_duk->set( $ns => $self->global_ns->{$ns} );
    }

    return $js_duk;
}

sub eval_code {
    my $self = shift;
    my ( $code, $stash ) = @_;

    $code = heredoc( $code );
    $code = template_literals( $code );

    $stash ||= {};

    my $js_duk = $self->initialize( $stash );

    local $Clarive::Code::Utils::GLOBAL_ERR = '';

    if( $self->allow_pragmas ) {
        $self->_process_pragmas($code);
    }

    my $fullcode;

    if( $self->enclose_code ) {
        $fullcode = $self->prefix . "(function(){$code}())";
    } else {
        $fullcode = $self->prefix . $code;
    }

    printf STDERR $fullcode if $self->dump_code;

    return try {
        local $CURRENT_VM = $js_duk;
        $js_duk->eval( $fullcode );
    }
    catch {
        ( my $err = $_ ) =~ s{^(.+) at /.+/JS.pm line \d+\.$}{$1};

        my $file = $self->current_file;

        my $msg = "Error executing JavaScript ($file): $err";

        if( $err =~ /parse error/ && $Clarive::Code::Utils::GLOBAL_ERR ) {
            warn( "$Clarive::Code::Utils::GLOBAL_ERR\n" );
        }

        if( my ($err_line) = $err =~ /\(line (\d+)\)/ ) {
            $err_line--;
            my @lines = ( split "\n", $fullcode );
            my $start_line = $err_line > ($self->_prefix_lines+2) ? $err_line - 2 : $self->_prefix_lines;
            my $end_line   = $err_line < ( $#lines - 2 ) ? $err_line + 2 : $#lines;
            for my $line ( $start_line..$end_line ) {

                my $real_line = $line + 1 - $self->_prefix_lines;

                if( $line == $err_line ) {
                    $msg =~ s/(\(line )(\d+)\)/(line $real_line)/;
                }

                $msg .= sprintf "%d%s %s\n", $real_line, ( $line == $err_line ? '>>>' : ':  ' ), $lines[$line];
            }
        }
        _fail "$msg";
    };
}

sub _process_pragmas {
    my $self = shift;
    my $code = shift;

    for my $pragma ( $code =~ m{//CLA-PRAGMA (\S+)}g ) {
        if( $pragma =~ 'enclose=(\d+)' ) {
            $self->enclose_code($1);
        }
        elsif( $pragma =~ 'dump_code=(\d+)' ) {
            $self->dump_code($1);
        }
    }
}

sub current_filename {
    my $self = shift;
    return _file( $self->current_file )->basename;
}

sub current_dir {
    my $self = shift;
    return '' . _file( $self->current_file )->parent;
}

package Clarive::Code::JS::Service; {
    use Moose;
    with 'Baseliner::Role::Service';
};
1;
