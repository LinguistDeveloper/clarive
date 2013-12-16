package BaselinerX::CI::topic;
use Baseliner::Moose;
with 'Baseliner::Role::CI::Topic';

has title       => qw(is rw isa Any);
has id_category => qw(is rw isa Any);
has name        => qw(is rw isa Any);
has category    => qw(is rw isa Any);
has name_category    => qw(is rw isa Any);
has id_category_status => qw(is rw isa Any);

#has_ci 'projects';
#has_cis 'jobs';

sub rel_type {
    { 
        projects => [ from_mid => 'topic_project' ] ,
        #jobs     => [ to_mid => 'job_changeset' ] ,
    };
}


sub icon { '/static/images/icons/topic.png' }

around delete => sub {
    my ($orig, $self, $mid ) = @_;
    $mid = $mid // $self->mid;
    DB->BaliTopic->search({ mid=>$mid })->delete if length $mid;
	my $cnt = $self->$orig($mid);
};
    
# adds extra data to _ci during loading
around load_post_data => sub {
    my ($orig, $class, $mid ) = @_;
    return {} unless $mid;
    my $data = Baseliner->model('Topic')->get_data( undef, $mid, with_meta=>1 );
    delete $data->{mid};
    return $data;
};

sub files {
    my $self  = shift;
    my @files = Baseliner->model( 'Baseliner::BaliMasterRel' )->search(
        {from_mid => [ $self->mid ], rel_type => 'topic_file_version'},
        {

            #                join    => [ 'topic_file_version_to' ],
            join    => {'topic_file_version_to' => {'file_projects' => {'directory'}}},
            +select => [
                'topic_file_version_to.filename', 'max(topic_file_version_to.versionid)',
                'max(topic_file_version_to.mid)', 'max(directory.name)'
            ],
            +as      => [ 'filename', 'version', 'mid', 'path' ],
            group_by => 'topic_file_version_to.filename',
        }
    )->hashref->all;
    return @files;
} 

sub topic_name {
    my ($self) = @_;
    return sprintf '%s #%s - %s', $self->name_category, $self->mid, ( $self->title // $self->name ); 
}

sub timeline {
    my ($self, $p) = @_;
    
    my @data;
    
    # master cal entries
    my @cal =
        DB->BaliMasterCal->search( { mid => $self->mid }, { order_by => { -asc => 'start_date' } } )->hashref->all;
    push @data, map {
        my $start = $_->{plan_end_date};
        my $end = $_->{end_date} // '';
        if( $end && $end < $start ) {  # if earlier, switch
            my $old=$end;
            $end=$start;
            $start=$old;
        }
        
        +{
            start         => $start,
            $end ? ( end => $end ) : (),
            instant       => $end ? \0 : \1,
            durationEvent => $end ? \1 : \0,
            color         => "#c03020",
            textColor     => "#000000",

            #classname => "special_event2 aquamarine",
            title       => $_->{slotname},
            caption     => $_->{slotname},
            description => $_->{slotname},
        }
    } grep { $_->{plan_end_date} } @cal;
    
    # events
    my %events = map { $_->{text} => $_ } @{ Baseliner::Sugar::events_by_mid( $self->mid ) };
    push @data, map {
        my $start = $_->{ts};
        +{
            start         => $start,
            instant       => \1,
            durationEvent => \0,
            color         => "#30c020",
            textColor     => "#444",
            #classname => "special_event2 aquamarine",
            title       => $_->{text},
            caption     => $_->{text},
            description => $_->{text},
        }
    } values %events; 
    
    my %same_date;
    $same_date{ substr($_->{start},0,10) }+=1 for grep { $_->{start} } @data;
    my $max_same_date = ( sort { $b <=> $a } values %same_date )[0]; 
    my $k = 1;
    @data = map { $_->{trackNum}=$k++; $_ } sort { $a->{start} cmp $b->{start} } @data;
    return { events => \@data, max_same_date=>$max_same_date }
}

sub create_topic {
    my ($class, $p) = @_;
    my ($msg, $topic_mid, $status, $title) = Baseliner->model('Topic')->update({ action=>'add', %$p });
    { msg=>$msg, mid=>$topic_mid, status=>$status, title=>$title };
}

sub is_changeset {
    my ($self) = @_;
    my $row = DB->BaliTopic->search({ mid=> $self->mid},{ join=>'categories', select=>'categories.is_changeset', as=>'is_changeset' })->hashref->first;
    return $row ? $row->{is_changeset} : 0;
}

sub is_release {
    my ($self) = @_;
    my $row = DB->BaliTopic->search({ mid=> $self->mid},{ join=>'categories', select=>'categories.is_release', as=>'is_release' })->hashref->first;
    return $row ? $row->{is_release} : 0;
}

sub projects {
    my ($self) = @_;
    $self->related( rel_type=>'topic_project' );
} 

sub revisions {
    my ($self) = @_;
    $self->related( rel_type=>'topic_revision' );
} 

sub bl {
    my ($self)=@_;
    DB->BaliTopicStatus->find( $self->id_category_status )->bl;    
}

sub items {
    my ($self, %p) = @_;

    my ($project) = $self->projects;
    my @revisions = $self->revisions;
    my $type = $p{type} // 'promote';
    my $bl   = $p{bl} // $self->bl;
    
    my %repos;
    # group revisions by repo
    for my $rev ( @revisions ) {
        push @{ $repos{$rev->repo->mid}{revisions} }, $rev; 
        $repos{$rev->repo->mid}{repo} //= $rev->repo;
    }

    # repo by repo, get top items for revs given
    my @items;
    for my $repo_group ( values %repos ) {
        my ($revs,$repo) = @{ $repo_group }{qw/revisions repo/};
        my @repo_items = $repo->group_items_for_revisions( revisions=>$revs, type=>$type, path_prefix=>$p{path_prefix} );
    }
    return @items;
}

sub jobs {
    my ($self, $p )=@_;
    my @jobs = $self->parents( isa=>'job', %$p );
    wantarray ? @jobs : \@jobs;
}

sub is_in_active_job {
    my ($self )=@_;
    my @active_jobs;
    if ( $self->jobs ) {
        @active_jobs = grep { ref $_ eq 'BaselinerX::CI::job' && $_->is_active } $self->jobs;
    }
    return @active_jobs;
}

sub get_data {
    my ($self, $meta)=@_;
    Baseliner->model('Topic')->get_data( $meta, $self->mid, with_meta=>1 );
}

sub get_doc {
    my ($self, @rest)=@_;
    mdb->topic->find_one({ mid=>$self->mid }, @rest); 
}

sub get_meta {
    my ($self)=@_;
    my $mid = $self->mid if ref $self;
    Baseliner->model('Topic')->get_meta( $mid );
}

sub verify_integrity {
    my ($self)=@_;

    # delete rows in mongo not found in BaliTopic
    my $k = 0;
    my @docs = ci->topic->find->all;
    for (@docs) {
      my $row = DB->BaliTopic->find( $_->{mid} );
      if( !$row ) {
         warn "$_->{name} (#$_->{mid}) NOT FOUND in BaliTopic\n";
         $k++;
         mdb->topic->remove({ _id=> $_->{_id} });
      }
    }
    warn "Integrity check against BaliTopic done (invalid docs=$k).";
}

1;
