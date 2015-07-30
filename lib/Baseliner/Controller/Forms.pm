package Baseliner::Controller::Forms;
use Moose;
use Baseliner::Utils;
use Baseliner::Sugar;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

sub save : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $cmd = $p->{cmd};
    if( $cmd eq 'get_files' ) {
        my $dir = _dir( $c->path_to('root/forms') );
        my %rows;

        for my $f ( $dir->children ) {
            my $name = $f->basename;
            ($name) = $name =~ m{^(.*)(\..*?)$};
            $rows{ $name } = $name ;
        }
        $c->stash->{json} = \%rows;
        $c->forward('View::JSON');
    }
    elsif( $cmd eq 'get_content' ) {
        my $f = $p->{filename};
        $c->res->body( scalar _file( $c->path_to('root/forms', "$f.js" ) )->slurp );
    }
    elsif( $cmd eq 'save_changes' ) {
        my $f = $p->{filename};
        my $content = $p->{content};
        open my $ff, '>', $c->path_to('root/forms', "$f.js" );
        print $ff $content;
        close $ff;
        $c->res->body(1);
    }
    else {
        $c->res->body(0);
    }
}

1;
