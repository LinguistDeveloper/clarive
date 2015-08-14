package BaselinerX::Service::RenameItems;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Carp;
use Try::Tiny;
use Path::Class;

with 'Baseliner::Role::Service';

register 'service.job.rename_items' => { 
    name    => 'Rename Baseline Items and Files',
    data    => { rename_items=>1, rename_files=>1 },
    icon    => '/static/images/icons/rename_items.png',
    #icon    => '/static/images/icons/baseline.gif',
    job_service  => 1,
    handler => \&run, 
};

sub run {
    my ($self,$c, $config)=@_;

    my $stash = $c->stash;
    my $job = $stash->{job};
    my $log = $job->logger;
    $self->log( $job->logger );
    my $bl = $job->bl;
    my $all_bls = join '|', grep !/^\*$/, map { $_->bl } BaselinerX::CI::bl->search_cis;

    my @files_renamed;
    if( $config->{rename_files} ) {
        $log->debug( _loc('Running file rename for baseline %1', $job->bl) );
        @files_renamed = $self->rename_files( bl=>$bl, all_bls=>$all_bls, path=>$job->job_dir );
    }
    
    my (@items_renamed, @items_removed );
    if( $config->{rename_items} ) {
        my @items;
        for my $item ( _array( $stash->{items} ) ) {
            my $path = $item->path; 
            if( $path =~ /{$bl}/ ) {
                my $old_path = $path;
                $item->rename( sub{ s/{$bl}//g } );
                push @items_renamed, { old=>$old_path, new=>$item->path };
                push @items, $item;
            } elsif( $path !~ /{($all_bls)}/ ) {
                push @items, $item;
            } else {
                push @items_removed, $path;
            }
        }
        $log->info( 
            _loc( 'Renamed %1 item(s), removed %2 item(s)', scalar(@items_renamed), scalar(@items_removed)), 
            { renamed=>\@items_renamed, removed=>\@items_removed, items=>[ map { $_->path } @items ] } )
            if @items_renamed;
        $stash->{items} = \@items;
    }
    return { files=>\@files_renamed, items=>\@items_renamed };
}

sub rename_files {
    my $self = shift;
    my $p = _parameters(@_);
    _check_parameters( $p, qw/path bl/ );
    return if $p->{bl} eq '*'; # WTF?
    _fail unless length $p->{path};
    my $bl = $p->{bl};
    my $all_bls = $p->{all_bls};
    
    my $dir = Path::Class::dir( $p->{path} );
    _fail _loc('Could not find rename root dir %1', $dir) unless -e $dir;
    my ($list, $list_del);
    my $cnt = 0;

    my @files_renamed;
    $dir->recurse( callback => sub {
            my $f = shift;
            my $path = $f->stringify;
            return if $path =~ m/system volume/i;
            return if $f->is_dir;
            my $file = $f->stringify ;
            my $new_name = $self->rename( $bl, $file );
            if( $file ne $new_name ) {
                if( -e $new_name ) {
                    unlink $new_name
                        or _throw _loc 'Could not delete file %1: %2',$new_name, $!;
                }
                rename $file, $new_name
                     or _throw _loc 'Could not rename element %1 to %2: %3', $file, $new_name, $!;
                $list .= "'$file' ==> '$new_name'\n";
                push @files_renamed, { old=>"$file", new=>"$new_name" };
                $cnt++;
            } 
            elsif( $file =~ /{($all_bls)}/ ) {
                # delete files from other baselines
                unlink $file or _throw _loc 'Could not delete file that belongs to another baseline %1: %2', $file, $!;
                $list_del .= "File '$file' deleted.\n";
            }
    });

    $self->log->info(_loc('Renamed %1 file(s)',$cnt), data=>$list ) if $list;
    $self->log->info(_loc('Deleted elements that belong to another baseline'), data=>$list_del ) if $list_del;
    return @files_renamed;
}

sub rename {
    my ($self, $bl, $item) = @_;
    my $newname = $item;
    $newname =~ s/{$bl}//g;
    $newname =~ s/{ALL}//g;
    $newname =~ s/{ANY}//g;
    return $newname;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 DESCRIPTION

Rename elements for a given baseline. Does it physically (files) and on the elements stash.

=cut
