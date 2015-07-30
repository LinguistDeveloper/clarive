package Baseliner::Controller::Doc;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }
use experimental 'autoderef';

sub content : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $mid = $p->{mid} || _throw 'Missing mid';
    my $meta = model->Topic->get_meta($mid);
    my $doc = mdb->topic->find_one({ mid=>$mid });
    my ($title,$body) = ( $$doc{title}, $$doc{description} );
    for my $field ( @$meta ) {
        next unless $field->{meta_type};
        if( $field->{meta_type} eq 'title' ) {
            $title = $$doc{ $field->{id_field} };
        }
        elsif( $field->{meta_type} eq 'content' ) {
            $body = $$doc{ $field->{id_field} };
            if( $field->{js} =~ /pagedown/ ) {   # XXX create a meta_subtype for this or a transformer: field
                $body = Util->_markdown( $body );
            }
        }
    }
    $body = _loc('Missing content for topic with mid %1',$mid) if !defined $body;
    $title = _loc('Missing title for topic with mid %1',$mid) if !defined $title;
    my $info = [
        { text=>_loc('Modified On'), value=>$$doc{modified_on} },
        { text=>_loc('Modified By'), value=>$$doc{modified_by} },
        { text=>_loc('Created On'), value=>$$doc{created_on} },
        { text=>_loc('Created By'), value=>$$doc{created_by} },
        { text=>_loc('Version'), value=>$$doc{_version}//'1.0' },
    ];
    my $moniker = Util->_name_to_id($title) =~ s/_/-/gr; 
    $c->stash->{json} = { body=>$body, title=>$title, info=>$info, moniker=>$moniker };
    $c->forward('View::JSON');
}

sub menu : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $username = $c->username;
    
    # gen_tree does not return children, gotta recurse here
    #my $prj = ci->project->find_one({ name=>$prjname }) || _fail(_loc('Project %1 not found', $prjname));
    #my @tree = Baseliner::Controller::FileVersion->gen_tree({ username=>$username, id_project=>$prj->{mid} });
    my @tree;
    my $doc_id = $p->{doc_id};
    my $doc_title = $p->{doc_title}//'';
    if( $doc_id =~ /folder:(.+)/ ) {
        my $id_folder = $1;
        _debug "Generating tree of id_folder $id_folder for user $username";
        @tree = Baseliner::Controller::FileVersion->gen_tree({ username=>$username, id_folder=>$id_folder });
        if( my $folder = ci->new( $id_folder ) ) {
            $doc_title = $folder->name;
        }
        _debug( \@tree );
        my $menuify; $menuify = sub{
            my ($item_path,@t) = @_;    
            _debug "Item path " . _dump($item_path);
            return map {
                my $row = $_;
                my $text = $$row{text};
                #_debug( $_ );
                my $id_folder = $$row{data}{id_folder} || -1;
                my @tree2 = Baseliner::Controller::FileVersion->gen_tree({ username=>$username, id_folder=>$id_folder });
                +{ 
                   text       => $text,
                   moniker    => ( $$row{moniker} =~ s/_/-/gr ),  # dash is more webish
                   topic_mid  => $$row{data}{topic_mid},
                   topic_name => $$row{topic_name},
                   path       => join( '/', map{ s{/}{&frasl;}r } @$item_path, $text),
                   id_folder  => $id_folder,
                   children   => $id_folder ? [ $menuify->([@$item_path,$text],@tree2) ] : []
                 };
            } @t;
        };
        @tree = $menuify->([], @tree );
    }
    elsif( $doc_id =~ /topic:(.+)/ ) {
        my $parent_mid = $1;
        my $meta = model->Topic->get_meta_hash( $parent_mid ); 
        my %topics;
        for my $rel ( mdb->master_rel->find({ from_mid=>$parent_mid, rel_type=>'topic_topic' })->all ) {
            my $mid = $$rel{to_mid};
            my $id_field = $$rel{rel_field};
            my $field = $meta->{ $id_field };
            $topics{$id_field}{text} ||= $field->{name_field};
            $topics{$id_field}{text} ||= $field->{name_field};
            # children
            my $topic = ci->topic->find_one($mid) // _fail _loc 'Topic mid not found: %1', $mid;
            my $tt = { text=>$$topic{title}, 
                path => '', #join( '/', map{ s{/}{&frasl;}r } @$item_path, $text),
                id_folder  => -1,
                children => [],
                topic_name=>$$topic{title}, topic_mid=>$$topic{mid}, moniker=>( $$topic{moniker}=~ s/_/-/gr ), }; 
            _debug( $tt );
            push @{ $topics{$id_field}{children} }, $tt; 
        }
        @tree = values \%topics;
    }
    
    
    _debug( \@tree );
        #my @tree = (
        #{ text=>'Uno', id=>'uno', children=>[
        #{ text=>'Dos', id=>'dos', children=>[] }
        #] },
        #);
    $c->stash->{json} = { doc_title=>$doc_title, menu=>\@tree, success=>\1 };
    $c->forward('View::JSON');
}

sub default : Path {
    my ($self, $c, $prj, @path) = @_;
    my $p = $c->req->params;
    #$c->stash->{json} = { total=>$total, totalCount=>$total, data=>\@tree, success=>\1 };
    #$c->forward('View::JSON');
    $c->stash->{template} = '/static/docgen/home.html';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

