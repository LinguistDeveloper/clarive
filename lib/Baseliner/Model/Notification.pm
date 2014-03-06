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
    return ('Default','Users','Roles','Actions','Fields');
}

sub get_recipients{
    my ( $self, $type ) = @_;
    try{
        my @recipients;
        given ($type) {
            when ('Users') {
                @recipients = map {+{id => $_->{mid}, name => $_->{username}, description => $_->{realname} ? $_->{realname}:''  }}
                            Baseliner->model('Baseliner::BaliUser')->search(undef,{select=>['mid','username','realname'], order_by=>{-asc=>['realname']}})->hashref->all;
            }
            when ('Roles') {
                @recipients = map {+{id => $_->{id}, name => $_->{role}, description => $_->{description} ? $_->{description}:''  }} 
                            Baseliner->model('Baseliner::BaliRole')->search(undef,{select=>['id','role','description'], order_by=>{-asc=>['role']}})->hashref->all;
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
    my $valid;
    
    foreach my $key (keys $data->{scopes}){
    	if( !exists $notify_scope->{$key} ){
        	$valid = 0;
        	last; 
        }else{ $valid = 1; }
    }
    
    if ($valid == 1) {
    	foreach my $key (keys $notify_scope){
        	if( exists $data->{scopes}->{$key}->{'*'} ){
            	$valid = 1;
            }
            else{
        		if( ref $notify_scope->{$key} eq 'ARRAY'){
            		foreach my $value (@{$notify_scope->{$key}}){
            			if (exists $data->{scopes}->{$key}->{$value}) {
                			$valid = 1;
                    		last;
                		}else{ $valid = 0;}
            		}
        		}
        		else{
        			if (exists $data->{scopes}->{$key}->{$notify_scope->{$key}}) {
        				$valid = 1;
        			}else{ $valid = 0; }
        		}
        		last unless $valid == 1;
            } 
    	}
    }   
    return $valid;
}

sub exclude_default{
    my ( $self, $p ) = @_;
    my $event_key = $p->{event_key} or _throw 'Missing parameter event_key';
    my $exclude_default = 0;
    my @recipients = map { (_load $_->{data})->{recipients} } DB->BaliNotification->search({ event_key => $event_key, is_active => 1, action => 'EXCLUDE' } )->hashref->all;
    
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
    
    my @rs_notify = DB->BaliNotification->search({ event_key => $event_key, is_active => 1, action => $action } )->hashref->all;
    
    if ( @rs_notify ) {
		foreach my $row_send ( @rs_notify ){
			my $data = _load($row_send->{data});
    
            my $valid = 0;
    		if ($notify_scope) {
                $valid = $self->isValid({ data => $data, notify_scope => $notify_scope});    
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
                    		given ($type) {
                        		when ('Actions')    { $notification->{$row_send->{template_path}}->{$carrier}->{$type}->{$key_value} = 1; }
                        		default             { $notification->{$row_send->{template_path}}->{$carrier}->{$type}->{$key_value} = $data->{recipients}->{$carrier}->{$type}->{$key_value}; }
                    		};
                		}
            		}
        		}
    		}
		}
        
		foreach my $plantilla (keys $notification){
			foreach my $carrier ( keys $notification->{$plantilla}) {
    			my @users;
        		foreach my $type (keys $notification->{$plantilla}->{$carrier}){
        			my @tmp_users;
        			given ($type) {
            			when ('Users') 	    { 
                        	if ( exists $notification->{$plantilla}->{$carrier}->{$type}->{'*'} ){
                                #if (exists $notify_scope->{project}){
                                #	@tmp_users = Baseliner->model('Users')->get_users_friends_by_projects(mid => $mid, $notify_scope->{project});
                                #}
                                #else{
                                	@tmp_users = Baseliner->model('Users')->get_users_username;
                                #}
                            }
                            else{
                        		@tmp_users = values $notification->{$plantilla}->{$carrier}->{$type};                             
                            }
                        }
                        when ('Actions') 	{
                            my @actions;
                            if ( exists $notification->{$plantilla}->{$carrier}->{$type}->{'*'} ){
								@actions = ('*');                            
                            }
                            else{
                            	@actions = keys $notification->{$plantilla}->{$carrier}->{$type};
                            }
                            my $query = {};
                            $query->{action} = \@actions;
                            delete $query->{action} if (scalar @actions == 1 && $actions[0] eq '*');                                
                            my @roles = map {$_->{id_role}} Baseliner->model('Baseliner::BaliRoleaction')->search($query)->hashref->all;
                            @tmp_users = Baseliner->model('Users')->get_users_from_mid_roles_topic( roles => \@roles, mid => $mid );
                            #@tmp_users = Baseliner->model('Users')->get_users_from_actions(mid => $mid, actions => \@actions, projects => \@prj_mid);
                        }
                        when ('Roles') 	    {
                        	my @roles;
                        	if ( exists $notification->{$plantilla}->{$carrier}->{$type}->{'*'} ){
                            	if (exists $notify_scope->{project}){
                                	@roles = Baseliner->model('Users')->get_roles_from_projects(mid => $mid, $notify_scope->{project});
                            	}
                                else{
                            		@roles = ('*');
                                }
                            }
                            else{
                            	@roles = keys $notification->{$plantilla}->{$carrier}->{$type};
                            }
                            @tmp_users = Baseliner->model('Users')->get_users_from_mid_roles_topic( roles => \@roles, mid => $mid );
                            #@tmp_users = Baseliner->model('Users')->get_users_from_mid_roles( roles => \@roles, projects => \@prj_mid);                            
                        }
                        when ('Fields') 	    {
                            my @fields = map {lc($_)} keys $notification->{$plantilla}->{$carrier}->{$type};
                            my $topic = mdb->topic->find_one({mid=>"$mid"});
                            my @users_mid;
                            for my $field (@fields){
                                push @users_mid, $topic->{$field};
                            }
                            @tmp_users= map {$_->{name}} ci->user->find({mid=>@users_mid})->all;

                            #@tmp_users = map { _ci($_->{to_mid})->name }
                            #                        DB->BaliMasterRel->search(  { 'LOWER(rel_field)' => \@fields, rel_type => 'topic_users'},
                            #                                                    { select => 'to_mid' })->hashref->all;
                        }                        
            		};
            		push @users, @tmp_users;
        		}
     			if (@users) {
                	my %users; 
                    map { $users{$_} = 1 } @users;
                    
        			$notification->{$plantilla}->{$carrier} = \%users;
        		}
        		else{
        			delete $notification->{$plantilla}->{$carrier} ;
        		}
    		}
    		my @totCarrier = keys $notification->{$plantilla};
    		if (!@totCarrier) {
    			delete $notification->{$plantilla};
    		}
		};
    }
    
    if (keys $notification){
    	return $notification ;
    }
    else {
    	return undef ;
    }
}

