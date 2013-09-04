package Baseliner::Schema::Baseliner::Result::BaliJob;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->load_components("+Baseliner::Schema::Master");

__PACKAGE__->table("bali_job");

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "mid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
  },
  "name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 45,
  },
  "starttime",
  {
    data_type => "DATE",
    default_value => \"SYSDATE",
    is_nullable => 0,
    size => 19,
  },
  "maxstarttime",
  {
    data_type => "DATE",
    default_value => \"SYSDATE",  # should be sysdate+1
    is_nullable => 0,
    size => 19,
  },
  "endtime",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "status",
  {
    data_type => "VARCHAR2",
    default_value => "READY",
    is_nullable => 0,
    size => 45,
  },
  "ns",
  { data_type => "VARCHAR2", default_value => "/", is_nullable => 0, size => 45 },
  "bl",
  { data_type => "VARCHAR2", default_value => "*", is_nullable => 0, size => 45 },
  "runner",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "pid",
  { data_type => "NUMBER", default_value => undef, is_nullable => 1, size => 38 },
  "comments",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "type",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "username",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "ts",
  {
    data_type => "DATE",
    default_value => \"SYSDATE",
    is_nullable => 1,
    size => 19,
  },
  "host",
  {
    data_type => "VARCHAR2",
    default_value => "localhost",
    is_nullable => 1,
    size => 255,
  },
  "owner",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "step",
  {
    data_type => "VARCHAR2",
    default_value => "PRE",
    is_nullable => 1,
    size => 50,
  },
  "id_stash",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 38,
  },
  "id_rule",
  {
    data_type => "NUMBER",
    is_nullable => 1,
  },
  "rollback",
  { data_type => "NUMBER", default_value => 0, is_nullable => 1, size => 126 },
  "now",
  { data_type => "NUMBER", default_value => 0, is_nullable => 1, size => 126 },
  "schedtime",
  {
    data_type => "DATE",
    default_value => \"sysdate",
    is_nullable => 1,
    size => 19,
  },
  "exec",
  { data_type => "NUMBER", default_value => 1, is_nullable => 1, size => 126 },
  "request_status",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "job_key",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 id_stash

Type: belongs_to

Related object: L<Baseliner::Schema::Baseliner::Result::BaliJobStash>

=cut

__PACKAGE__->belongs_to(
  "id_stash",
  "Baseliner::Schema::Baseliner::Result::BaliJobStash",
  { id => "id_stash" },
);

=head2 bali_job_items

Type: has_many

Related object: L<Baseliner::Schema::Baseliner::Result::BaliJobItems>

=cut

__PACKAGE__->has_many(
  "bali_job_items",
  "Baseliner::Schema::Baseliner::Result::BaliJobItems",
  { "foreign.id_job" => "self.id" },
);

=head2 bali_job_stashes

Type: has_many

Related object: L<Baseliner::Schema::Baseliner::Result::BaliJobStash>

=cut

__PACKAGE__->has_many(
  "bali_job_stashes",
  "Baseliner::Schema::Baseliner::Result::BaliJobStash",
  { "foreign.id_job" => "self.id" },
);

=head2 bali_log_datas

Type: has_many

Related object: L<Baseliner::Schema::Baseliner::Result::BaliLogData>

=cut

__PACKAGE__->has_many(
  "bali_log_datas",
  "Baseliner::Schema::Baseliner::Result::BaliLogData",
  { "foreign.id_job" => "self.id" },
);


sub is_not_running {
    my $self = shift;
    return $self->status !~ m/RUNNING/ ;
}

__PACKAGE__->belongs_to(
  "job_stash",
  "Baseliner::Schema::Baseliner::Result::BaliJobStash",
  { "foreign.id" => "self.id_stash" },
);

__PACKAGE__->has_many(
  "bali_log",
  "Baseliner::Schema::Baseliner::Result::BaliLog",
  { "foreign.id_job" => "self.id" },
);

__PACKAGE__->has_master;

sub sqlt_deploy_hook {
   my ($self, $sqlt_table) = @_;
   $sqlt_table->add_index(name =>'bali_job_idx_name', fields=>['name'] );
   $sqlt_table->add_index(name =>'bali_job_pid_status', fields=>['pid','status'] );
}

# this is the best way to avoid having more than one stash per job
#  and still maintain ref integrity 
use Try::Tiny;
use Baseliner::Utils;

sub stash {
    my ( $self, $data ) = @_;

    if( defined $data && $data ) {
        my $stash = $self->id_stash;
        if( ref $stash ) {
            $stash->stash( $data );
        } else {
            $stash = $self->bali_job_stashes->create({ stash => $data });
        }
        $stash->update;
        $self->id_stash( $stash->id );
        $self->update;
    } else {
        return try {
            my $stash = $self->job_stash; # the foreign key row
            ref $stash ? $stash->stash : undef;
        } catch {
            undef;
        };
    }
}

# adds a key-value to a stashed hash
sub stash_key {
    my ( $self, $key, $val ) = @_;
    my $stash =  $self->stash;
    if( defined $stash ) {
        try {
            $stash = _load( $stash );
            $stash->{$key} = $val;
            $self->stash( Baseliner::Utils::_dump( $stash ) );
        } catch {
            Baseliner::Utils::_throw( _loc('Could not update the stash with key %1: %2', $key, shift ) );
        };
    } else {
        # create the stash
        if( $key && defined $val ) {
            $stash = { $key => $val };
            $self->stash( Baseliner::Utils::_dump( $stash ) );
        }
    }
    return $stash;
}

sub last_log {
    my ( $self, $data ) = @_;

    my $logs = $self->bali_log->search( undef, { order_by => 'id desc' })->first;
    #my $max_id = $self->bali_log->get_column('id')->max;
    return $logs; 
}

sub last_log_message {
    my $self = shift;
    use Baseliner::Core::DBI;
    my $db = Baseliner::Core::DBI->new( dbi=>$self->result_source->storage->dbh );
    my $id = $self->id;
    return $db->value("select rtrim(text) from bali_log
        where id=(select max(id) from bali_log bl where bl.id_job=$id and bl.lev<>'debug')");
    #return bali_log->first->text
}

# is_active means it is ready to run, or running
sub is_active {
    my $self = shift;
    return $self->status =~ m/^IN-EDIT|^READY|^RUNNING|^PAUSED|^SUSPENDED|^WAITING/ ;
}

# returns the key column, if not exists then create it, commit and return
sub hash_key {
    my $self = shift;
    $self->job_key and return $self->job_key;
    $self->job_key( Baseliner::Utils::_md5 );
    $self->update;
}

1;
