package Baseliner::Controller::REPL;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

use experimental 'autoderef';
use JSON::XS;
use Try::Tiny;
use File::Basename qw(dirname);
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use Clarive::Code;

register 'action.development.repl'          => { name => 'Baseliner REPL' };
register 'action.development.js_reload',    => { name => 'JS Reload' };
register 'action.development.cache_clear',  => { name => 'Wipe Cache' };
register 'action.development.ext_api'       => { name => 'ExtJS API Reference' };
register 'action.development.ext_examples'  => { name => 'ExtJS Examples' };
register 'action.development.gui_designer', => { name => 'GUI Designer' };
register 'action.development.sequences',    => { name => 'Sequences' };

register 'menu.development' => {
    label  => _locl('Development'),
    action => 'action.development.%',
    index  => 30
};
register 'menu.development.repl' => {
    label    => _locl('REPL'),
    url_comp => '/repl/main',
    title    => _locl('REPL'),
    action   => 'action.development.repl',
    icon     => '/static/images/icons/console.svg',
    index    => 10,
};
register 'menu.development.js_reload' => {
    label    => _locl('JS Reload'),
    url_eval => '/site/js-reload.js',
    title    => _locl('JS Reload'),
    icon     => '/static/images/icons/js-reload.svg',
    action   => 'action.development.js_reload',
    index    => 20,
};

register 'menu.development.cache_clear' => {
    label    => _locl('Wipe Cache'),
    url_run  => '/cache_clear',
    title    => _locl('Wipe Cache'),
    action   => 'action.development.cache_clear',
    icon     => '/static/images/icons/wipe_cache.svg',
    index      => 30,
};

register 'menu.development.ext_api' => {
    label      => _locl('ExtJS API'),
    url_iframe => '/static/ext/docs/index.html',
    title      => _locl('ExtJS API'),
    action     => 'action.development.ext_api',
    icon     => '/static/images/icons/extjs.svg',
    index      => 1000,
};
register 'menu.development.ext_examples' => {
    label      => _locl('ExtJS Examples'),
    url_iframe => '/static/ext/examples/index.html',
    title      => _locl('ExtJS Examples'),
    action     => 'action.development.ext_examples',
    icon     => '/static/images/icons/extjs_example.svg',
    index      => 1000,
};
register 'menu.development.sequences' => {
    label    => _locl('Sequences'),
    url_comp => '/repl/sequences',
    title    => _locl('Sequences'),
    action   => 'action.development.sequences',
    icon     => '/static/images/icons/sequence.svg',
};

sub sequence_store : Local {
    my ( $self, $c ) = @_;
    $c->stash->{json} = try {
        my @rows = mdb->master_seq->find->all;
        { success => \1, data => \@rows, totalCount => scalar(@rows) };
    }
    catch {
        my $err = shift;
        { success => \0, msg => _loc( 'Error getting sequences: %1', $err ) };
    };
    $c->forward('View::JSON');
}

sub sequences : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = '/comp/sequences.js';
}

sub sequences_update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    $c->stash->{json} = try {
        my $modified_records = _load $p->{modified_records};
        foreach my $updated_seq ( keys $modified_records ) {
            my $new_value    = $modified_records->{$updated_seq}[0];
            my $actual_value = mdb->master_seq->find( { _id => $updated_seq } )->next->{seq};
            my $old_value    = $modified_records->{$updated_seq}[1];
            if ( $old_value != $actual_value ) {
                die _loc('Error sync updating sequences');
            }
            my $ret = mdb->master_seq->update( { _id => $updated_seq, seq => $old_value },
                { '$set' => { seq => $new_value } } );
        }
        { success => \1, msg => _loc('Modified rows updated successfully') };
    }
    catch {
        my $err = shift;
        { success => \0, msg => _loc( 'Error updating sequences: %1', $err ) };
    };
    $c->forward('View::JSON');
}

sub sequence_test : Local {
    my ( $self, $c ) = @_;
    my $option = $c->request->parameters->{option};
    if ( $option == 0 ) {
        mdb->master_seq->remove( { _id => 'id1' } );
        mdb->master_seq->remove( { _id => 'id2' } );
        mdb->master_seq->insert( { _id => 'id1', seq => 1 } );
        mdb->master_seq->insert( { _id => 'id2', seq => 1 } );
        $c->stash->{json} = { success => \1, msg => _loc('Sequences added successfully') };
    }
    if ( $option == 1 ) {
        mdb->master_seq->update( { _id => "id1" }, { '$set' => { seq => 2 } } );
        $c->stash->{json} = { success => \1, msg => _loc('Simulation of modification of sequence by other user') };
    }
    if ( $option == 2 ) {
        my $seq_id = $c->request->parameters->{seq_id};
        my $seq = mdb->master_seq->find( { _id => $seq_id } )->next->{seq};
        $c->stash->{json} = { success => \1, msg => _loc( 'Get seq value of ' . $seq_id ), seq => $seq };
    }
    if ( $option == -1 ) {
        mdb->master_seq->remove( { _id => 'id1' } );
        mdb->master_seq->remove( { _id => 'id2' } );
        $c->stash->{json} = { success => \1, msg => _loc('Initial state establishet') };
    }
    $c->forward('View::JSON');
}

