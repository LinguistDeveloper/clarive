package Clarive::Code::Utils;
use strict;
use warnings;
use Class::Load qw(is_class_loaded);
use Try::Tiny;

use Exporter::Tidy default => [
    qw(
        unwrap_types
        js_sub
        from_camel_class
        to_duk_bool
        template_literals
        heredoc
      )
];

our $GLOBAL_ERR;

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

    my ($classname) = grep { is_class_loaded( Util->to_ci_class($_) ) } ($camel,$snake);

    $classname;
}

1;
