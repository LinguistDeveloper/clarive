package Baseliner::Model::Notification;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Model::Topic;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);
use v5.10;
use experimental 'autoderef', 'switch';

BEGIN { extends 'Catalyst::Model' }

with 'Baseliner::Role::Service';

register 'action.admin.notification' => { name=> _locl('Admin Notifications') };

register 'menu.admin.notifications' => {
    label    => _locl('Notifications'),
    title    => _locl('Notifications'),
    action   => 'action.admin.notification',
    url_comp => '/comp/notifications.js',
    icon     => '/static/images/icons/email.svg',
    tab_icon => '/static/images/icons/email.svg'
};

register 'config.notifications' => {
    metadata => [
        { id => 'template_default', label => _locl('Template by default'), default => '/email/generic_topic.html'},
        { id => 'exclude_default', label => _locl('Exclude all default notifications'), default => '0'}
    ]
};

register 'config.comm.email' => {
    name => 'Email configuration',
    metadata => [
        { id=>'frequency', name=>_locl('Email daemon frequency'), default=>10 },
        { id=>'timeout', name=>_locl('Email daemon process queue timeout'), default=>30 },
        { id=>'max_message_size', name=>_locl('Max message size in bytes'), default=>(1024 * 1024) },
        { id=>'max_attach_size', name=>_locl('Max attach size in bytes'), default=>(1024 * 1024 * 7) },
        { id=>'server', name=>_locl('Email server'), default=>'smtp.example.com' },
        { id=>'from', name=>_locl('Email default sender'), default=>'user <user@mailserver>' },
        { id=>'domain', name=>_locl('Email domain'), default=>'exchange.local' },
        { id=>'auto_generate_empty_emails', name=>_locl('Auto generate emails for users with empty email field'), default=>'0' },
        { id=>'max_attempts', name=>_locl('Max attempts'), default=>10 },
        { id=>'baseliner_url', name=>_locl('Base URL to access baseliner'), default=>'http://localhost:3000' },
        { id=>'default_template', name=>_locl('Default template for emails'), default=>'/email/generic.html' },
        { id=>'smtp_auth', name=>_locl('SMTP needs authentication'), default=>0 },
        { id=>'smtp_user', name=>_locl('SMTP server user'), default=>'' },
        { id=>'smtp_password', name=>_locl('SMTP server password'), default=>'' },

    ]
};

register 'service.daemon.email' => {
    name => _locl('Email Daemon'),
    icon => '/static/images/icons/service-daemon-email.svg',
    config => 'config.comm.email',
    show_in_palette => 0,
    handler => sub {
        my $self = shift;
        require Baseliner::Comm::Email;
        Baseliner::Comm::Email->new->daemon( @_ );
    }
};

register 'service.email.flush' => {
    name => _locl('Flush Email Queue Once'),
    icon => '/static/images/icons/service-email-flush.svg',
    config => 'config.comm.email',
    handler => sub {
        my $self = shift;
        require Baseliner::Comm::Email;
        Baseliner::Comm::Email->new->process_queue( @_ );
    }
};

sub get_actions{
    return ('SEND','EXCLUDE');
}

sub get_carriers{
    return ('TO','CC','BCC');
}

sub get_type_recipients{
    #return ('Default','Users','Roles','Groups','Emails','Actions');
    return ('Default','Users','Roles','Actions','Fields','Owner','Emails');
}

