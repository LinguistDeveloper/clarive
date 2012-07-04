package Baseliner::Controller::FileVersion;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Core::DBI;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

sub drop : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    
    my @files = $c->model('Baseliner::BaliProject')->find( $p->{id_project} )->files->search( {mid=>$p->{id_file} },{select=> [qw(mid)]})->hashref->all;
    
    my $project = $c->model('Baseliner::BaliProject')->find( $p->{id_project} );
    my $file = $project->files->search( {mid=>$p->{id_file} },{select=> [qw(mid)]})->all;
    if ($file){
        $c->stash->{json} = { success=>\0, msg=>_loc('File already exists') };
    }else{
        my $file = $c->model('Baseliner::BaliFileVersion')->find($p->{id_file});
        $project->add_to_files( $file, { rel_type=>'project_file_version' });
        $c->stash->{json} = { success=>\1, msg=>_loc('File added to project') };
    }
    $c->forward('View::JSON');
}

sub tree_file_project : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my @files = $c->model('Baseliner::BaliProject')->find( $p->{id_project} )->files->search( undef,{select=> [qw(mid filename versionid)]} )->hashref->all;
    my @tree;
    foreach my $file (@files){
        push @tree, {
                        text    => $file->{filename} . '(v' . $file->{versionid} . ')',
                        leaf    =>\1,
                        data    => {
                           id_file => $file->{mid},
                        },                
                    };
    }
    $c->stash->{json} = \@tree;
    $c->forward('View::JSON');
}

1;
