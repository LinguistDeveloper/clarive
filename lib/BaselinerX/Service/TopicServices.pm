package BaselinerX::Service::TopicServices;
use Baseliner::Plug;
use Baseliner::Utils;
use Path::Class;
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
    icon => '/static/images/icons/folder_new.png',
    form => '/forms/topic_create.js' 
};

register 'service.topic.update' => {
    name => 'Update topic data',
    handler => \&update,
    job_service  => 1,
    icon => '/static/images/icons/folder_edit.png',
    form => '/forms/topic_update.js' 
};


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
    my @topic_mids = Util->_array_or_commas( $topics);
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
        ($new_status_id) = map {$_->{id_status}} ci->status->find_one( {id_status => $new_status} );
    } else {
        ($new_status_id) = map {$_->{id_status}} ci->status->find_one( {name => $new_status} );
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

1;
