package BaselinerX::Service::TopicServices;
use Baseliner::Plug;
use Baseliner::Utils;
use Path::Class;
use utf8;
#use Try::Tiny;

with 'Baseliner::Role::Service';

register 'service.topic.change_status' => {
    name => 'Change topic status',
    handler => \&change_status,
    job_service  => 1,
    icon => '/static/images/icons/folder_go.png',
    form => '/forms/topic_status.js' 
};

register 'service.topic.create' => {
    name => 'Create a new topic',
    handler => \&create,
    job_service  => 1,
    icon => '/static/images/icons/folder_new.gif',
    form => '/forms/topic_create.js' 
};

register 'service.topic.update' => {
    name => 'Update topic data',
    handler => \&update,
    job_service  => 1,
    icon => '/static/images/icons/folder_edit.png',
    form => '/forms/topic_update.js' 
};

register 'service.topic.upload' => {
    name => 'Asset topic file',
    handler => \&upload,
    job_service  => 0,
    icon => '/static/images/icons/upload.gif',
    form => '/forms/asset_file.js' 
};

register 'service.topic.load' => {
    name => 'Load topic data',
    handler => \&load,
    job_service  => 0,
    icon => '/static/images/icons/document.png',
    form => '/forms/topic_load.js' 
};

register 'service.topic.related' => {
    name => 'Load topic related',
    handler => \&related,
    job_service  => 0,
    icon => '/static/images/icons/spacetree.png',
    form => '/forms/topic_related.js' 
};

register 'service.topic.inactivity_daemon' => {
    name    => 'Watch for topics without activity in statuses',
    config  => 'config.job.daemon',
    daemon  => 1,
    handler => \&inactivity_daemon,
};

register 'config.topic.inactivity_daemon' => {
    metadata=> [
        {  id=>'frequency', label=>'Inactivity daemon Frequency', type=>'int', default=>600 }
    ]
};


sub inactivity_daemon {
    my ($self,$c,$config)=@_;
    my $freq = $config->{frequency};

    for( 1..1000 ) {

    }
    _log "Topic inactivity daemon stopped.";
}

sub load {
    my ( $self, $c, $config ) = @_;

    my $mid = $config->{topic} // _fail(_loc("Missing mid"));

    my $topic = mdb->topic->find_one({ mid => "$mid"});
    if ( !$topic ) {
        _fail(_loc("Topic %1 not found", $mid));
    } 
    return $topic;
    
}
sub web_request {
    my ( $self, $c, $config ) = @_;

    require LWP::UserAgent;
    require HTTP::Request;
    require Encode;
    
    my $method = $config->{method} // 'GET';
    my $url    = $config->{url};
    my $args   = $config->{args};
    my $headers = $config->{headers} || {};
    my $body = $config->{body} || '';
    my $timeout = $config->{timeout};
    my $encoding = $config->{encoding} || 'utf-8';

    if( $encoding ne 'utf-8' ) {
        Encode::from_to($url, 'utf-8', $encoding ) if $url;
        if( ref $args ) {
            my $x = _dump($args);
            Encode::from_to( $x, 'utf-8', $encoding );
            $args = _load( $x );
        }
        if( ref $headers ) {
            my $x = _dump($headers);
            Encode::from_to( $x, 'utf-8', $encoding );
            $headers = _load( $x );
        }
    }

    my $uri = URI->new( $url );
    $uri->query_form( $args );
    my $request = HTTP::Request->new( $method => $uri );
    $request->authorization_basic($config->{username}, $config->{password}) if $config->{username};
    my $ua = LWP::UserAgent->new();
    $ua->timeout( $timeout ) if $timeout;
    for my $k ( keys %$headers ) {
        $ua->default_header( $k => $headers->{$k} );
    }
    $ua->env_proxy;
    
    if( length $body ) {
        $request->content( $body ); 
    }

    my $response = $ua->request( $request );

    _fail sprintf qq/HTTP request failed: %s\nUrl: %s\nArgs: %s/, $response->status_line, $url, _to_json($args)
        unless $response->is_success;
    my $content = $response->decoded_content;
        #if( $encoding ne 'utf-8' ) {
        #Encode::from_to($content, $encoding, 'utf-8' ) if $content;
        #}
    return { response=>$response, content=>$content };
} 

