package Baseliner::Role::Filesys;
use Moose::Role;
use Baseliner::Utils;
use Path::Class;
use namespace::autoclean;

requires 'execute';
requires 'put';
requires 'get';
requires 'copy';
requires 'mkpath';

sub send_dir {
    my ($self, %p ) = @_;
    my $from = dir( $p{from} );
    my $to = dir( $p{to} ) or _throw 'Missing parameter to';

    my @dirs;
    my @files;
    $from->recurse( callback=>sub{
        my $f = shift;
        $f->is_dir
            ? push(@dirs, $f->relative( $from ) )
            : push(@files, $f->relative( $from ) );
        $f->is_dir
            ? _log("DIR : $f")
            : _log("FILE: $f");
    });

    # create dirs 
    for( @dirs ) {
        next if $_ eq '.';
        #$self->mkpath( "$_" ); 
    }

    # send files
    for( @files ) {
        _log "PUT $_";
        $self->get( from=>"$_" );
    }
}

1;

