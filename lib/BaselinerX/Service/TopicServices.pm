package BaselinerX::Service::TopicServices;
use Moose;

use experimental 'smartmatch';
use Try::Tiny;
use Path::Class;
use Baseliner::Core::Registry ':dsl';
use Baseliner::DataView::Topic;
use Baseliner::Utils;

with 'Baseliner::Role::Service';

register 'service.topic.change_status' => {
    name => _locl('Change topic status'),
    handler => \&change_status,
    job_service  => 1,
    icon => '/static/images/icons/topic.svg',
    form => '/forms/topic_status.js'
};

register 'service.topic.create' => {
    name => _locl('Create a new topic'),
    handler => \&create,
    job_service  => 1,
    icon => '/static/images/icons/topic.svg',
    form => '/forms/topic_create.js'
};

register 'service.topic.update' => {
    name => _locl('Update topic data'),
    handler => \&update,
    job_service  => 1,
    icon => '/static/images/icons/topic.svg',
    form => '/forms/topic_update.js'
};

register 'service.topic.upload' => {
    name => _locl('Attach file to a topic'),
    handler => \&upload,
    job_service  => 0,
    icon => '/static/images/icons/topic.svg',
    form => '/forms/asset_file.js'
};

register 'service.topic.remove_file' => {
    name => _locl('Remove files from a topic'),
    handler => \&remove_file,
    job_service  => 0,
    icon => '/static/images/icons/topic.svg',
    form => '/forms/remove_file.js'
};

register 'service.topic.load' => {
    name => _locl('Load topic data'),
    handler => \&load,
    job_service  => 0,
    icon => '/static/images/icons/topic.svg',
    form => '/forms/topic_load.js'
};

register 'service.topic.related' => {
    name => _locl('Load topic related'),
    handler => \&related,
    job_service  => 0,
    icon => '/static/images/icons/topic.svg',
    form => '/forms/topic_related.js'
};

register 'service.topic.inactivity_daemon' => {
    name    => _locl('Watch for topics without activity in statuses'),
    icon => '/static/images/icons/daemon.svg',
    config  => 'config.job.daemon',
    daemon  => 1,
    handler => \&inactivity_daemon,
};

register 'service.topic.get_with_condition' => {
    name => _locl('Get topics that match conditions'),
    handler => \&get_with_condition,
    job_service  => 0,
    icon => '/static/images/icons/topic.svg',
    form => '/forms/topic_get_with_condition.js'
};

