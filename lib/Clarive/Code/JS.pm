package Clarive::Code::JS;
use Moose;
BEGIN { extends 'Clarive::Code::Base' }

BEGIN { $ENV{PERL_INLINE_DIRECTORY} = "$ENV{CLARIVE_BASE}/local/lib/_Inline" }

use Try::Tiny;
use Scalar::Util qw(blessed);
use JavaScript::Duktape 1.0;
use Baseliner::Utils qw(:logging _md5 _file);
use Clarive::Code::JSUtils;
use Clarive::Code::JSModules::console;
use Clarive::Code::JSModules::process;

has enclose_code  => qw(is rw isa Bool default 0);
has transpiler    => qw(is rw isa Str), default => '';
has allow_pragmas => qw(is rw isa Bool default 1);

has filename => qw(is rw isa Str), default => 'EVAL';

has extend_cla => qw(is rw isa HashRef default), sub { +{} };
has global_ns  => qw(is rw isa HashRef default), sub { +{} };

has save_vm  => qw(is rw isa Bool default 0);
has _last_vm => qw(is rw isa Any);

has
  prefix  => qw(is rw isa Str required 1 lazy 1),
  default => sub {
    my $self = shift;

    my $prefix = '';

    $prefix .= qq{"use strict";\n} if $self->strict_mode;

    $prefix .= <<"EOF";
Duktape.modSearch = function (id) {
    var res = cla.loadModule(id);
    return res;
};
EOF

    $prefix;
  };

has
  _prefix_lines => qw(is rw isa Num lazy 1),
  default       => sub {
    my $self = shift;
    scalar split /\n/, $self->prefix;
  };

our $CURRENT_VM;

sub eval_code {
    my $self = shift;
    my ( $code, $stash ) = @_;

    $stash ||= {};

    my $js_duk = $self->_initialize($stash);

    local $Clarive::Code::JSUtils::GLOBAL_ERR = '';

    if ( $self->allow_pragmas ) {
        $self->_process_pragmas($code);
    }

    my $processed_code;

    if ( my $tp = $self->transpiler ) {
        $processed_code = $self->_transpile( $tp, $code );
    }
    else {
        $processed_code = heredoc($code);
        $processed_code = template_literals($processed_code);
    }

    if ( $self->enclose_code ) {
        $processed_code = $self->prefix . "(function(global){$processed_code}(this))";
    }
    else {
        $processed_code = $self->prefix . $processed_code;
    }

    return try {
        local $CURRENT_VM = $js_duk;

        $js_duk->eval($processed_code);
    }
    catch {
        my $err = shift;
        $err =~ s{^(.+) at /.+/JS.pm line \d+\.$}{$1}s;

        my $file = $self->filename;

        my $msg = "Error executing JavaScript ($file): $err";

        if ( $err =~ /parse error/ && $Clarive::Code::JSUtils::GLOBAL_ERR ) {
            warn("$Clarive::Code::JSUtils::GLOBAL_ERR\n");
        }

        if ( my ($err_line) = $err =~ /\(line (\d+)\)/ ) {
            $err_line--;

            my @lines = ( split "\n", $processed_code );

            my $start_line = $err_line > ( $self->_prefix_lines + 2 ) ? $err_line - 2 : $self->_prefix_lines;
            my $end_line = $err_line < ( $#lines - 2 ) ? $err_line + 2 : $#lines;

            for my $line ( $start_line .. $end_line ) {
                my $real_line = $line + 1 - $self->_prefix_lines;

                if ( $line == $err_line ) {
                    $msg =~ s/(\(line )(\d+)\)/(line $real_line)/;
                }

                $msg .= sprintf "%d%s %s\n", $real_line, ( $line == $err_line ? '>>>' : ':  ' ), $lines[$line];
            }
        }

        _fail "$msg";
    };
}

sub _initialize {
    my $self = shift;
    my ($stash) = @_;

    if ( my $last_vm = $self->_last_vm ) {
        return $last_vm;
    }

    my $js_duk = JavaScript::Duktape->new;
    if ( $self->save_vm ) {
        $self->_last_vm($js_duk);
    }

    $js_duk->set( __filename => $self->filename );
    $js_duk->set( __dirname  => $self->current_dir );

    $js_duk->set(
        YAML => {
            parse => sub { my ($string) = @_; $string = Encode::encode( 'UTF-8', $string ); YAML::XS::Load($string) },
            stringify => sub { YAML::XS::Dump(@_) }
        }
    );

    my $console_ns = Clarive::Code::JSModules::console->generate( $stash, $self );
    $js_duk->set( console => $console_ns );

    my $process_ns = Clarive::Code::JSModules::process->generate( $stash, $self );
    $js_duk->set( process => $process_ns );

    # cla ns setup
    require Clarive::Code::JSModules::cla;
    my $cla_ns = Clarive::Code::JSModules::cla->generate( $stash, $self );
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

sub _process_pragmas {
    my $self = shift;
    my $code = shift;

    for my $pragma ( grep !/^["']$/, "\n$code" =~ m{\n[\s\t]*(["'])use (.+)\1;}g ) {
        if ( $pragma =~ 'transpiler\((\S+)\)' ) {
            $self->transpiler($1);
        }
    }
}

sub _transpile {
    my $self = shift;
    my ( $lang, $code ) = @_;

    my $md5 = _md5($code);
    if ( my $cached = cache->get( { d => 'code-js:transpiler', md5 => $md5 } ) ) {
        return $cached;
    }

    my $tp = Clarive->app->plugins->locate_first("transpiler/$lang.js")
      or die "Transpiler not found: $lang\n";
    my $tp_code = _file( $tp->{path} )->slurp( iomode => '<:utf8' );

    my $js = JavaScript::Duktape->new;

    $js->set( loadModule => sub { load_module( shift() ) } );
    my $loader = q{ Duktape.modSearch = function(id) { return loadModule(id) }; };
    $js->eval($loader);

    my $duk = $js->duk;
    $duk->eval_string($tp_code);
    $duk->push_string("$code");
    if ( my $rc = $duk->pcall(1) ) {
        die sprintf "Transpile Error (%s): %s\n", $lang, $duk->safe_to_string(-1);
    }
    else {
        my $transpiled = $duk->to_perl(-1);
        die "Transpiled code empty or invalid\n" if !length $transpiled;
        cache->set( { d => 'code-js:transpiler', md5 => $md5 }, $transpiled );
        return $transpiled;
    }
}

sub current_dir {
    my $self = shift;

    return '' . _file( $self->filename )->parent;
}

1;
