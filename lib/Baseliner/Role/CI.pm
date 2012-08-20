package Baseliner::Role::CI;
use Moose::Role;

use Moose::Util::TypeConstraints;

subtype CI => as 'Baseliner::Role::CI';
coerce 'CI' =>
  from 'Num' => via { Baseliner::CI->new( $_ ) }; 

has mid => qw(is rw isa Num);

requires 'icon';
#requires 'collection';

has job     => qw(is rw isa Baseliner::Role::JobRunner),
    lazy    => 1,
    default => sub {
        require Baseliner::Core::JobRunner;
        Baseliner::Core::JobRunner->new;
    };

# methods 
sub has_bl { 1 } 
sub icon_class { '/static/images/ci/class.gif' }

sub collection {
    my $self = shift;
    ref $self and $self = ref $self;
    my ($collection) = $self =~ /^BaselinerX::CI::(.+?)$/;
    $collection =~ s{::}{/}g;
    return $collection;
}

sub save {
    use Baseliner::Utils;
    use Baseliner::Sugar;
    my ( $self, %p ) = @_;
    my ($mid,$name,$data,$bl,$active) = @{\%p}{qw/mid name data bl active/};
    my $collection = $self->collection;
    my $ret = $mid;

    # transaction bound, in case there are foreign tables
    Baseliner->model('Baseliner')->txn_do(sub{
        if( length $mid ) { 
            ######## update
            _debug "****************** CI UPDATE: $mid";
            my $row = Baseliner->model('Baseliner::BaliMaster')->find( $mid );
            $row->bl( join ',', _array $bl ) if defined $bl; # TODO mid rel bl (bl) 
            $row->name( $name ) if defined $name;
            $row->active( $active ) if defined $active;
            $row->update;
            if( $row ) {
                $self->save_data( $row, $data );
                ##_log _dump { $row->get_columns };
            }
            else {
                _fail _loc "Could not find master row for mid %1", $mid;
            }
        } else {  
            ######## new
            _debug "****************** CI NEW: $collection";
            my $row = Baseliner->model('Baseliner::BaliMaster')->create({
                collection => $collection, name=> $name, active => $active,
            });
            my $mid = $row->mid;
            $row->bl( join ',', _array $bl ) if defined $bl; # TODO mid rel bl (bl) 
            if( defined $name ) {
                $row->name( $name );
            } else {
                $row->name( "${collection}:${mid}" );
            }
            $self->save_data( $row, $data );
            $ret = $row->mid;
        }
    });
    return $ret;  # mid
}

# save data to table or yaml
sub save_data {
    my ( $self, $master_row, $data ) = @_;
    return unless ref $data;
    my $storage = $self->storage;
    if( $storage eq 'yaml' ) {
        _debug "------------>" . _dump( $data );
        $master_row->yaml( _dump( $data ) );
        $master_row->update;
    }
    elsif( $storage eq 'fields' ) {
       # TODO  
    }
    else {  # dbic result source
        my $rs = Baseliner->model("Baseliner::$storage");
        $data->{name} //= $master_row->name;
        my $pk = $self->storage_pk;
        $data->{ $pk } //= $master_row->mid;
        $self->table_update_or_create( $rs, $master_row->mid, $data );
    }
    return $master_row->mid;
}

sub table_update_or_create {
    my ($self, $rs, $mid, $data ) = @_;
    # find or create
    if( my $row = $rs->find( $mid ) ) {
        return $self->table_update( $row, $data );
    } else {
        return $self->table_create( $rs, $data );
    }
} 
sub table_create { $_[1]->create( $_[2] ) } 
sub table_update { $_[1]->update( $_[2] ) } 

sub load {
    use Baseliner::Utils;
    my ( $self, $mid ) = @_;
    $mid ||= $self->mid;
    _fail _loc( "Missing mid %1", $mid ) unless length $mid;
    my $row = Baseliner->model('Baseliner::BaliMaster')->find( $mid );
    _fail _loc( "Master row not found for mid %1", $mid ) unless ref $row;
    # find class, so that we are subclassed correctly
    my $class = "BaselinerX::CI::" . $row->collection;
    # fix static generic calling from Baseliner::CI
    $self = $class if $self eq 'Baseliner::Role::CI';
    # get my storage type
    my $storage = $class->storage;
    # setup the base data from master row
    my $data = { $row->get_columns };
    if( $storage eq 'yaml' ) {
        $data = { %$data, %{ _load( $row->yaml ) || {} } };
    }
    elsif( $storage eq 'fields' ) {
       # TODO  
    }
    else {  # dbic result source
        my $rs = Baseliner->model("Baseliner::$storage");
        my $storage_row = $rs->find( $mid );
        my %tab_data = ref $storage_row ? $storage_row->get_columns : ();
        $data = { %$data, %tab_data };
    }
    $data->{mid} //= $mid;
    $data->{ci_form} //= $self->ci_form;
    $data->{ci_class} //= $class;
    return $data;
}

sub ci_form {
    my ($self) = @_;
    my $component = sprintf "/ci/%s.js", $self->collection;
    my $fullpath = Baseliner->path_to( 'root', $component );
    return -e $fullpath  ? $component : '';
}

sub storage { 'yaml' }   # ie. yaml, fields, BaliUser, BaliProject
sub storage_pk { 'mid' }  # primary key (mid) column for foreing table

# from Node
has uri      => qw(is rw isa Str);   # maybe a URI someday...
has resource => qw(is rw isa Baseliner::CI::URI), 
                handles => qr/.*/;

has debug => qw(is rw isa Bool), default=>sub { $ENV{BASELINER_DEBUG} };


1;

