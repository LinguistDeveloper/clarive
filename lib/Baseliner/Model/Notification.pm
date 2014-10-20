package Baseliner::Model::Notification;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);
use v5.10;

BEGIN { extends 'Catalyst::Model' }

with 'Baseliner::Role::Service';

register 'action.admin.notification' => { name=>'Admin Notifications' };

register 'menu.admin.notifications' => {
    label    => 'Notifications',
    title    => _loc ('Notifications'),
    action   => 'action.admin.notification',
    url_comp => '/comp/notifications.js',
    icon     => '/static/images/icons/email.png',
    tab_icon => '/static/images/icons/email.png'
};

register 'config.notifications' => {
    metadata => [
        { id => 'template_default', label => 'Template by default', default => '/email/generic_topic.html'},
    ]
};

register 'config.comm.email' => {
    name => 'Email configuration',
    metadata => [
        { id=>'frequency', name=>'Email daemon frequency', default=>10 },
        { id=>'timeout', name=>'Email daemon process_queue timeout', default=>30 },
        { id=>'max_message_size', name=>'Max message size in bytes', default=>(1024 * 1024) },
        { id=>'server', name=>'Email server', default=>'smtp.example.com' },
        { id=>'from', name=>'Email default sender', default=>'user <user@mailserver>' },
        { id=>'domain', name=>'Email domain', default=>'exchange.local' },
        { id=>'max_attempts', name=>'Max attempts', default=>10 },
        { id=>'baseliner_url', name=>'Base URL to access baseliner', default=>'http://localhost:3000' },
        { id=>'default_template', name=>'Default template for emails', default=>'' },
        { id=>'smtp_auth', name=>'SMTP needs authentication', default=>0 },
        { id=>'smtp_user', name=>'SMTP server user', default=>'' },
        { id=>'smtp_password', name=>'SMTP server password', default=>'' },

    ]
};

register 'service.daemon.email' => {
    name => 'Email Daemon',
    config => 'config.comm.email',
    handler => sub {
        my $self = shift;
        require Baseliner::Comm::Email;
        Baseliner::Comm::Email->new->daemon( @_ );
    }
};

