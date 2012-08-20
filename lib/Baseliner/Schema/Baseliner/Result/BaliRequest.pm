package Baseliner::Schema::Baseliner::Result::BaliRequest;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliRequest

=cut

__PACKAGE__->table("bali_request");

=head1 ACCESSORS

=head2 id

  data_type: NUMBER
  default_value: undef
  is_auto_increment: 1
  is_nullable: 0
  size: 38

=head2 ns

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 0
  size: 1024

=head2 bl

  data_type: VARCHAR2
  default_value: *
  is_nullable: 1
  size: 50

=head2 requested_on

  data_type: DATE
  default_value: undef
  is_nullable: 1
  size: 19

=head2 finished_on

  data_type: DATE
  default_value: undef
  is_nullable: 1
  size: 19

=head2 status

  data_type: VARCHAR2
  default_value: pending
  is_nullable: 1
  size: 50

=head2 finished_by

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 255

=head2 requested_by

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 255

=head2 action

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 255

=head2 id_parent

  data_type: NUMBER
  default_value: undef
  is_nullable: 1
  size: 38

=head2 key

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 255

=head2 name

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 255

=head2 type

  data_type: VARCHAR2
  default_value: approval
  is_nullable: 1
  size: 100

=head2 id_wiki

  data_type: NUMBER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 1
  size: 126

=head2 id_job

  data_type: NUMBER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 1
  size: 126

=head2 data

  data_type: CLOB
  default_value: undef
  is_nullable: 1

=head2 callback

  data_type: VARCHAR2
  default_value: undef
  is_nullable: 1
  size: 1024

=head2 id_message

  data_type: NUMBER
  default_value: undef
  is_nullable: 1
  size: 126

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => 38,
  },
  "ns",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "bl",
  { data_type => "VARCHAR2", default_value => "*", is_nullable => 1, size => 50 },
  "requested_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "finished_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "status",
  {
    data_type => "VARCHAR2",
    default_value => "pending",
    is_nullable => 1,
    size => 50,
  },
  "finished_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "requested_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "action",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "id_parent",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 38 },
  "key",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "type",
  {
    data_type => "VARCHAR2",
    default_value => "approval",
    is_nullable => 1,
    size => 100,
  },
  "item",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "id_wiki",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 126,
  },
  "id_job",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 126,
  },
  "data",
  {
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
  },
  "callback",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "id_message",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "projects",
  "Baseliner::Schema::Baseliner::Result::BaliProjectItems",
  { "foreign.ns" => "self.ns" },
);

use Baseliner::Utils;
use Try::Tiny;

sub data_hash {
    my $self = shift;
    my $data = $self->data;
    return {} unless $data;
    return _load( $data );
}

=head2 load_data

Return ns info and localization into the data field.

    no_data => 1  - no $self->data($data) loading (slow)

=cut
sub load_data {
    my ($self, %p ) = @_;
    my $data = {};
    if( exists $p{data}  ) {
        $data = ref $p{data} ? $p{data} : _load( $p{data} ); 
    } elsif( length $self->data ) {
        $data = _load( $self->data );
    } elsif( $p{no_data} ) {
        my $db = Baseliner->model('Baseliner')->dbi;
        $data = $db->value('select data from bali_request where id=?', $self->id );
        $data = _load( $data ) if $data;
    }

    # get ns data only if needed
    unless( $data->{ns_name} && $data->{ns_icon} ) {
        my $namespaces = $p{model_namespaces} || Baseliner->model('Namespaces'); # for perf
        # get the request ns
        my $nsid = exists $p{data} ? $data->{ns} : $self->ns;
        my $ns = try { $namespaces->get( $nsid ) } catch { };
        my ($ns_name, $ns_icon );
        if( ref $ns ) {
            $ns_name = $ns->ns_name . " (" . $ns->ns_type . ")";
            $ns_icon = try { $ns->icon } catch { '' };
        } else {
            _log _loc "Error: request %1 has an invalid namespace %2", $self->id, $self->ns;
            $ns = {};
            my $domain;
            ($domain, $ns_name)  = ns_split $nsid; 	
            $ns_icon = try {
                Baseliner->model('Registry')->get( 'namespace.endevor.package' )->registry_node->instance->module->icon
            } catch {
                '/static/images/icons/help.png';
            };
        }
        # get the request ns name and icon
        $data = {
           %$data,
           %$ns,
           ns_name => $ns_name, 
           ns_icon => $ns_icon,
        };
    } 

    # localize
    $data->{type} ||= _loc( exists $p{data} ? $data->{type} : $self->type );
    $self->data( $data ) unless exists $p{data} || $p{no_data};
    return $data;
}

=head2 save_data

Push ns info and localization into the data field.

Returns the data hash. 

=cut
sub save_data {
    my ($self, %p ) = @_;
    if( my $data = $self->load_data ) {
        $self->data( _dump( $data ) );
        $self->update;
        return $data;
    }
}

1;
