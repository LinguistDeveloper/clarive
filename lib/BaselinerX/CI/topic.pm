package BaselinerX::CI::topic;
use Baseliner::Moose;
with 'Baseliner::Role::CI::Topic';

has title       => qw(is rw isa Any);
has id_category => qw(is rw isa Any);
has name        => qw(is rw isa Any);
has category    => qw(is rw isa Any);
#has_ci 'projects';

sub rel_type {
    { 
        projects => [ from_mid => 'topic_project' ] ,
    };
}


sub icon { '/static/images/icons/topic.png' }

around delete => sub {
    my ($orig, $self, $mid ) = @_;
    $mid = $mid // $self->mid;
    # if( DB->BaliTopic->find( $mid ) ) {
    #     Baseliner->model('Topic')->update({ topic_mid=>$mid, action=>'delete' });
    # }
	my $cnt = $self->$orig($mid);
};
    
around load => sub {
    my ($orig, $self ) = @_;
    my $data = $self->$orig();
    $data = { %$data, %{ Baseliner->model('Topic')->get_data( undef, $self->mid, with_meta=>1 ) || {} } };
    #$data->{category} = { DB->BaliTopic->find( $self->mid )->categories->get_columns };
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
    return sprintf '%s #%s - %s', 'Cmbio', $self->mid, $self->name; 
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
1;
