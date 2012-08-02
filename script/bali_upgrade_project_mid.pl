{

    package Baseliner::Schema::Baseliner::Result::BaliOldProject;
    use strict;
    use warnings;
    use base 'DBIx::Class::Core';
    __PACKAGE__->load_components("InflateColumn::DateTime");
    __PACKAGE__->table("bali_project");
    __PACKAGE__->add_columns(
        "mid",
        { data_type => "numeric", is_nullable => 0, original => { data_type => "number" }, },
        "id",
        { data_type => 'integer', is_auto_increment => 1, is_nullable => 0, sequence => "bali_project_seq", },
        "name",
        { data_type => "varchar2", is_nullable => 0, size => 1024 },
        "data",
        { data_type => "clob", is_nullable => 1 },
        "ns",
        { data_type => "varchar2", default_value => "/", is_nullable => 1, size => 1024, },
        "bl",
        { data_type => "varchar2", default_value => "*", is_nullable => 1, size => 1024, },
        "ts",
        {   data_type     => "datetime",
            default_value => \"current_timestamp",
            is_nullable   => 1,
            original      => { data_type => "date", default_value => \"sysdate" },
        },
        "domain",
        { data_type => "varchar2", is_nullable => 1, size => 1 },
        "description",
        { data_type => "clob", is_nullable => 1 },
        "id_parent",
        { data_type => "numeric", is_nullable => 1, original => { data_type => "number" }, size => 126, },
        "nature",
        { data_type => "varchar2", is_nullable => 1, size => 1024 },
        "active",
        { data_type => "char", is_nullable => 1, size => 1, default => '1' },
    );
    __PACKAGE__->set_primary_key("id");

}


require Baseliner;
use Try::Tiny;
use Baseliner::Utils;
use Baseliner::Sugar;
my $c = 'Baseliner';

package main;

print "Baseliner BALI_PROJECT ID to MID migration.\n\n";
my $sch = $c->model('Baseliner');
$sch->schema->register_class( 'BO' => 'Baseliner::Schema::Baseliner::Result::BaliOldProject' );
my $rs  = $sch->resultset('BO');
my $dbh = $sch->storage->dbh;

try {
    $rs->search( undef, { select => ['id'] } );
    $dbh->do(q{ALTER TABLE bali_project ADD (mid number) });
}
catch {
    print "Update failed. No ID on BALI_PROJECT. You should be fine.\n\n";
    exit 1;
};
try {
    $dbh->do(q{DROP TABLE bali_project_items});
};
try {
    $dbh->do(q{ALTER TABLE bali_sqa DROP CONSTRAINT bali_sqa_fk});
};
my $projects = $rs->search();
while ( my $project = $projects->next ) {
    if ( $project->mid ) {

        ##BALI_PROJECT*****************************************************************************
        my $projects1 = $rs->search( { id_parent => $project->id } );
        while ( my $project1 = $projects1->next ) {
            $project1->id_parent( $project->mid * -1 );
            $project1->update();
        }
        ##*****************************************************************************************

        ##BALI_CONFIG******************************************************************************
        my $projects1 = $c->model('Baseliner::BaliConfig')->search( { ns => 'project/' . $project->id } );
        while ( my $project1 = $projects1->next ) {
            $project1->ns( '#project/' . $project->mid );
            $project1->update();
        }
        ##*****************************************************************************************


        ##BALI_ROLEUSER******************************************************************************
        my $projects1 = $c->model('Baseliner::BaliRoleuser')->search( { ns => 'project/' . $project->id } );
        while ( my $project1 = $projects1->next ) {
            $project1->ns( '#project/' . $project->mid );
            $project1->update();
        }
        ##*****************************************************************************************


        ##BALI_SQA*****************************************************************************
        my $projects1 = $c->model('Baseliner::BaliSqa')->search( { id_prj => $project->id } );
        while ( my $project1 = $projects1->next ) {
            $project1->id_prj( $project->mid * -1 );
            $project1->update();
        }
        ##*****************************************************************************************

    } else {
        _log "mid";
        my $project_mid = master_new 'bali_project' => sub {
            my $mid = shift;
            $project->mid($mid);
            $project->update();
        };

        ##BALI_PROJECT*****************************************************************************
        my $projects1 = $rs->search( { id_parent => $project->id } );
        while ( my $project1 = $projects1->next ) {
            $project1->id_parent( $project->mid * -1 );
            $project1->update();
        }
        ##*****************************************************************************************

        ##BALI_CONFIG******************************************************************************
        my $projects1 = $c->model('Baseliner::BaliConfig')->search( { ns => 'project/' . $project->id } );
        while ( my $project1 = $projects1->next ) {
            $project1->ns( '#project/' . $project->mid );
            $project1->update();
        }
        ##*****************************************************************************************


        ##BALI_ROLEUSER******************************************************************************
        my $projects1 = $c->model('Baseliner::BaliRoleuser')->search( { ns => 'project/' . $project->id } );
        while ( my $project1 = $projects1->next ) {
            $project1->ns( '#project/' . $project->mid );
            $project1->update();
        }
        ##*****************************************************************************************


        ##BALI_SQA*****************************************************************************
        my $projects1 = $c->model('Baseliner::BaliSqa')->search( { id_prj => $project->id } );
        while ( my $project1 = $projects1->next ) {
            $project1->id_prj( $project->mid * -1 );
            $project1->update();
        }
        ##*****************************************************************************************
    }
}

my $projects = $rs->search( { id_parent => { '<', 0 } } );
while ( my $project = $projects->next ) {
    $project->id_parent( $project->id_parent * -1 );
    $project->update();
}

my $projects = $c->model('Baseliner::BaliConfig')->search( { ns => { 'like', '%#project%' } } );
while ( my $project = $projects->next ) {
    $project->ns( substr( $project->ns, 1 ) );
    $project->update();
}

my $projects = $c->model('Baseliner::BaliRoleuser')->search( { ns => { 'like', '%#project%' } } );
while ( my $project = $projects->next ) {
    $project->ns( substr( $project->ns, 1 ) );
    $project->update();
}

my $projects = $c->model('Baseliner::BaliSqa')->search( { id_prj => { '<', 0 } } );
while ( my $project = $projects->next ) {
    $project->id_prj( $project->id_prj * -1 );
    $project->update();
}

$dbh->do(q{ALTER TABLE BALI_PROJECT DROP CONSTRAINT BALI_PROJECT_PK });
$dbh->do(q{ALTER TABLE BALI_PROJECT DROP COLUMN ID});
$dbh->do(q{ALTER TABLE BALI_PROJECT ADD CONSTRAINT BALI_PROJECT_PK PRIMARY KEY ( MID ) ENABLE });

$dbh->do(
    q{
        ALTER TABLE BALI_SQA
        add CONSTRAINT bali_sqa_fk
          FOREIGN KEY (id_prj)
          REFERENCES bali_project (mid)
    }
);


print "Finished bali_project to mid migration\n\n";