register 'config.topic.inactivity_daemon' => {
    metadata=> [
        {  id=>'frequency', label=>_locl('Inactivity daemon Frequency'), type=>'int', default=>600 }
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

    my $topics = $config->{topics} // _fail _loc('Missing or invalid parameter topics');
    my $old_status_id_or_name = $config->{old_status};
    my $new_status_id_or_name = $config->{new_status} // _fail _loc('Missing or invalid parameter new_status');

    my @topic_mids = Util->_array_or_commas($topics);

    my @statuses;
    if ( $old_status_id_or_name ) {
        @statuses = Util->_array_or_commas( $old_status_id_or_name );
    }

    my $new_status = ci->status->find_one(
        { '$or' => [ { id_status => "$new_status_id_or_name" }, { name => "$new_status_id_or_name" } ] } );
    if ( !$new_status ) {
        _fail _loc( "Status %1 does not exist in the system", $new_status_id_or_name );
    }

    my @topic_rows;
    for my $mid ( @topic_mids ) {
        my $topic = mdb->topic->find_one( { mid => "$mid" } );
        _fail _loc("Topic %1 does not exist in the system", $mid) unless $topic;

        my $old_status = $topic->{category_status};

        if ( @statuses && !( grep { $old_status->{id_status} eq $_ || $old_status->{name} eq $_ } @statuses ) ) {
            _fail _loc( 'Topic %1 not changed to %2 (%3). Current status is not in the valid old_status list',
                $topic->{mid}, $new_status->{name}, $new_status_id_or_name );
        }

        push @topic_rows, $topic;
    }

    for my $topic ( @topic_rows ) {
        my $old_status = $topic->{category_status};

        _log _loc(
            'Changing status for topic %1 from status `%2` (%3) to status `%4` (%5)',
            $topic->{mid},       $old_status->{name}, $old_status->{id_status},
            $new_status->{name}, $new_status->{id_status}
        );

        Baseliner::Model::Topic->new->change_status(
            change     => 1,
            id_status  => $new_status->{id_status},
            mid        => $topic->{mid},
            username   => $config->{username} // 'clarive'
        );
    }
}

sub create {
    my ( $self, $c, $config ) = @_;

    my $data     = $config->{variables};
    my $username = $config->{username} // 'clarive';
    my $title    = $config->{title};

    my ($category_id_or_name) = _array $config->{category};
    _fail( _loc('Missing parameter category') ) unless $category_id_or_name;
    my ($status_id_or_name) = _array $config->{status};
    _fail( _loc('Missing parameter status') ) unless $status_id_or_name;

    my $category =
      mdb->category->find_one( { '$or' => [ { id => $category_id_or_name }, { name => $category_id_or_name } ] } );
    _fail _loc( "Category %1 does not exist in the system", $category_id_or_name ) unless $category;

    my $status = ci->status->find_one(
        { '$or' => [ { id_status => $status_id_or_name }, { name => $status_id_or_name } ] } );
    _fail _loc("Status %1 does not exist in the system", $status_id_or_name) unless $status;

    $data->{title}              = $title;
    $data->{username}           = $username;
    $data->{action}             = 'add';
    $data->{category}           = $category->{id};
    $data->{id_category_status} = $status->{id_status};

    my (undef, $topic_mid) = Baseliner::Model::Topic->new->update($data);

    return $topic_mid;
}

sub update {
    my ( $self, $c, $config ) = @_;

    my $stash = $c->stash;

    my $user = $config->{username} // 'clarive';
    my $variables = $config->{variables};
    my $mid = $config->{mid};

    my $data = {};

    $data->{topic_mid} = $mid;
    $data->{action} = 'update';
    $data->{username} = $user;

    for my $field ( keys %$variables) {
        $data->{$field} = $variables->{$field};
    }

    Baseliner->model('Topic')->update(
        $data
    );
}

sub upload {
    my ( $self, $c, $config ) = @_;
    my $stash    = $c->stash;
    my $filepath = $config->{path};
    my $username = $config->{username} // 'clarive';
    if ( $username eq '' ) { $username = 'clarive' }

    my $p;
    my $id_field = $config->{field};
    my $topic_mid = "$config->{mid}";
    $filepath =~ m{^(.*)\/ (.*)$}x;
    my $filename = $2;

    my $file = _file( '' . $filepath );

    my $model_topic = Baseliner::Model::Topic->new;
    my %response = $model_topic->upload( file => $file, topic_mid => $topic_mid, filename => $filename, filter => $id_field, username => $username, );

    if ( $response{upload_file} ) {
        my $p              = {};
        $p->{topic_mid}    = $topic_mid;
        $p->{username}     = $username;
        $p->{upload_files} = $response{upload_file};
        $p->{id_field}     = $id_field;

        try {
            $model_topic->upload_complete(%$p);
            return '200';
        }
        catch {
            my $err = shift;
            _fail _loc( $err );
        };
    }
    else {
        _fail _loc( "Error asseting the file %1 to the topic %2. Error: %3",
            $filename, $topic_mid, $response{msg} );
    }
}

sub remove_file {
    my ( $self, $c, $config ) = @_;

    my $username  = $config->{username} && $config->{username} ne '' ? $config->{username} : 'clarive';
    my $topic_mid = $config->{topic_mid} // _fail('Missing or invalid parameter topic_mid');
    my $asset_mid = $config->{remove} eq 'asset_mid' ? $config->{asset_mid} : [];
    my $fields    = $config->{remove} eq 'fields'    ? $config->{fields}    : [];

    Baseliner::Model::Topic->remove_file(
        topic_mid => $topic_mid,
        asset_mid => $asset_mid,
        username  => $username,
        fields    => $fields
    );
}

sub related {
    my ( $self, $c, $config ) = @_;

    my $return = [];
    my $stash = $c->stash;
    my $event_mid = $stash->{mid};
    my $mid = $config->{mid} // die _loc("Missing mid");
    my $statuses = $config->{related_status} // [];
    my $not_in_statuses = $config->{not_in_status} // 'off';
    my $categories = $config->{related_categories} // [];
    my $depth = $config->{depth} // 1;
    my $include_event_mid = $config->{include_event_mid} && $config->{include_event_mid} eq 'on' ? '':$event_mid;
    my $query_type = $config->{query_type} // 'children';
    my @fields = $config->{fields} ? split(',',$config->{fields}):();
    my $condition = {};

    my $ci = ci->new($mid);
    my $where = { collection => 'topic'};
    $where->{mid} = {'$ne' => $include_event_mid} if $include_event_mid;
    $condition->{'category.id'} = mdb->in($categories) if $categories;
    if ( $statuses ) {
        if ( $not_in_statuses eq 'on' ) {
            $condition->{'category_status.id'} = mdb->nin($statuses);
        } else {
            $condition->{'category_status.id'} = mdb->in($statuses);
        }
    }

    my @related_mids = map {$_->{mid}} $ci->$query_type( where => $where, mids_only => 1, depth => $depth);
    $condition->{mid} = mdb->in(@related_mids);
    my @related = mdb->topic->find($condition)->fields({_txt => 0})->all;

    return \@related;
}

sub get_with_condition {
    my ( $self, $c, $config ) = @_;

    my $categories = $config->{categories} || [];
    my $statuses   = $config->{statuses}   || [];
    my $not_in_status = $config->{not_in_status};
    my $filter_user   = $config->{assigned_to};
    my $limit         = $config->{limit} // 100;
    my $condition     = {};
    my $where         = {};

    if ( $config->{condition} ) {
        try {
            my $cond = eval( 'q/' . $config->{condition} . '/' );
            $condition = Util->_decode_json($cond);
        }
        catch {
            _error "JSON condition malformed (" . $config->{condition} . "): " . shift;
        };
    }

    $where = $condition;

    if ( $filter_user && $filter_user ne 'any' ) {
        if ( $filter_user eq 'current' ) {
            $filter_user = $c->stash->{username};
        }
        my $ci_user = ci->user->find_one( { name => $filter_user } );
        if ($ci_user) {
            my @topic_mids
                = map { $_->{from_mid} }
                mdb->master_rel->find( { to_mid => $ci_user->{mid}, rel_type => 'topic_users' } )
                ->fields( { from_mid => 1 } )->all;
            if (@topic_mids) {
                $where->{'mid'} = mdb->in(@topic_mids);
            }
            else {
                $where->{'mid'} = -1;
            }
        }
    }

    my $rs = Baseliner::DataView::Topic->find(
        limit         => $limit,
        where         => $where,
        categories    => $categories,
        statuses      => $statuses,
        username      => $c->stash->{username},
        not_in_status => $not_in_status
    );

    my @topics = map {
        { hash_flatten($_) }
    } $rs->all;

    return \@topics;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
