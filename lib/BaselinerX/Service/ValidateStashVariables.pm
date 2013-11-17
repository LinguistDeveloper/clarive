package BaselinerX::Service::ValidateStashVariables;
use Baseliner::Plug;
use Baseliner::Utils;
use Path::Class;
use Try::Tiny;

with 'Baseliner::Role::Service';

register 'service.validate.stash_variables' => {
    name => 'Validate stash variables',
    handler => \&validate,
    icon => '/static/images/icons/webservice.png',
    form => '/forms/validate_stash_variables.js', 
};

sub validate {
    my ( $self, $c ) = @_;

    my $msg = "<br><br>";
    my $status = 'ok';

    my $variables = $c->{config}->{variables};
    my $stash = $c->{stash};

    if ( $variables ) {
        for my $var ( keys %$variables ) {
            my @tokens = split /\./, $var;
            my $value = $stash;
            my @name;

            for my $token ( @tokens ) {
                $value = $value->{$token};
                push @name, $token;
                if ( !$value ) {
                    $status = 'ko';
                    $msg .= " - "._loc("%1 must be filled", join(".",@name))."<br>";
                    last;
                }
            };

            if ( $value ) {
                if ( $variables->{$var} && $variables->{$var} ne '???' ) {
                    my $qr = qr($variables->{$var});
                    try {
                        if ( $value !~ $qr ) {
                            $status = 'ko';
                            $msg .= " - "._loc("%1 must match reg-exp %2", $var,$variables->{$var})."<br>";
                        }
                    } catch {
                            $status = 'ko';
                            $msg .= " - "._loc("Error parsing %1: %2", $var, shift)."<br>";                    
                    };
                }
            }
        }
    }
    if ( $status eq 'ko') {
        _fail $msg;
    }
} 


1;
