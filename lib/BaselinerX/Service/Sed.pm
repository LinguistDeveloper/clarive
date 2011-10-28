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

register 'config.sed' => {
    name => 'Sed replace configuration',
    metadata => [
        { id=>'map', label=>'Sed map array of hashes', type=>'eval'  },
        { id=>'paths', label=>'Sed File Path Regex Array (OR)' },    
        { id=>'excludes', label=>'Sed File Path Exclude Regex Array (OR)' },    
        { id=>'patterns', label=>'Sed Substitute pattern Regex', type=>'array' },
    ]
};
register 'service.sed' => {
    name => 'Job Service for Replacing Characters in files',
    config=> 'config.sed',
    handler => \&run 
};

sub run {
    my ($self,$c,$config) =@_;

    my $job = $c->stash->{job};
    my $log = $job->logger;
    $log->info( _loc('Starting service Sed') );
    my $path = $config->{path} || $job->job_stash->{path}
        or _throw 'Invalid job path in stash';

    -e $path or _throw _loc "Invalid path '%1'", $path;

    # check config
    my $map = $config->{'map'};
    unless( ref $map  eq 'ARRAY' ) {
        $log->info('Sed array map not set or incorrect. Exiting');
        return;
    }

    # recurse
    my $cnt = 0;
    my @mods;
    my $dir = Path::Class::dir( $path );
    $dir->recurse( callback=>sub{
        my $f = shift;
        return if $f->is_dir;

        # find matching sed
        for my $sed ( _array $map ) {
            _debug "Checking $f...";
            my $path_ok = eval {
                return 1 unless defined $sed->{include};
                return 1 if $f =~ $sed->{include};
            };
            _debug("Not included $f..."), return unless $path_ok;
            _debug("Excluded $f..."), return
                if defined $sed->{exclude} && $f =~ $sed->{exclude};
            my $ret = $self->process_file( file=>$f, patterns=>$sed->{pattern}, slurp=>$sed->{slurp} );
            $cnt += $ret;
            push @mods, "$f ($ret)" if $ret;
        }
    });

    $log->info( _loc('Sed service file changes.', data=>_dump(\@mods) )) if @mods;
    _debug _dump \@mods if @mods;
    $log->info( _loc('Sed service finished. Changed %1 file(s).', scalar(@mods) ));
}

=head2 process_file

Modify a file with a evalled pattern:

    $self->process_file( file=>$full_path_to_file, pattern=>'s{text}{newtext}g' );

Returns the count of substitutions in the file (0 to n).

=cut
sub process_file {
    my ($self, %p ) = @_;
    my $file = $p{file} or _throw _loc('Missing file parameter');
    _debug "Changing file $file";
    #XXX better process line by line on live file to reduce ram
    # save date
    my @stat = stat $file;
        # slurp in
    open my $fin, '<', $file or _throw _loc('Sed: failed to open file "%1": %2', $file, $!);
        # process
    my $cnt = 0;
    my @mods;

    _debug "Processing file $file with $p{patterns}";
    my $sed_sub = sub { 
        my $data = shift;
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
        open my $fout, '>', $file or _throw _loc('Sed: failed to write to file "%1": %2', $file, $!);;
        print $fout $data;
        close $fout;
    } 
    else {
        my $tmpfile = file $file . '-' . $$ . '.bak';
        open my $fout, '>', $tmpfile or _throw _loc('Sed: failed to write to file "%1": %2', $tmpfile, $!);;
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
