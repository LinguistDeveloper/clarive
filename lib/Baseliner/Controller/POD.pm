package Baseliner::Controller::POD;

if( $ENV{BASELINER_POD} ) {
    eval q{use base 'Catalyst::Controller::POD'};

    __PACKAGE__->config(
        inc        => 1,
        namespaces => [qw(Baseliner::* BaselinerX::*)],
        self       => 1,
        dirs       => [ "".Baseliner->path_to('.') ],
    );
    __PACKAGE__->meta->make_immutable( inline_constructor=>0 );
} else {
    eval q{
        use base 'Catalyst::Controller';
        sub pod : Global {
            my($self,$c)=@_;
            $c->res->body('<pre><b>Attention</b>: Baseliner POD Reference is turned off by default. To turn it on, 
           set the environment variable BASELINER_POD=1 and restart the web server.</pre>'); 
        }
    };
        
}

1;
