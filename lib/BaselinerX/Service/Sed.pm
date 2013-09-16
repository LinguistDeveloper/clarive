package BaselinerX::Service::Sed;
use Baseliner::Plug;
use Baseliner::Utils;
use Path::Class;
with 'Baseliner::Role::Service';

=head1 DESCRIPTION

Sed service is a file string substitution service.

=head1 USAGE

From the command line:

    perl script/bali.pl service.sed --path /tmp/aa --map '[{ pattern=>"s{bb}{111}", include=>'^.*\.txt' }]'

Some config examples:

    [
        { pattern=>[ 's{^text}{done}g', 's{11}{12}g' ] },
        { pattern=>'s{^text}{done}sg', slurp=>1  },
        { pattern=>[ 's{^text}{done}g', 's{11}{12}g' ], include=>'txt$|html$' },
    ]

Pattern is evalled, so escape vars when necessary. 

=head2 slurp mode

Treats the whole file as a single string. Be careful when substituting a line, it may 
delete the whole file. 

=cut

register 'service.sed' => {
    name => 'Replace Strings',
    form => '/forms/sed.js',
    handler => \&run 
};

sub run {
    my ($self,$c,$config) =@_;

    my $stash = $c->stash;
    my $job = $stash->{job};
    my $log = $job->logger;
    my $stmt  = $stash->{current_statement_name};

    $log->info( _loc('*%1* starting', $stmt ) );

    my $path = $config->{path} 
        or _fail _loc('*%1* Missing or invalid path in configuration', $stmt);

    -e $path or _fail _loc "*%1* Invalid path '%1'", $stmt, $path;

    # check config
    my $sed = {
        patterns => $config->{patterns},
        includes => $config->{includes},
        excludes => $config->{excludes},
        slurp   => (length $config->{slurp} && $config->{slurp} =~/1|on/ ? 1 : 0) ,
    };

    # recurse
    my $cnt = 0;
    my @mods;
    my $dir = Path::Class::dir( $path );
    my @log;
    $dir->recurse( callback=>sub{
        my $f = shift;
        return if $f->is_dir;

        # find matching sed
        push @log, "Checking $f...";
        for my $in ( _array( $sed->{includes} ) ) {
            if( $f !~ /$in/ ) {
                push( @log, "Not included $f...");
                return; 
            }
        }
        for my $ex ( _array( $sed->{excludes} ) ) {
            if(  $f =~ /$ex/ ) {
                push( @log, "Excluded $f...");
                return;
            }
        }
        push @log, "processing: $f";
        my $ret = $self->process_file( stash=>$stash, file=>$f, patterns=>$sed->{patterns}, slurp=>$sed->{slurp} );
        $cnt += $ret;
        push @mods, "$f ($ret)" if $ret;
    });

    $log->debug( _loc('*%1* include/exclude.', $stmt), data=>join("\n", @log ) ); 
    $log->info( _loc('*%1* changes.', $stmt), data=>_dump(\@mods) ) if @mods;
    _debug _dump \@mods if @mods;
    $log->info( _loc('*%1* finished. Changed %2 file(s).', $stmt, scalar(@mods)) );
}

=head2 process_file

Modify a file with a evalled pattern:

    $self->process_file( file=>$full_path_to_file, pattern=>'s{text}{newtext}g' );

Returns the count of substitutions in the file (0 to n).

=cut
sub process_file {
    my ($self, %p ) = @_;
    my $file = $p{file} or _throw _loc('Missing file parameter');

    # save date
    my @stat = stat $file;
        # slurp in
    open my $fin, '<', $file or _throw _loc('Sed: failed to open file "%1": %2', $file, $!);
        # process
    my $cnt = 0;

    #_debug "Processing file $file with $p{patterns}";
    my $sed_sub = sub { 
        my $data = shift;
        
        # parse vars from stash
        my $parsed = Util->parse_vars( $data, $p{stash} ) if ref $p{stash};
        $cnt++ if $data ne $parsed;
        $data = $parsed;

        # run substitutions on parsed vared values, if any
        for my $re ( _array $p{patterns} ) {
            $cnt += eval q{$data =~ }.$re;
        }
        return $data;
    };
    if( $p{slurp} ) {
        my $data = join'',<$fin>;
        close $fin;
        $data = $sed_sub->($data);
        # slurp out 
        open my $fout, '>', $file or _fail _loc('Sed: failed to write to file "%1": %2', $file, $!);;
        print $fout $data;
        close $fout;
    } 
    else {
        my $tmpfile = file $file . '-' . $$ . '.bak';
        open my $fout, '>', $tmpfile or _fail _loc('Sed: failed to write to file "%1": %2', $tmpfile, $!);;
        while( <$fin> ) {
            print $fout $sed_sub->($_)
        }
        close $fout;
        unlink $file;
        rename $tmpfile, $file;
    }
    # reset date
    utime $stat[8], $stat[9], $file;
    return $cnt;
}

1;
