package Baseliner::Schema::Baseliner::Result::BaliSem;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_sem");
__PACKAGE__->add_columns(
  "sem",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "description",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
  "slots", { data_type => "NUMBER", default_value => 1, is_nullable => 1, size => 126 },
  "active", { data_type => "NUMBER", default_value => 1, is_nullable => 1, size => 126 },
  "bl",
  {
    data_type => "VARCHAR2",
    default_value => "*",
    is_nullable => 0,
    size => 255,
  },
  "queue_mode",
  {
    data_type => "VARCHAR2",
    default_value => "slot",
    is_nullable => 0,
    size => 255,
  },
);

__PACKAGE__->set_primary_key("sem", "bl");

__PACKAGE__->has_many(
  "queue",
  "Baseliner::Schema::Baseliner::Result::BaliSemQueue",
  { "foreign.sem" => "self.sem" },
);

sub bl_queue {
    my ($self) = @_;
    my $bl = $self->bl; 
    
    if( $bl eq '*' ) {
        return $self->queue->search({ sem => $self->sem, bl=>'*' });
    } else {
        return $self->queue->search({ sem => $self->sem, bl => $bl });
    }
}

sub occupied {
    my ($self) = @_;
    return $self->bl_queue->search({ status=>['granted', 'busy'], active=>1 })->count;
}

sub waiting {
    my ($self) = @_;
    return $self->bl_queue->search({ status=>['waiting'], active=>1 })->count;
}

1;

