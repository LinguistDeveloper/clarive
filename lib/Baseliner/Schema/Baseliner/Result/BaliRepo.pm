package Baseliner::Schema::Baseliner::Result::BaliRepo;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_repo");
__PACKAGE__->add_columns(
  #"id", { data_type => "integer", is_auto_increment => 1, is_nullable => 0, original => { data_type => "number" }, size => 38, },
  "ns",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "backend",
  {
    data_type => "VARCHAR2",
    default_value => 'default',
    is_nullable => 1,
    size => 1024,
  },
  "ts",
  {
    data_type => "DATE",
    default_value => \"SYSDATE",
    is_nullable => 1,
    size => 19,
  },
  "bl",
  {
    data_type => "VARCHAR2",
    default_value => '*',
    is_nullable => 1,
    size => 255,
  },
  "provider",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "item",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "class",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "data",
  {
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("ns");


__PACKAGE__->has_many(
  "keys",
  "Baseliner::Schema::Baseliner::Result::BaliRepoKeys",
  { "foreign.ns" => "self.ns" },
);

use Baseliner::Utils;
use namespace::clean;

sub hash {
    my ($self,%p) = @_;
    return _load( $self->data ) if defined $self->data;
    return {};
}

=head2 kv data=>HashRef, merge=>Bool, search=>HashRef, select=>ArrayRef

Load and store key-value data hashes.
   
Substitute data, deleting all previous data associated with the given row:

    $row->kv( data=>{ aa=>11 } );

Merge data in:

    $row->kv( data=>{ cc=>11 }, merge=>1 ); 

Search:

    my $hash = $row->kv( search=>{ cc=>11 } );

Select only given keys:

    my $hash = $row->kv( select=>['aa', 'bb' ] );

=cut
sub kv {
    my ($self,%p) = @_;
    my $data = $p{data};
    if( ref $data eq 'HASH' ) {
        $self->keys->delete unless $p{add} || $p{merge};
        for my $k ( keys %$data ) {
            my $datatype='';
            if( ref($data->{$k}) =~ /ARRAY|HASH/  ) {
                $data->{$k} = _dump $data->{$k};
                $datatype='yaml';
            }
            my $row = $self->keys->search({ k => $k })->first;
            if( ref $row ) {
                $row->datatype( $datatype );
                $row->v( $data->{$k} );
                $row->update;
            } else {
                $self->keys->create({ k => $k, v => $data->{$k}, datatype=>$datatype });
            }
        }
    } else {
        return $self->load_kv( %p );
    }
}

sub load_kv {
    my ($self,%p) = @_;
    my $data = {};
    my $rs;
    if( defined $p{search}  ) {
        $p{search} ||= {};
        $rs = $self->keys->search($p{search});
    } else {
        $rs = $self->keys;
    }
	$rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    while( my $r = $rs->next ) {
        next if defined $p{select}
            && !grep { lc $r->{k} eq $_ } _array( $p{select} );
        # deserialize if needed
        $r->{v} = _load( $r->{v} )
            if defined $r->{v} && $r->{datatype} eq 'yaml';
        $data->{ $r->{k} } = $r->{v} ;
    }
    return $data;
}

1;
