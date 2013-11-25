package Baseliner::Plugin::ConfigExternal;
use Moose;

sub setup { 
    my $c = shift;
    # config / options from a supervisor? -- have higher precedence than .conf files
    if( ref $Baseliner::BASE_OPTS eq 'HASH' ) {
        $c->config( %{ $c->config }, %{ $Baseliner::BASE_OPTS } );
    }
    $c->next::method(@_);
}

1;
