package BaselinerX::Service::TopicServices;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Path::Class;
use experimental 'smartmatch';
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
    icon => '/static/images/icons/add.gif',
    form => '/forms/topic_create.js' 
};

register 'service.topic.update' => {
    name => 'Update topic data',
    handler => \&update,
    job_service  => 1,
    icon => '/static/images/icons/edit.gif',
    form => '/forms/topic_update.js' 
};

register 'service.topic.upload' => {
    name => 'Attach file to a topic',
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

register 'service.topic.get_with_condition' => {
    name => 'Get topics that matches conditions',
    handler => \&get_with_condition,
    job_service  => 0,
    icon => '/static/images/icons/report_default.png',
    form => '/forms/topic_get_with_condition.js' 
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
    my $category = $config->{category} // _fail( _loc 'Missing parameter category' );
    my $data = $config->{variables};
    my $username = $config->{username} // 'clarive';
    my $new_status = $config->{status} // _fail(_loc('Missing parameter status'));
    my $title = $config->{title};
    my $category_id;
    my $new_status_id;

    #Let's get the category id
    if ( !is_number( $category ) ) {
        my $cat = mdb->category->find_one({ name => $category });
        if ( $cat ) {
            $category_id = $cat->{id};
        } else {
            _fail _loc("Category %1 does not exist in the system", $category);
        }
    } else {
        my $cat = mdb->category->find_one({ id => $category });
        if ( $cat ) {
            $category_id = $cat->{id};
        } else {
            _fail _loc("Category %1 does not exist in the system", $category);
        }        
    }

    #Let's get the new_status id
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
    if ( !$new_status_id ) {
        _fail _loc("Status %1 does not exist in the system", $new_status);
    }
    $data->{title} = $title;
    $data->{username} = $username;
    $data->{action} = 'add';
    $data->{category} = $category_id;

    Baseliner->model('Topic')->update( 
        $data
    );
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
    my $stash = $c->stash;
    my $event_mid = $stash->{mid};
    my $mid = $config->{mid} // die _loc("Missing mid");
    my $statuses = $config->{related_status} // [];
    my $not_in_statuses = $config->{not_in_status} // 'off';
    my $categories = $config->{related_categories} // [];
    my $depth = $config->{depth} // 1;
    my $include_event_mid = $config->{include_event_mid} eq 'on' ? '':$event_mid;
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
    _warn $condition;
    my @related = mdb->topic->find($condition)->fields({_txt => 0})->all;

    return \@related;

}

sub get_with_condition {
    my ( $self, $c, $config ) = @_;

    _warn $c;
    my $categories = $config->{categories} || [];
    my $statuses = $config->{statuses} || [];
    my $not_in_status = $config->{not_in_status};
    my $filter_user = $config->{assigned_to};
    my $limit = $config->{limit} // 100;
    my $condition = {};
    my $where = {};

    if ( $config->{condition} ) {
        try {
            my $cond = eval('q/'.$config->{condition}.'/');
            $condition = Util->_decode_json($cond);
        } catch {
            _error "JSON condition malformed (".$config->{condition}."): ".shift;
        }
    }

    $where = $condition;

    if ( $filter_user && $filter_user ne 'Any') {
        if ( $filter_user eq _loc('Current')) {
            $filter_user = $c->username;
        }
        my $ci_user = ci->user->find_one({ name=>$filter_user });
        if ($ci_user) {
            my @topic_mids = 
                map { $_->{from_mid} }
                mdb->master_rel->find({ to_mid=>$ci_user->{mid}, rel_type => 'topic_users' })->fields({ from_mid=>1 })->all;
            if (@topic_mids) {
                $where->{'mid'} = mdb->in(@topic_mids);
            } else {
                $where->{'mid'} = -1;
            }
        }
    }

    my $main_conditions = {};

    if ( _array($statuses) ) {
        my @local_statuses = _array($statuses);
        if ( $not_in_status ) {
            @local_statuses = map { $_ * -1 } @local_statuses;
            $main_conditions->{'statuses'} = \@local_statuses;
        } else {
            $main_conditions->{'statuses'} = \@local_statuses;
        }
    }
    my $username = $c->{username} || 'root';
    my $perm = Baseliner->model('Permissions');

    my @user_categories =  map {
        $_->{id};
    } $c->model('Topic')->get_categories_permissions( username => $username, type => 'view' );

    if ( _array($categories) ) {
        use Array::Utils qw(:all);
        my @categories_ids = _array($categories);
        @user_categories = intersect(@categories_ids,@user_categories);
    }

    my $is_root = $perm->is_root( $username );
    if( $username && ! $is_root){
        Baseliner->model('Permissions')->build_project_security( $where, $username, $is_root, @user_categories );
    }

    $main_conditions->{'categories'} = \@user_categories;

    my ($cnt, @topics) = Baseliner->model('Topic')->topics_for_user({ limit => $limit, clear_filter => 1, where => $where, %$main_conditions, username=>$username }); #mdb->topic->find($where)->fields({_id=>0,_txt=>0})->all;

    my @topic_cis = map {$_->{mid}} @topics;
    @topics = map { my $t = {};  $t = hash_flatten($_); $t } @topics;
    # my @cis = map { ($_->{to_mid},$_->{from_mid})} mdb->master_rel->find({ '$or' => [{from_mid => mdb->in(@topic_cis)},{to_mid => mdb->in(@topic_cis)}]})->all;
    # my %ci_names = map { $_->{mid} => $_->{name}} mdb->master->find({ mid => mdb->in(@cis)})->all;

    # $c->stash->{json} = { success => \1, data=>\@topics, cis=>\%ci_names };
    return \@topics;

}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
