use strict;
use warnings;

use Test::More;
use Test::Fatal;

use lib 't/lib';
use TestEnv;
use TestSetup qw(_topic_setup _setup_clear _setup_user);
use TestUtils;

use Baseliner::Role::CI;
use Baseliner::Core::Registry;
use BaselinerX::Type::Event;
use BaselinerX::Type::Statement;

TestEnv->setup;

use BaselinerX::Type::Event;
use_ok 'Baseliner::Model::Events';
use_ok 'Baseliner::Model::Topic';

subtest 'get next status for user' => sub {
    _setup_clear();
    _setup_user();
    my $base_params = _topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $id_status_from = $base_params->{status_new};
    my $id_status_to   = ci->status->new( name=>'Dev', type => 'I' )->save;

    # create a workflow
    my $workflow = [{ id_role=>'1', id_status_from=> $id_status_from, id_status_to=>$id_status_to, job_type=>undef }];
    mdb->category->update({ id=>"$base_params->{category}" },{ '$set'=>{ workflow=>$workflow }, '$push'=>{ statuses=>$id_status_to } });

    my @statuses = model->Topic->next_status_for_user(
        username       => 'root',
        id_category    => $base_params->{category},
        id_status_from => $id_status_from, 
        topic_mid      => $topic_mid
    );

    my $transition = shift @statuses;
    is $transition->{id_status_from}, $id_status_from;
    is $transition->{id_status_to}, $id_status_to;
};

###################################################
#

done_testing();
