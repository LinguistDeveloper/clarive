package Baseliner::Model::Notification;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);
use v5.10;

BEGIN { extends 'Catalyst::Model' }

register 'action.admin.notification' => { name=>'Admin Notifications' };

register 'menu.admin.notifications' => {
    label    => 'Notifications',
    title    => _loc ('Notifications'),
    action   => 'action.admin.notification',
    url_comp => '/comp/notifications.js',
    icon     => '/static/images/log_w.gif',
    tab_icon => '/static/images/log_w.gif'
};

sub get_actions{
    return ('SEND','EXCLUDE');
}

sub get_carriers{
    return ('TO','CC','BCC');
}

sub get_type_recipients{
    return ('Default','Users','Roles','Groups','Emails','Actions');
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
            when ('Default') {
                @recipients = ({id => 'Default', name => 'Default'});
            }            
        };
        return wantarray ? @recipients : \@recipients;
    }catch{
        _throw _loc( 'Error reading recipients: %1', shift() );    
    };
}

1;


