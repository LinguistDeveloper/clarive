package BaselinerX::Service::ChangesetServices;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;

#with 'Baseliner::Role::Namespace::Create';
with 'Baseliner::Role::Service';

register 'service.changeset.checkout' => {
    name    =>_loc('Checkout files of a changeset'),
    handler =>  \&checkout,
};

register 'service.changeset.job_elements' => {
    name    =>_loc('Fill job_elements'),
    handler =>  \&job_elements,
};

register 'service.changeset.update' => {
    name    =>_loc('Update Baselines'),
    handler =>  \&update_baselines,
};

sub checkout {
    my ($self, $c, $config ) = @_;
    my $job = $c->stash->{job};
    my $log = $job->logger;
    my $stash = $job->job_stash;
    my $bl = $job->bl;

    my $e = $job->job_stash->{elements};

    $log->debug( "Elements", data => _dump $e);
    my @eltos = $e->list( '' );
    
    my $checkout;

    for my $element ( @eltos ) {
        my $file = $c->model( 'Baseliner::BaliFileVersion' )->find( $element->{mid} );
        my $filepath = _file $job->root, $element->{path}, $element->{name};
        _mkpath( _file $job->root, $element->{path} );

        $log->debug( "Element $element->{mid}", data => _dump $element);

        open my $fout, '>', $filepath or _throw _loc('Changeset checkout: failed to write to file "%1": %2', $filepath, $!);;
        print $fout $file->filedata;
        close $fout;
        $checkout .= $filepath."\n";
    } 
    $log->info( _loc("Checked out files"), data => $checkout );
}

sub job_elements {
    my ( $self, $c, $config ) = @_;
    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $job->job_stash;
    my $bl    = $job->bl;
    my @changesets;

    for my $item ( _array $stash->{contents} ) {
        my $ns = ns_get $item->{item};
        next unless $ns->ns_type eq 'changeset';

        if ( $ns->{ns} =~ /.*\/(.*)$/ ) {
            my $mid = $1;
            $log->debug( "Changeset $mid detected for job");
            push @changesets, $mid;
        }

    } ## end for my $item ( _array $stash...)

    if ( $job->job_type eq 'demote' || $job->rollback ) {

    } else {
        my @versions = $c->model( 'Baseliner::BaliMasterRel' )->search(
            {from_mid => \@changesets, rel_type => 'topic_file_version'},
            {
                join => [ 'topic_file_version_to' ],
                +select => [ 'topic_file_version_to.filename', 'max(topic_file_version_to.versionid)', 'max(topic_file_version_to.mid)' ],
                +as     => [ 'filename','version','mid' ],
                group_by => 'topic_file_version_to.filename',
            }
        )->hashref->all;

        my @elems = map {
            BaselinerX::ChangesetElement->new( mid => $_->{mid}, fullpath=> "/changesets/".$_->{filename}, status=>'M', version=>$_->{version} );
        } @versions;
        my $e = $job->job_stash->{elements} || BaselinerX::Job::Elements->new;
        $e->push_elements( @elems );
        $job->job_stash->{elements} = $e;
        $log->info( _loc("Elements included in job"), data => join "\n", map { "M  ".$_->{filename}.":".$_->{version}} @versions);
    }


} ## end sub job_elements


sub update_baselines {
    my ( $self, $c, $config ) = @_;
    my $job      = $c->stash->{job};
    my $log      = $job->logger;
    my $stash    = $job->job_stash;
    my $bl       = $job->bl;
    my $job_type = $job->job_type;
    my $status   = $stash->{status_to};
    my @changesets;

    if ( $job_type eq 'static' ) {
        $self->log->info( _loc "Changesets status not updated. Static job." );
        return;
    }

    for my $item ( _array $stash->{contents} ) {

        if ( $item->{item} =~ /.*\/(.*)$/ ) {
            my $mid = $1;
            push @changesets, $mid;
        }
    } ## end for my $item ( _array $stash...)
    my $rs_changesets = $c->model( 'Baseliner::BaliTopic' )->search( mid => \@changesets );

    while ( my $row = $rs_changesets->next ) {
        $row->id_category_status( $status );
        $row->update;
        my $status_name = $c->model( 'Baseliner::BaliTopicStatus' )->find( $status )->name;        
        $log->info( _loc( "%1 %2 to %3", $job_type, $row->title, $status_name ) );
    }
} ## end sub update_baselines

package BaselinerX::ChangesetElement;
use Moose;
use Moose::Util::TypeConstraints;
use Baseliner::Utils;

with 'BaselinerX::Job::Element';

has mask => qw(is rw isa Str default /application/subapp/nature);
has sha => qw(is rw isa Str);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %p = @_;

    if( ! exists $p{path} && ! exists $p{name} ) {
        if(  $p{ fullpath } =~ /^(.*)\/(.*?)$/ ) {
            ( $p{path}, $p{name} ) = ( $1, $2 );
        } 
        else {
            ( $p{path}, $p{name} ) = ( '', $p{fullpath} );
        }
    }
    $self->$orig( %p );
};

1;
