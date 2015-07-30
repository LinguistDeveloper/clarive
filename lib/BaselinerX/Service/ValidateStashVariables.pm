package BaselinerX::Service::ValidateStashVariables;
use Moose;
use Baseliner::Core::Registry ':dsl';
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
            my $value;
            my @name;

            for my $token ( @tokens ) {
                $value = $stash->{$token};
                push @name, $token;
                if ( !$value || ( ref($value) =~ /ARRAY/ && scalar @$value == 0) || ( ref($value) =~ /HASH/ && scalar(keys %$value) == 0)) {
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


no Moose;
__PACKAGE__->meta->make_immutable;

1;