sub get_recipients{
    my ( $self, $type ) = @_;
    try{
        my @recipients;
        given ($type) {
            when ('Users') {
                @recipients = map {+{id => $_->{mid}, name => $_->{username}, description => $_->{realname} ? $_->{realname}:''  }}
                            ci->user->find()->fields({mid => 1, username => 1, realname => 1, _id => 0})->sort({realname => 1})->all;

            }
            when ('Roles') {
                @recipients = map {+{id => $_->{id}, name => $_->{role}, description => $_->{description} ? $_->{description}:''  }}
                            mdb->role->find()->fields({ id=>1, role=>1, description=>1, _id=>0 })->sort({ role => 1 })->all;
            }
            when ('Emails') {
                @recipients = ({id => 'Emails', name => 'Emails'});
            }
            when ('Actions') {
                @recipients = map {+{id => $_, name => $_, description => ''  }}
                            Baseliner::Core::Registry->starts_with('action.');
            }
            when ('Fields') {
                my @fields = Baseliner::Model::Topic->new->get_fieldlet_nodes();
                my @name_fields = _unique map { $$_{id_field}; } grep { $$_{key} eq 'fieldlet.system.users' } @fields;
                @recipients = map { +{ id => $_, name => $_ } } @name_fields;
            }
            when ('Default') {
                @recipients = ({id => 'Default', name => 'Default'});
            }
            when ('Owner') {
                @recipients = ({id => 'Owner', name => 'Owner'});
            }
        };
        return wantarray ? @recipients : \@recipients;
    }catch{
        _throw _loc( 'Error reading recipients: %1', shift() );
    };
}

sub isValid {
    my ( $self, $p ) = @_;
    my $data         = $p->{data}         or _throw 'Missing parameter data';
    my $notify_scope = $p->{notify_scope} or _throw 'Missing parameter notify_scope';
    my $mid          = $p->{mid};
    my $valid        = 1;

SCOPE: foreach my $key ( keys %{ $data->{scopes} } ) {
        my @data_scope;
        if ( $key eq 'step' ) {
            my @steps = _array $data->{scopes}->{$key};

            foreach my $step (@steps) {
                push( @data_scope, $step->{name} );
            }
        }
        else {
            @data_scope = _array keys %{ $data->{scopes}->{$key} };
        }

        if ( $data_scope[0] eq '*' ) {
            next SCOPE;
        }

        if ( !exists $notify_scope->{$key} || scalar( _array( $notify_scope->{$key} ) ) == 0 ) {
            if ( $mid && $key eq 'project' ) {
                my @chi = ci->new($mid)->children( where => { collection => 'topic' } );
                my @projs = _unique map { $_->{mid} } map { $_->projects } @chi;
                my $found = 0;
            PROJECT: for (@projs) {
                    if ( $_ ~~ @data_scope ) {
                        $found = 1;
                        last PROJECT;
                    }
                }
                if ( !$found ) {
                    $valid = 0;
                    last SCOPE;
                }
            }
            else {
                $valid = 0;
                last SCOPE;
            }
        }
        else {
            my @event_scope = _array $notify_scope->{$key};

            my $found = 0;
        EVENT: for (@event_scope) {
                if ( $_ ~~ @data_scope ) {
                    $found = 1;
                    last EVENT;
                }
            }
            if ( !$found ) {
                $valid = 0;
                last SCOPE;
            }
        }
    }
    return $valid;
}

sub exclude_default{
    my ( $self, $p ) = @_;
    my $event_key = $p->{event_key} or _throw 'Missing parameter event_key';
    my $exclude_default = 0;
    my @recipients = map { ($_->{data})->{recipients} } mdb->notification->find({event_key => $event_key, is_active => mdb->true, action => 'EXCLUDE'})->all;
    foreach my $recipient (@recipients){
        foreach my $carrier (keys $recipient){
            foreach my $key (keys $recipient->{$carrier}){
                $exclude_default = 1;
                last;
            }
            last if $exclude_default;
        }
        last if $exclude_default;
    }
    return $exclude_default;
}

