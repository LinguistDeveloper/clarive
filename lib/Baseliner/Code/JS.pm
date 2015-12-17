package Baseliner::Code::JS;
use strict;
use warnings;
use JavaScript::Duktape;

sub new {
    bless {} => __PACKAGE__;
}

sub eval_code {
    my $self = shift;
    my ($code,$stash) = @_;

    my $js = JavaScript::Duktape->new;
    $js->set(
        Cla => {
            parseVars => sub{
                my $js = shift;
                my ($str)=@_;
                Util->parse_vars($str,$stash);
            },
            CI=>{
                Clax => sub {
                    my $js = shift;
                    my ($opts) = @_;
                    { 
                        connect => sub {
                            $opts->{hostname};
                        }
                    }
                }
            }
        }
    );
    $js->eval( $code );
}

1;
