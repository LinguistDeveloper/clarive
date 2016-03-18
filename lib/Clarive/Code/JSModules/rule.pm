package Clarive::Code::JSModules::rule;
use strict;
use warnings;

use Clarive::Code::Utils;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    +{
        create => js_sub {
            my ( $opts, $rule_tree ) = @_;

            Baseliner::Model::Rules->save_rule(
                rule_tree         => $rule_tree,
                rule_active       => '1',
                rule_name         => $opts->{name},
                rule_when         => $opts->{when},
                rule_event        => $opts->{event},
                rule_type         => $opts->{type},
                rule_compile_mode => $opts->{compileMode},
                rule_desc         => $opts->{description},
                subtype           => $opts->{subtype},
                authtype          => $opts->{authtype},
                wsdl              => $opts->{wsdl},
            );
        },
        run => js_sub {
            my ( $id_rule, $rule_stash ) = @_;

            require Baseliner::RuleRunner;
            my $rule_runner = Baseliner::RuleRunner->new;
            my $ret_rule    = $rule_runner->run_single_rule(
                id_rule      => $id_rule,
                stash        => ( ref $rule_stash ? $rule_stash : $stash ),
                logging      => 1,
                simple_error => 2,
            );

            ref $rule_stash ? $rule_stash : $stash;
        }
    };
}

1;
