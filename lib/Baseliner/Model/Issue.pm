package Baseliner::Model::Issue;
use Moose;
use Baseliner::Utils;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);
use v5.10;

BEGIN { extends 'Catalyst::Model' }

sub update {
    my ( $self, $p ) = @_;
    my $action = $p->{action};

    _log "====================== \n" . _dump $p;

    my $return;
    my $id;

    given ( $action ) {
        when ( 'add' ) {
            try {
                my $issue = Baseliner->model( 'Baseliner::BaliIssue' )->create(
                    {
                        title       => $p->{title},
                        description => $p->{description},
                        created_by  => $p->{username},
                        id_category  => $p->{category}
                    }
                );
                $id     = $issue->id;
                $return = _loc( 'Issue added' );
            } ## end try
            catch {

                _throw _loc( 'Error adding Issue: %1', shift() );
            }
        } ## end when ( 'add' )
        when ( 'update' ) {
            try {
                my $id_issue = $p->{id};
                my $issue    = Baseliner->model( 'Baseliner::BaliIssue' )->find( $id_issue );
                $issue->title( $p->{title} );
                $issue->description( $p->{description} );
                $issue->id_category( $p->{category} );
                $issue->update();
                $id     = $id_issue;
                $return = _loc( 'Issue modified' );
            } ## end try
            catch {
                _throw _loc( 'Error modifying Issue: %1', shift() );
            }
        } ## end when ( 'update' )
        when ( 'delete' ) {
            my $id_issue = $p->{id};

            try {

                my $row = Baseliner->model( 'Baseliner::BaliIssue' )->find( $id_issue );
                $row->delete;

                $id     = $id_issue;
                $return = _loc( 'Issue deleted' );
            } ## end try
            catch {
                _throw _loc( 'Error deleting issue: %1', shift() );
            }
        } ## end when ( 'delete' )
        when ( 'close' ) {
            try {
                my $id_issue = $p->{id};
                my $issue    = Baseliner->model( 'Baseliner::BaliIssue' )->find( $id_issue );
                $issue->status( 'C' );
                $issue->update();

                $id     = $id_issue;
                $return = _loc( 'Issue closed' );
            } ## end try
            catch {
                _throw _loc( 'Error closing Issue: %1', shift() );
            }
        } ## end when ( 'close' )
    } ## end given
    return ( $return, $id );
} ## end sub update

1;