sub get_rules_notifications{
    my ( $self, $p ) = @_;
    my $event_key = $p->{event_key} or _throw 'Missing parameter event_key';
    my $action = $p->{action} or _throw 'Missing parameter action';
    my $notify_scope = $p->{notify_scope}; # or _throw 'Missing parameter notify_scope';
    my $mid = $p->{mid};

    my $notification = {};
    my @rs_notify = mdb->notification->find({event_key => $event_key, is_active => mdb->true, action => $action})->all;
    #my @prj_mid = map { $_->{mid} } ci->related( mid => $mid, where=>{collection => 'project'}) if $mid;

    if ( @rs_notify ) {
        foreach my $row_send ( @rs_notify ){
            #my $data = ref $row_send->{data} ? $row_send->{data} : _load($row_send->{data});
            my $data = $self->encode_data($row_send->{data});

            my $valid = 0;
            if ($notify_scope) {
                $valid = $self->isValid({ data => $data, notify_scope => $notify_scope, mid => $mid});
            }else{
                $valid = 1 unless $data->{scopes} && keys %{ $data->{scopes} };
            }
            if ($valid == 1){
                my $actions;
                my $roles;

                foreach my $carrier (keys $data->{recipients}){
                    my $type;
                    foreach $type (keys $data->{recipients}->{$carrier}){
                        my @values;
                        foreach my $key_value (keys $data->{recipients}->{$carrier}->{$type}){
                            #my $key = Util->_md5( $row_send->{template_path} . '#' . ( $row_send->{subject} // '') );
                            my $key = Util->_md5( $row_send->{template_path} . '#' . ( $row_send->{subject} // '') );
                            $notification->{$key}{subject}       = $row_send->{subject};
                            $notification->{$key}{template_path} = $row_send->{template_path};
                            given ($type) {
                                when ('Actions') {
                                    $notification->{$key}{carrier}{$carrier}->{$type}->{$key_value} = 1;
                                }
                                default {
                                    $notification->{$key}{carrier}{$carrier}->{$type}->{$key_value} = $data->{recipients}->{$carrier}->{$type}->{$key_value};
                                }
                            };
                        }
                    }
                }
            }
        }
        foreach my $key (keys $notification){
            foreach my $carrier ( keys $notification->{$key}{carrier}) {
                my @users;
                foreach my $type (keys $notification->{$key}{carrier}{$carrier}){
                    my @tmp_users;
                    given ($type) {
                        when ('Users')         {
                            if ( exists $notification->{$key}{carrier}{$carrier}->{$type}->{'*'} ){
                                @tmp_users = Baseliner::Model::Users->new->get_users_username;
                            }
                            else{
                                @tmp_users = values $notification->{$key}{carrier}{$carrier}->{$type};
                            }
                        }
                        when ('Actions')     {
                            my @actions;
                            if ( exists $notification->{$key}{carrier}{$carrier}->{$type}->{'*'} ){
                                @actions = ('*');
                            }
                            else{
                                @actions = keys $notification->{$key}{carrier}{$carrier}->{$type};
                            }
                            my $query = {};
                            $query->{action} = \@actions;

                            my @full_roles = mdb->role->find->all;

                            my @roles;
                            if (scalar @actions == 1 && $actions[0] eq '*'){
                                delete $query->{action};
                                @roles = map {$_->{id}} @full_roles;
                            }else{
                                foreach my $role (@full_roles){
                                    my $actions = $role->{actions};
                                    foreach my $action (@$actions){
                                        foreach my $actual_action (@{$query->{action}}){
                                            if($action->{action} eq $actual_action){
                                                push @roles, $role->{id};
                                            }
                                        }
                                    }
                                }
                            }
                            @roles = _unique @roles;

                            @tmp_users = Baseliner::Model::Users->new->filter_users_roles(
                                roles        => \@roles,
                                notify_scope => $notify_scope,
                                mid          => $mid
                            );
                        }
                        when ('Roles') {
                            my @roles;
                            if ( exists $notification->{$key}{carrier}{$carrier}->{$type}->{'*'} ) {
                                if ( exists $notify_scope->{project} ) {
                                    @roles = Baseliner::Model::Users->new->get_roles_from_projects(
                                        $notify_scope->{project} );
                                }
                                else {
                                    @roles = ('*');
                                }
                            }
                            else {
                                @roles = keys $notification->{$key}{carrier}{$carrier}->{$type};
                            }
                            @tmp_users = Baseliner::Model::Users->new->filter_users_roles(
                                roles        => \@roles,
                                notify_scope => $notify_scope,
                                mid          => $mid
                            );
                        }
                        when ('Fields')         {
                            my @fields = keys $notification->{$key}{carrier}{$carrier}->{$type};
                            my $topic = mdb->topic->find_one({mid=>"$mid"});
                            my @users_mid;
                            for my $field (@fields){
                                push @users_mid, _array($topic->{$field});
                            }
                            @tmp_users= map {$_->{name}} ci->user->find({mid=>mdb->in(@users_mid)})->all;

                        }
                        when ('Emails') {
                            my @emails = keys $notification->{$key}{carrier}{$carrier}->{$type};
                            push @tmp_users, @emails;
                        }
                        when ('Owner')      {
                            my $topic = mdb->topic->find_one({mid=>"$mid"});
                            push @tmp_users, $topic->{created_by};
                        }
                    };
                    push @users, @tmp_users;
                }
                 if (@users) {
                    my %users;
                    map { $users{$_} = 1 } @users;

                    $notification->{$key}{carrier}{$carrier} = \%users;
                }
                else{
                    delete $notification->{$key}{carrier}{$carrier} ;
                }
            }
            my @totCarrier = keys $notification->{$key};
            if (!@totCarrier) {
                delete $notification->{$key};
            }
        };
    }
    if (keys $notification){
        return $notification;
    }
    else {
        return undef ;
    }
}


sub decode_data {
    my ($self,$p) = @_;
    my $data = _load $p;
    if($data->{recipients}){
        if($data->{recipients}->{TO}){
            $data->{recipients}->{TO} = $self->decode_recipients($data,'TO');
        }
        if($data->{recipients}->{CC}){
            $data->{recipients}->{CC} = $self->decode_recipients($data,'CC');
        }
        if($data->{recipients}->{BCC}){
            $data->{recipients}->{BCC} = $self->decode_recipients($data,'BCC');
        }
    }
    if($data->{scopes}){
        if($data->{scopes}->{category}){
            $data->{scopes}->{category} = $self->decode_scopes($data,'category');
        }
        if($data->{scopes}->{category_status}){
            $data->{scopes}->{category_status} = $self->decode_scopes($data,'category_status');
        }
        if($data->{scopes}->{project}){
            $data->{scopes}->{project} = $self->decode_scopes($data,'project');
        }
        if($data->{scopes}->{field}){
            $data->{scopes}->{field} = $self->decode_scopes($data,'field');
        }
        if($data->{scopes}->{bl}){
            $data->{scopes}->{bl} = $self->decode_scopes($data,'bl');
        }
        if($data->{scopes}->{status}){
            $data->{scopes}->{status} = $self->decode_scopes($data,'status');
        }
        if($data->{scopes}->{step}){
            $data->{scopes}->{step} = $self->decode_scopes($data,'step');
        }
    }
    return $data;
}

sub decode_scopes {
    my ( $self, $data, $p ) = @_;
    if ( $p eq 'field' ) {
        $data->{scopes}->{field} = [ values $data->{scopes}->{field} ];
    }
    else {
        my @scopes;
        if ( $p eq 'step' ) {
            foreach my $scope ( _array $data->{scopes}->{step} ) {
                push @scopes, { 'name' => $scope };
            }
        }
        else {
            foreach ( keys $data->{scopes}->{$p} ) {
                push @scopes, { 'mid' => $_, 'name' => $data->{scopes}->{$p}->{$_} };
            }
        }
        $data->{scopes}->{$p} = \@scopes;
    }
}

sub decode_recipients {
    my ($self, $data, $p) = @_;
    if($data->{recipients}->{$p}->{Fields}){
        $data->{recipients}->{$p}->{Fields} = [keys $data->{recipients}->{$p}->{Fields}];
    }
    if($data->{recipients}->{$p}->{Owner}){
        $data->{recipients}->{$p}->{Owner} = [keys $data->{recipients}->{$p}->{Owner}];
    }
    if($data->{recipients}->{$p}->{Emails}){
        $data->{recipients}->{$p}->{Emails} = [keys $data->{recipients}->{$p}->{Emails}];
    }
    if($data->{recipients}->{$p}->{Actions}){
        $data->{recipients}->{$p}->{Actions} = [keys $data->{recipients}->{$p}->{Actions}];
    }
    if($data->{recipients}->{$p}->{Roles}){
        my @ar;
        foreach (keys $data->{recipients}->{$p}->{Roles}){
            push @ar, {'mid' => $_, 'name' => $data->{recipients}->{$p}->{Roles}->{$_}};
        }
        $data->{recipients}->{$p}->{Roles} = \@ar;
    }
    if($data->{recipients}->{$p}->{Users}){
        my @ar;
        foreach (keys $data->{recipients}->{$p}->{Users}){
            push @ar, {'mid' => $_, 'name' => $data->{recipients}->{$p}->{Users}->{$_}};
        }
        $data->{recipients}->{TO}->{Users} = \@ar;
    }
    return $data->{recipients}->{$p};
}

sub encode_data {
    my ($self,$data) = @_;
    if($data->{scopes}){
        $data->{scopes} = $self->encode_scopes($data->{scopes});
    }
    if($data->{recipients}){
        if($data->{recipients}->{TO}){
            $data->{recipients}->{TO} = $self->encode_recipients($data->{recipients}, 'TO');
        }
        if($data->{recipients}->{CC}){
            $data->{recipients}->{CC} = $self->encode_recipients($data->{recipients}, 'CC');
        }
        if($data->{recipients}->{BCC}){
            $data->{recipients}->{BCC} = $self->encode_recipients($data->{recipients}, 'BCC');
        }
    }
    return $data;
}

sub encode_scopes {
    my ( $self, $scopes ) = @_;
    if ( $scopes->{project} ) {
        my %hash;
        foreach ( _array $scopes->{project} ) {
            $hash{ $_->{mid} } = $_->{name};
        }
        $scopes->{project} = \%hash;
    }
    if ( $scopes->{category_status} ) {
        my %hash;
        foreach ( _array $scopes->{category_status} ) {
            $hash{ $_->{mid} } = $_->{name};
        }
        $scopes->{category_status} = \%hash;
    }
    if ( $scopes->{category} ) {
        my %hash;
        foreach ( _array $scopes->{category} ) {
            $hash{ $_->{mid} } = $_->{name};
        }
        $scopes->{category} = \%hash;
    }
    if ( $scopes->{field} ) {
        my %hash;
        foreach ( _array $scopes->{field} ) {
            $hash{$_} = $_;
        }
        $scopes->{field} = \%hash;
    }
    if ( $scopes->{bl} ) {
        my %hash;
        foreach ( _array $scopes->{bl} ) {
            $hash{ $_->{mid} } = $_->{name};
        }
        $scopes->{bl} = \%hash;
    }
    if ( $scopes->{status} ) {
        my %hash;
        foreach ( _array $scopes->{status} ) {

            $hash{$_->{mid} } = $_->{name};
        }
        $scopes->{status} = \%hash;
    }

    return $scopes;
}

sub encode_recipients {
    my ($self, $recipients, $method) = @_;
    if($recipients->{$method}->{Fields}){
        my %hash;
        foreach (_array $recipients->{$method}->{Fields}){
            $hash{ $_ } = $_;
        }
        $recipients->{$method}->{Fields} = \%hash;
    }
    if($recipients->{$method}->{Owner}){
       my %hash;
        foreach (_array $recipients->{$method}->{Owner}){
            $hash{ $_ } = $_;
        }
        $recipients->{$method}->{Owner} = \%hash;
    }
    if($recipients->{$method}->{Emails}){
        my %hash;
        foreach (_array $recipients->{$method}->{Emails}){
            $hash{ $_ } = $_;
        }
        $recipients->{$method}->{Emails} = \%hash;
    }
    if($recipients->{$method}->{Actions}){
        my %hash;
        foreach (_array $recipients->{$method}->{Actions}){
            $hash{ $_ } = $_;
        }
        $recipients->{$method}->{Actions} = \%hash;
    }
    if($recipients->{$method}->{Roles}){
        my %hash;
        foreach (_array $recipients->{$method}->{Roles}){
            $hash{ $_->{mid} } = $_->{name};
        }
        $recipients->{$method}->{Roles} = \%hash;
    }
    if($recipients->{$method}->{Users}){
        my %hash;
        foreach (_array $recipients->{$method}->{Users}){
            $hash{ $_->{mid} } = $_->{name};
        }
        $recipients->{$method}->{Users} = \%hash;
    }
    return $recipients->{$method};
}

sub get_notifications {
    my ( $self, $p ) = @_;
    my $event_key = $p->{event_key} or _throw 'Missing parameter event_key';
    my $ev = Baseliner::Core::Registry->get( $event_key );
    my $notify_scope = $p->{notify_scope}; #or _throw 'Missing parameter notify_scope';
    my $mid = $p->{mid};
    my @notify_default = _array ($p->{notify_default});

    my $send_notification;
    $send_notification = $self->get_rules_notifications( { event_key => $event_key, action => 'SEND', notify_scope => $notify_scope, mid => $mid } );
    my $name_config = $event_key;
    $name_config =~ s/event.//g;

    # rgo: use the event to get it's defaults!
    my $template = $ev->{notify}->{template};
    $template ||= BaselinerX::Type::Model::ConfigStore->new->get( 'config.notifications.' . $name_config, enforce_metadata => 0)->{template_default};
    $template ||=  BaselinerX::Type::Model::ConfigStore->new->get( 'config.notifications' )->{template_default};
    if ($template) {
        _log( _loc("template for %1: %2", $event_key, $template ));
    } else {
        _error( _loc( 'Could not find template for %1', $event_key ) );
    }

    if(!$self->exclude_default( {event_key => $event_key} )){
        for my $notify ( values %$send_notification ) {
            if( $notify->{template_path} eq $template ){
                map { $notify->{carrier}{TO}{$_} = 1 } @notify_default;
            }else{
                if (@notify_default){
                    my %users;
                    map { $users{$_} = 1 } @notify_default;
                    map { $users{$_} = 1 } keys $notify->{carrier}{TO};
                    $notify->{carrier}{TO} = \%users;
                }
            }
        }
    }
    my $exclude_notification;
    $exclude_notification = $self->get_rules_notifications( { event_key => $event_key, action => 'EXCLUDE', notify_scope => $notify_scope, mid => $mid  } );
    if ($exclude_notification){
        foreach my $key ( keys $exclude_notification ){
            foreach my $carrier ( keys $exclude_notification->{$key} ){
                foreach my $value ( keys $exclude_notification->{$key}{carrier}{$carrier} ){
                    delete $send_notification->{$key}{carrier}{$carrier}->{$value};
                }
            }
        }
    }

    if ($send_notification){
        foreach my $key ( keys $send_notification ){
            foreach my $carrier ( keys $send_notification->{$key}{carrier} ){
                my @totUsers = keys $send_notification->{$key}{carrier}{$carrier};
                if (!@totUsers) {
                    delete $send_notification->{$key}{carrier}{$carrier};
                }
                else{
                    my @users;
                    foreach my $user ( keys $send_notification->{$key}{carrier}{$carrier} ){
                        push @users, $user;
                    }
                    $send_notification->{$key}{carrier}{$carrier} = \@users;
                }
            }
            my @totCarrier = keys $send_notification->{$key};
            if (!@totCarrier) {
                delete $send_notification->{$key};
            }
        }

        if (keys $send_notification ){
            return $send_notification ;
        }
        else {
            return undef ;
        }
    }
    else{
        return undef ;
    }

};


no Moose;
__PACKAGE__->meta->make_immutable;

1;