register 'service.email.flush' => {
    name => 'Email Flush Queue Once',
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
                            Baseliner->registry->starts_with('action.');
            }
            when ('Fields') {
                @recipients = ({id => 'Fields', name => 'Fields'});
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
    my $data = $p->{data} or _throw 'Missing parameter data';
    my $notify_scope = $p->{notify_scope} or _throw 'Missing parameter notify_scope';
    my $mid = $p->{mid};
    my $valid = 1;
    
    SCOPE: foreach my $key (keys %{$data->{scopes}}){
        my @data_scope = _array keys %{$data->{scopes}->{$key}};
        if ( $data_scope[0] eq '*' ) {
            next SCOPE;
        }

        if ( !exists $notify_scope->{$key} ) {
            if ( $mid && $notify_scope->{key} eq 'project' ) {
                my @chi = ci->new($mid)->children();
                my @projs = _unique map{ $_->{mid}} map {$_->projects} @chi;
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
    # if ($valid == 1) {
    # 	foreach my $key (keys $notify_scope){
    #     	if( exists $data->{scopes}->{$key}->{'*'} ){
    #         	$valid = 1;
    #         }
    #         else{
    #     		if( ref $notify_scope->{$key} eq 'ARRAY'){
    #         		foreach my $value (@{$notify_scope->{$key}}){
    #         			if (exists $data->{scopes}->{$key}->{$value}) {
    #             			$valid = 1;
    #                 		last;
    #             		}else{ $valid = 0;}
    #         		}
    #     		}
    #     		else{
    #     			if (exists $data->{scopes}->{$key}->{$notify_scope->{$key}}) {
    #     				$valid = 1;
    #     			}else{ $valid = 0; }
    #     		}
    #     		last unless $valid == 1;
    #         } 
    # 	}
    # }   
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
    #my @prj_mid = map { $_->{mid} } ci->related( mid => $mid, isa => 'project') if $mid;
    
    if ( @rs_notify ) {
		foreach my $row_send ( @rs_notify ){

			#my $data = ref $row_send->{data} ? $row_send->{data} : _load($row_send->{data});
            my $data = $self->encode_data($row_send->{data});

            my $valid = 0;
    		if ($notify_scope) {
                $valid = $self->isValid({ data => $data, notify_scope => $notify_scope, mid => $mid});    
            }else{
                $valid = 1 unless keys $data->{scopes};
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
            			when ('Users') 	    { 
                        	if ( exists $notification->{$key}{carrier}{$carrier}->{$type}->{'*'} ){
                                @tmp_users = Baseliner->model('Users')->get_users_username;
                            }
                            else{
                        		@tmp_users = values $notification->{$key}{carrier}{$carrier}->{$type};                           
                            }
                        }
                        when ('Actions') 	{
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
                            
                            @tmp_users = Baseliner->model('Users')->get_users_from_mid_roles_topic( roles => \@roles, mid => $mid );
                        }
                        when ('Roles') 	    {
                        	my @roles;
                        	if ( exists $notification->{$key}{carrier}{$carrier}->{$type}->{'*'} ){
                            	if (exists $notify_scope->{project}){
                                	@roles = Baseliner->model('Users')->get_roles_from_projects($notify_scope->{project});
                            	}
                                else{
                            		@roles = ('*');
                                }
                            }
                            else{
                            	@roles = keys $notification->{$key}{carrier}{$carrier}->{$type};
                            }
                            @tmp_users = Baseliner->model('Users')->get_users_from_mid_roles_topic( roles => \@roles, mid => $mid );
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
                        when ('Owner') 	    {
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
    }
    return $data;
}

sub decode_scopes {
    my ($self, $data, $p) = @_;  
    if($p eq 'field'){
       $data->{scopes}->{field} = [values $data->{scopes}->{field}];
    }
    else{ 
       my @ar;
       foreach (keys $data->{scopes}->{$p}){
          push @ar, {'mid' => $_, 'name' => $data->{scopes}->{$p}->{$_}};   
       }
       $data->{scopes}->{$p} = \@ar;
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
    my ($self,$scopes) = @_;
    if($scopes->{project}){  
        my %hash;
        foreach (_array $scopes->{project}){
            $hash{ $_->{mid} } = $_->{name};
        }
        $scopes->{project} = \%hash;
    }
    if($scopes->{category_status}){
        my %hash;
        foreach (_array $scopes->{category_status}){
            $hash{ $_->{mid} } = $_->{name};
        }
        $scopes->{category_status} = \%hash;
    }
    if($scopes->{category}){
        my %hash;
        foreach (_array $scopes->{category}){
            $hash{ $_->{mid} } = $_->{name};
        }
        $scopes->{category} = \%hash;
    }
    if($scopes->{field}){
        my %hash;
        foreach (_array $scopes->{field}){
            $hash{ $_ } = $_;
        }
        $scopes->{field} = \%hash;
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
    my $ev = Baseliner->registry->get( $event_key );
    my $notify_scope = $p->{notify_scope}; #or _throw 'Missing parameter notify_scope';
    my $mid = $p->{mid};
    my @notify_default = _array ($p->{notify_default});
    
	my $send_notification;
    $send_notification = $self->get_rules_notifications( { event_key => $event_key, action => 'SEND', notify_scope => $notify_scope, mid => $mid } );
    
    my $name_config = $event_key;
    $name_config =~ s/event.//g;
    
    # rgo: use the event to get it's defaults! 
    my $template = $ev->notify->{template};
    $template ||= Baseliner->model( 'ConfigStore' )->get( 'config.notifications.' . $name_config . '.template_default', enforce_metadata => 0)->{template_default};
    $template ||=  Baseliner->model( 'ConfigStore' )->get( 'config.notifications.template_default' )->{template_default};
    _log( "template for $event_key: $template" );
    
    if(!$self->exclude_default( {event_key => $event_key} )){
        for my $notify ( values %$send_notification ) {
            if( $notify->{template_path} eq $template ){
                map { $notify->{carrier}{TO}{$_} = 1 } @notify_default;        
            }else{
                if (@notify_default){
                    my %users; 
                    map { $users{$_} = 1 } @notify_default;            
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


1;