sub get_notifications {
	my ( $self, $p ) = @_;
    my $event_key = $p->{event_key} or _throw 'Missing parameter event_key';
    my $notify_scope = $p->{notify_scope}; #or _throw 'Missing parameter notify_scope';
    my $mid = $p->{mid};
    my @notify_default = _array ($p->{notify_default});
    
	my $send_notification;
    $send_notification = $self->get_rules_notifications( { event_key => $event_key, action => 'SEND', notify_scope => $notify_scope, mid => $mid } );
    
    my $name_config = $event_key;
    $name_config =~ s/event.//g;
    my $template = Baseliner->model( 'ConfigStore' )->get( 'config.notifications.' . $name_config . '.template_default')->{template_default};
	if (!$template || $template eq ''){
    	$template =  Baseliner->model( 'ConfigStore' )->get( 'config.notifications.template_default' )->{template_default};
    }
    
    if(!$self->exclude_default( {event_key => $event_key} )){
        if (exists $send_notification->{$template}){
            map { $send_notification->{$template}->{TO}->{$_} = 1 } @notify_default;        
        }else{
            if (@notify_default){
                my %users; 
                map { $users{$_} = 1 } @notify_default;            
                $send_notification->{$template}->{TO} = \%users;
            }
        }
    }
    
	my $exclude_notification;
    $exclude_notification = $self->get_rules_notifications( { event_key => $event_key, action => 'EXCLUDE', notify_scope => $notify_scope, mid => $mid  } );    
    if ($exclude_notification){
    	foreach my $plantilla ( keys $exclude_notification ){
        	foreach my $carrier ( keys $exclude_notification->{$plantilla} ){
            	foreach my $value ( keys $exclude_notification->{$plantilla}->{$carrier} ){
                	delete $send_notification->{$plantilla}->{$carrier}->{$value};
                }
            }
        }
    }

    if ($send_notification){
        foreach my $plantilla ( keys $send_notification ){
            foreach my $carrier ( keys $send_notification->{$plantilla} ){
                my @totUsers = keys $send_notification->{$plantilla}->{$carrier};
                if (!@totUsers) {
                    delete $send_notification->{$plantilla}->{$carrier};
                }
                else{
                    my @users;
                    foreach my $user ( keys $send_notification->{$plantilla}->{$carrier} ){
                        push @users, $user;	
                    }
                    $send_notification->{$plantilla}->{$carrier} = \@users;
                }
            }
            my @totCarrier = keys $send_notification->{$plantilla};
            if (!@totCarrier) {
                delete $send_notification->{$plantilla};
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