sub test : Local {
    my ( $self, $c ) = @_;
    $c->response->body("hola");
}

sub main : Local {
    my ( $self, $c ) = @_;
    model->Permissions->user_has_action( username => $c->username, action => 'action.development.repl', fail => 1 );
    $c->stash->{template} = '/comp/repl.js';
}

sub eval : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->parameters;

    my $code = $p->{code};
    my $eval = $p->{eval};
    my $lang = $p->{lang};
    $lang = 'js' if $lang eq 'js-server';
    my $dump = $p->{dump} || 'yaml';
    my $sql = $p->{sql};

    $self->_push_to_history( $c->session, $code, $p->{lang} );

    local $ENV{BASELINER_LOGCOLOR} = 0;

    my $code_evaler = Clarive::Code->new( benchmark => 1 );

    my $stash = {};    # TODO it would be great if we could set a YAML stash in the REPL

    $c->res->status(200);
    $c->res->content_type('text/octet-steam');
    $c->res->body('');

    my $fh = $c->res->write_fh;

    my $capture_ret = _capture_pipe sub {
        $code_evaler->eval_code( $code, lang => $lang, stash => $stash );
      },
      merge  => 1,
      stdout => sub {
        my ($data) = @_;

        $data = Encode::decode( 'UTF-8', $data );

        my $response = JSON::XS::encode_json( { type => 'output', data => $data } );
        $fh->write( length( Encode::decode( 'UTF-8', $response ) ) . "\n" . $response );
      };

    my $elapsed = $capture_ret->{ret}->{elapsed};
    my $ret     = $capture_ret->{ret}->{ret};
    my $err     = $capture_ret->{ret}->{error} // '';

    if ( $dump eq 'yaml' ) {
        $ret = _dump($ret);
    }
    elsif ( $dump eq 'json' && ref $ret && !blessed $ret) {
        $ret = JSON::XS->new->pretty->encode( _damn($ret) );
    }

    my $response = JSON::XS::encode_json(
        {
            type => 'result',
            data => {
                stdout  => Encode::decode( 'UTF-8', $capture_ret->{stdout} ),
                stderr  => Encode::decode( 'UTF-8', $capture_ret->{stderr} ),
                elapsed => $elapsed,
                result  => $ret,
                error   => $err,
            }
        }
    );

    $fh->write( length( Encode::decode( 'UTF-8', $response ) ) . "\n" . $response );

    $fh->close;
}

sub save : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->parameters;

    my $id = $p->{id};
    my $text = $p->{text} //= $p->{id};
    $p->{username} = $c->username;

    my $doc = mdb->repl->find_one( { _id => $id } );
    if ($doc) {
        mdb->repl->save( { %$doc, %$p } );
    }
    else {
        $p->{_id} //= $id;
        mdb->repl->insert($p);
    }

    $c->stash->{json} = { success => \1 };
    $c->forward('View::JSON');
}

sub load : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->parameters;

    my $id = $p->{id};

    my $doc = mdb->repl->find_one( { _id => $id } );
    _fail _loc( 'REPL entry not found: %1', $id ) unless $doc;

    $c->stash->{json} = $doc;
    $c->forward('View::JSON');
}

sub delete : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->parameters;

    my $id = $p->{id};

    if ($id) {
        mdb->repl->remove( { _id => $p->{id} } );
    }
    else {
        _fail _loc('Missing REPL id');
    }

    $c->stash->{json} = { success => \1 };
    $c->forward('View::JSON');
}

sub tree_saved : Local {
    my ( $self, $c ) = @_;
    my $p     = $c->req->parameters;
    my $query = $p->{query};
    my @docs  = mdb->repl->find->all;
    my $k     = 0;
    $c->stash->{json} = [
        grep { $query ? $_->{text} =~ /$query/i : 1 }
          sort { lc $a->{text} cmp lc $b->{text} }
          map {
            my $id = "$_->{_id}";
            {
                _id       => $id,
                text      => $_->{text},
                iconCls   => 'default_folders',
                leaf      => \1,
                url_click => '/repl/load',
                data      => { _id => $id, id => $id }
            };
          } @docs
    ];
    $c->forward('View::JSON');
}

