package BaselinerX::Service::Parsing;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Try::Tiny;

with 'Baseliner::Role::Service';

#our $ICON_DEFAULT = '/static/images/icons/parser.png';
our $ICON_DEFAULT = '/static/images/icons/page_lens.png';

register 'service.parsing.parse_files' => {
    name => 'Parse Files',
    form => '/forms/parse_files.js',
    icon => $ICON_DEFAULT,
    job_service  => 1,
    handler => \&parse_files,
};

sub parse_files {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $parsers = $config->{parsers} // _throw 'Parsers not configured';
    my $fail_mode = $config->{fail_mode} // 'skip';
    my $paths = $config->{path} // _throw 'Path not configured for parser';

    my %trees;
    for my $parser ( Util->_array_or_commas($parsers)  ) {
        my $p = ci->new( $parser );
        for my $path ( _array( $paths ) ) { 
            _throw _loc 'Path not found: `%1`', $path unless -e $path;
            my $file = ci->file->new( path=>$path );
            my $tree = $p->parse( $file );
            if( ref($tree) && ! keys %$tree ) {
                next if $fail_mode eq 'skip';
                my $msg = _loc( "Parser *%1* could not parse '%2'", $p->name, $path);
                _warn $msg if $fail_mode eq 'warn'; 
                _fail $msg if $fail_mode eq 'fail'; 
            }
            $trees{"$path"} = $tree; 
        }
    }
    \%trees; 
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
