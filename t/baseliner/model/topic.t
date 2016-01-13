use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup qw(_topic_setup _setup_clear _setup_user);
use TestUtils;

use Baseliner::Role::CI;
use Baseliner::Core::Registry;
use BaselinerX::Type::Event;
use BaselinerX::Type::Statement;
use BaselinerX::Type::Event;
use Baseliner::Utils qw(_load);

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

subtest 'get_short_name: returns same name when no category exists' => sub {
    my $topic = _build_model();

    is $topic->get_short_name(name => 'foo'), 'foo';
};

subtest 'get_short_name: returns acronym' => sub {
    _setup();

    mdb->category->insert( { id => 1, name => 'Category', acronym => 'cat'} );

    my $topic = _build_model();

    is $topic->get_short_name(name => 'Category'), 'cat';
};

subtest 'get_short_name: returns auto acronym when does not exist' => sub {
    _setup();

    mdb->category->insert( { id => 1, name => 'Category'} );

    my $topic = _build_model();

    is $topic->get_short_name(name => 'Category'), 'C';
};

subtest 'get_short_name: returns auto acronym when does not exist removing special characters' => sub {
    _setup();

    mdb->category->insert( { id => 1, name => 'C123A##TegoRY'} );

    my $topic = _build_model();

    is $topic->get_short_name(name => 'C123A##TegoRY'), 'CATRY';
};

subtest 'get meta returns meta fields' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $meta = Baseliner::Model::Topic->new->get_meta( $topic_mid );

    is ref $meta, 'ARRAY';

    my $fieldlets = TestSetup->_fieldlets();
    my @fields = map { $$_{attributes}{data}{id_field} } @$fieldlets;
    my @fields_from_meta = map { $$_{id_field} } @$meta;
    is_deeply \@fields_from_meta, ['category',@fields];
};

subtest 'include into fieldlet gets its topic list' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my ( undef, $topic_mid2 ) = Baseliner::Model::Topic->new->update({ %$base_params, parent=>$topic_mid, action=>'add' });
    my $field_meta = { include_options=>'all_parents' }; 
    my $data = { category=>{ is_release=>0, id=>$base_params->{category} }, topic_mid=>$topic_mid2 }; 
    my ($is_release, @parent_topics) = Baseliner::Model::Topic->field_parent_topics($field_meta,$data);

    ok scalar @parent_topics == 1;
    is $parent_topics[0]->{mid}, $topic_mid;
};

subtest 'include into fieldlet filters out releases' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my $rel_cat = TestSetup->_topic_release_category($base_params);
    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, category=>$rel_cat, action=>'add' });
    my ( undef, $topic_mid2 ) = Baseliner::Model::Topic->new->update({ %$base_params, parent=>$topic_mid, action=>'add' });

    my $field_meta = { include_options=>'none' }; 
    my $data = { category=>{ is_release=>0, id=>$base_params->{category} }, topic_mid=>$topic_mid2 }; 
    my ($is_release, @parent_topics) = Baseliner::Model::Topic->field_parent_topics($field_meta,$data);

    ok scalar @parent_topics == 0;
};

subtest 'upload: related field NOT exists for upload file' => sub {
    _setup_clear();
    _setup_user();

    my $base_params = _topic_setup();
    my $topic       = _build_model();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'not_exists_this_id', qqfile => 'testFile.fake', topic_mid => "$topic_mid" };

    my $file = Util->_file( Util->_tmp_dir . '/fakefile.txt' );
    my %res = $topic->upload( f => $file, p => $params, username => 'root' );

    like $res{msg}, qr/related field does not exist for the topic/;
};

subtest 'upload: file not exists for upload file' => sub {
    _setup_clear();
    _setup_user();

    my $base_params = _topic_setup();
    my $topic       = _build_model();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params    = { filter => 'test_file', qqfile => 'testFile.fake', topic_mid => "$topic_mid" };
    my $temp_file = Util->_tmp_dir . '/fakefile.txt';
    my $file      = Util->_file($temp_file);

    my %res = $topic->upload( f => $file, p => $params, username => 'root' );
    $file->remove();
    like $res{msg}, qr/file $temp_file does not exis/;
};

subtest 'upload: upload file complete' => sub {
    _setup_clear();
    _setup_user();

    my $base_params = _topic_setup();
    my $topic       = _build_model();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'test_file', qqfile => 'testFile.fake', topic_mid => "$topic_mid" };

    my $file = Util->_file( Util->_tmp_dir . '/fakefile.txt' );
    open my $f, '>', $file or _throw _loc( "Could not open file %1: %2", $file, $! );
    $f->print("Fake test file");
    $f->close();

    my %res = $topic->upload( f => $file, p => $params, username => 'root' );
    $file->remove();

    is $res{success}, 'true';
};

subtest 'save_data: check master_rel for from_cl and to_cl from set_topics' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my ( undef, $topic_mid2 ) = Baseliner::Model::Topic->new->update({ %$base_params, parent=>$topic_mid, action=>'add' });
    my $doc = mdb->master_rel->find_one({ from_mid=>"$topic_mid", to_mid=>"$topic_mid2" });
    is $doc->{from_cl}, 'topic';
    is $doc->{to_cl}, 'topic';
};

subtest 'save_data: check master_rel for from_cl and to_cl from set_projects' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $doc = mdb->master_rel->find_one({ from_mid=>"$topic_mid" });
    is $doc->{from_cl}, 'topic';
    is $doc->{to_cl}, 'project';
};

subtest 'update: creates correct event.topic.create' => sub {
    _setup();

    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );

    my $event = mdb->event->find_one( { event_key => 'event.topic.create' } );
    my $event_data = _load $event->{event_data};

    my $topic = mdb->master->find_one( { mid => "$topic_mid" } );
    my $category = mdb->category->find_one;

    is $event_data->{mid},           $topic_mid;
    is $event_data->{title},         $topic->{title};
    is $event_data->{topic},         $topic->{title};
    is $event_data->{name_category}, $category->{name};
    is $event_data->{category},      $category->{name};
    is $event_data->{category_name}, $category->{name};
    is_deeply $event_data->{notify_default}, [];
    like $event_data->{subject}, qr/New topic: Category #\d+/;
    is_deeply $event_data->{notify},
      {
        'project'         => [ $base_params->{project} ],
        'category_status' => $category->{statuses}->[0],
        'category'        => $category->{id}
      };
};

done_testing();

sub _setup {
    mdb->category->drop;

    mdb->event->drop;
}

sub _build_model {
    return Baseliner::Model::Topic->new;
}