sub tree_hist : Local {
    my ( $self, $c ) = @_;

    my $p     = $c->req->parameters;
    my $query = $p->{query};

    $c->session->{repl_hist} ||= {};
    my $repl_hist = $c->session->{repl_hist};

    $c->stash->{json} = [
        map {
            my $code = $_->{code};
            $code =~ s/\n|\r//g;
            $code = substr( $code, 0, 30 );
            +{
                text      => sprintf( '%s (%s): %s', $_->{text}, $_->{lang}, $code ),
                iconCls   => 'default_folders',
                leaf      => \1,
                url_click => '/repl/load_hist',
                data => { text => $_->{text} }
              }
          }
          sort { $b->{text} cmp $a->{text} }    # by date DESC
          grep { $query ? $_->{code} =~ /\Q$query\E/i : 1 }
          grep { ref eq 'HASH' } values %{$repl_hist}
    ];
    $c->forward('View::JSON');
}

sub load_hist : Local {
    my ( $self, $c ) = @_;
    my $p    = $c->req->parameters;
    my $text = $p->{text};
    my $h    = $c->session->{repl_hist}->{$text};
    $c->stash->{json} =
      ref $h
      ? { code => $h->{code}, output => $h->{output}, lang => $h->{lang}, output => $h->{output} }
      : { output => 'not found' };
    $c->forward('View::JSON');
}

sub save_hist : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->parameters;

    $self->_push_to_history( $c->session, $p->{code}, $p->{lang} );

    $c->stash->{json} = {};
    $c->forward('View::JSON');
}

sub tree_main : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->parameters;

    $c->stash->{json} = [
        {
            text       => 'History',
            url        => '/repl/tree_hist',
            leaf       => \0,
            expandable => \1,
            expanded   => \0,
            iconCls    => 'default_folders'
        },
        {
            text       => 'Saved',
            url        => '/repl/tree_saved',
            leaf       => \0,
            expandable => \1,
            expanded   => \0,
            iconCls    => 'default_folders'
        },
    ];
    $c->forward('View::JSON');
}

sub save_to_file : Local {
    my ( $self, $c ) = @_;
    my $p    = $c->req->parameters;
    my @docs = mdb->repl->find->all;
    try {

        for my $item (@docs) {
            my $name = $item->{id};
            $name =~ Util->_name_to_id($name);
            $name =~ s/://g;
            $name =~ s/ /-/g;
            my $file = $c->path_to( 'etc', 'repl', "$name.t" );
            _mkpath dirname $file;

            my $code   = $item->{code};
            my $output = $item->{output};
            $code =~ s{\r}{}g;
            $output =~ s{\r}{}g;

            open( my $out, '>', $file ) or die $!;
            print $out $code;
            print $out "\n__END__\n";
            print $out $output;
            print $out "\n";
            close $out;
        }
        $c->stash->{json} = { success => \1 };
    }
    catch {
        my $error = shift;
        $c->stash->{json} = { success => \0, msg => _loc( "Cannot save: %1", $error ) };
    };
    $c->forward('View::JSON');
}

sub tidy : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->parameters;

    try {
        require Perl::Tidy;
        my $code = $p->{code};
        my $tidied;
        Perl::Tidy::perltidy( argv => ' ', source => \$code, destination => \$tidied );
        $c->stash->{json} = { success => \1, code => $tidied };
    }
    catch {
        $c->stash->{json} = { success => \0, msg => shift };
    };

    $c->forward('View::JSON');
}

sub _push_to_history {
    my ( $self, $session, $code, $lang, $output ) = @_;
    $session->{repl_hist} = {} unless ref $session->{repl_hist} eq 'HASH';
    my $hist = $session->{repl_hist};
    my $md5  = _md5($code);             # don't store duplicate repetitions
    if ( !$session->{repl_md5} || $session->{repl_md5} ne $md5 ) {

        if ( ( keys %$hist ) > 20 ) {
            my $oldest = [ sort keys %$hist ]->[0];
            delete $hist->{$oldest} if $oldest;
        }
        my $key = _now();
        $hist->{$key} = { text => $key, iconCls => 'default_folders', code => $code, lang => $lang, output => $output };

        #$session->{repl_hist} = \@hist;
        $session->{repl_md5} = $md5;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