sub change_status {
    my ( $self, $c, $config ) = @_;

    my $stash = $c->stash;
    my $topics = $config->{topics} // _fail _loc 'Missing or invalid parameter topics';
    my $old_status = $config->{old_status};
    my $new_status = $config->{new_status} // _fail _loc 'Missing or invalid parameter new_status';

    # Let's check that all topics exist in the system   
    my @topic_mids = Util->_array_or_commas($topics);
    my @topic_rows;

    # Generate the list of old_statuses valid to do the change
    my @statuses;
    if ( $old_status ) {
        @statuses = Util->_array_or_commas( $old_status );
    }

    for my $mid ( @topic_mids ) {
        my $topic = mdb->topic->find_one( { mid => "$mid" } );
        if ( !$topic ) {
            _fail _loc("Topic %1 does not exist in the system", $mid);
        }
        if ( @statuses && !($topic->{name_status} ~~ @statuses) ) {
            _fail _loc('Topic %1 not changed to %2. Current status is not in the valid old_status list', $topic->{mid}, $new_status);
        }
        push @topic_rows, $topic;
    }

    #Let's get the new_status id
    my $new_status_id;

    if ( is_number( $new_status ) ) {
        ($new_status_id) = map {$_->{id_status}} ci->status->find_one( {id_status => "$new_status"} );
    } else {
        ($new_status_id) = map {$_->{id_status}} ci->status->find_one( {name => "$new_status"} );
    }

    if ( !$new_status_id ) {
        _fail _loc("Status %1 does not exist in the system", $new_status);
    }

    for my $topic ( @topic_rows ) {
        _log _loc('Changing status for topic %1 to status %2', $topic->{mid}, $new_status_id); 
        Baseliner->model('Topic')->change_status( 
            change     => 1, 
            id_status  => $new_status_id,
            mid        => $topic->{mid},
            username   => $config->{username} // 'clarive'
        );
    }
}

sub create {
    my ( $self, $c, $config ) = @_;

    my $stash = $c->stash;
    my $category = $config->{category} // _fail( _loc 'Missing or invalid parameter category' );
    my $data = $config->{data};
    my $username = $config->{username} // 'clarive';
    my $new_status = $config->{new_status};

    #Let's get the category id
    ###### TODO: GET CATEGORY ID FROM MONGO ¿?¿? 
    my $id_category = $category;

    # if ( is_number( $category ) ) {
    #     ($category_id) = map {$_->{id}} ci->status->find_one( {id_status => $new_status} );
    # } else {
    #     ($new_status_id) = map {$_->{id_status}} ci->status->find_one( {name => $new_status} );
    # }

    # if ( !$new_status_id ) {
    #     _fail _loc("Status %1 does not exist in the system", $new_status);
    # }

    #Let's get the new_status id
    my $new_status_id;

    if ( $new_status ) {
        if ( is_number( $new_status ) ) {
            ($new_status_id) = map {$_->{id_status}} ci->status->find_one( {id_status => $new_status} );
        } else {
            ($new_status_id) = map {$_->{id_status}} ci->status->find_one( {name => $new_status} );
        }

        if ( !$new_status_id ) {
            _fail _loc("Status %1 does not exist in the system", $new_status);
        } else {
            $data->{id_category_status} = $new_status_id;
        }
    };

    $data->{username} = $username;
    $data->{action} = 'add';
    $data->{category} = $id_category;


    Baseliner->model('Topic')->update( 
        $data
    );
}

sub update {
    my ( $self, $c, $config ) = @_;

    my $stash = $c->stash;
    my $data = $config->{data};
    my $user = $config->{username} // 'clarive';

}

sub upload {
    my ( $self, $c, $config ) = @_;
    my $stash = $c->stash;
    my $filepath = $config->{path};
    my $username = $config->{username} // 'clarive';
    if ($username eq ''){$username = 'clarive'}
    
    my $p;
    $p->{filter} = $config->{field};
    $p->{topic_mid} = "$config->{mid}";
    $filepath =~ m{^(.*)\/ (.*)$}x;
    $p->{qqfile} = $2; #El nombre del fichero sin la ruta
    my $f =  _file( ''. $filepath );

    my %response = Baseliner->model("Topic")->upload(
                f           => $f, 
                p           => $p, 
                username    => $username,
        );
    if ($response{status} ne '200') {
        _fail _loc("Error asseting the file %1 to the topic %2. Error: %3", 
            $p->{qqfile}, $p->{topic_mid}, $response{msg});
    }   
}

sub related {
    my ( $self, $c, $config ) = @_;

    my $return = [];
    my $mid = $config->{mid} // die _loc("Missing mid");
    my $statuses = $config->{related_status} // [];
    my $not_in_statuses = $config->{not_in_status} // 'off';
    my $categories = $config->{related_categories} // [];
    my $depth = $config->{depth} // 1;
    my $query_type = $config->{query_type} // 'children';
    my @fields = $config->{fields} ? split(',',$config->{fields}):();
    my $condition = {};

    my $ci = ci->new($mid);
    my $where = { collection => 'topic'};
    $where->{'id_category'} = mdb->in($categories) if $categories;
    if ( $statuses ) {
        if ( $not_in_statuses eq 'on' ) {
            $where->{'id_category_status'} = mdb->nin($statuses);
        } else {
            $where->{'id_category_status'} = mdb->in($statuses);
        }
    }

    my @related_mids = map {$_->{mid}} $ci->$query_type( where => $where, mids_only => 1, depth => $depth);
    $condition->{mid} = mdb->in(@related_mids);

    my @related = mdb->topic->find({%$where,%$condition})->fields({_txt => 0})->all;

    return \@related;

}
1;
