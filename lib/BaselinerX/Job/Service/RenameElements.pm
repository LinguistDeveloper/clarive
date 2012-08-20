package BaselinerX::Job::Service::RenameElements;
use Baseliner::Plug;
use Baseliner::Utils;
use Carp;
use Try::Tiny;
use Path::Class;
use utf8;

with 'Baseliner::Role::Service';

register 'service.job.elements.rename' => { name => 'Rename Files by Suffix', handler => \&run, };

sub run {
    my ($self,$c, $config)=@_;

    my $job = $c->stash->{job};
    my $log = $job->logger;
    $self->log( $job->logger );

    $log->debug( _loc('Running file rename for baseline %1', $job->bl) );
    $self->rename_files( bl=>$job->bl, path=>$job->job_stash->{path} );
}

sub rename_files {
    my $self = shift;
    my $p = _parameters(@_);
    _check_parameters( $p, qw/path bl/ );
    return if $p->{bl} eq '*'; # WTF?
    
    my $dir = Path::Class::dir( $p->{path} );
    my ($list, $list_del);

    $dir->recurse( callback => sub {
            my $f = shift;
            my $path = $f->stringify;
            return if $path =~ m/system volume/i;
            return if $f->is_dir;
            my $file = $f->stringify ;
            my $new_name = $self->rename( $p->{bl}, $file );
            if( $file ne $new_name ) {
                if( -e $new_name ) {
                    unlink $new_name
                        or _throw _loc 'Could not delete file %1: %2',$new_name, $!;
                }
                rename $file, $new_name
                     or _throw _loc 'Could not rename element %1 to %2: %3', $file, $new_name, $!;
                $list .= "File '$file' renamed to '$new_name'\n";
            } 
            elsif( $file =~ /{[A-Z]+}/ ) {
                # delete files from other baselines
                unlink $file or _throw _loc 'Could not delete file that belongs to another baseline %1: %2', $file, $!;
                $list_del .= "File '$file' deleted.\n";
            }
    });
    $self->log->info(_loc('Renamed elements'), data=>$list ) if $list;
    $self->log->info(_loc('Deleted elements that belong to another baseline'), data=>$list_del ) if $list_del;
    #TODO now rename elements from $job_stash->{elements};
}

sub rename {
    my ($self, $bl, $item) = @_;
    my $newname = $item;
    $newname =~ s/{$bl}//g;
    $newname =~ s/{ALL}//g;
    $newname =~ s/{ANY}//g;
    return $newname;
}

1;
__END__

=head1 DESCRIPTION

Rename elements for a given baseline. Does it physically (files) and on the elements stash.

=cut
