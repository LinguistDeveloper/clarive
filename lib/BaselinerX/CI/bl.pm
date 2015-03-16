package BaselinerX::CI::bl;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging);
use Try::Tiny;
with 'Baseliner::Role::CI::Internal';

has bl          => qw(is rw isa Any default *);
has seq         => qw(is rw isa Any default 100);

sub icon { '/static/images/icons/baseline.gif' }
sub collection { 'bl' }
sub has_bl { 0 }

before save => sub {
    my ($self, $master_row, $data ) = @_;
    $self->moniker( $self->bl );
};
    
after save_data => sub {
    my ($self, $master_row, $data, $opts, $old ) = @_;
    # update statuses in topics
    if( $$opts{changed}{bl} && defined $$old{bl} ) {
        mdb->master_doc->update({ bl=>$$old{bl} },{ '$set'=>{ bl=>$self->bl } });
        mdb->topic->update({ bl=>$$old{bl} },{ '$set'=>{ bl=>$self->bl } });
        mdb->master_doc->update({ 'variables.'.$$old{bl} =>{'$exists'=>1} },
        { '$rename'=>{ 'variables.'.$$old{bl} =>'variables.'.$self->bl } },
        { multiple=>1 });
        cache->clear;
    }
};

1;
