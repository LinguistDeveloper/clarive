package BaselinerX::Notificacion;
use Baseliner::Plug;
use Baseliner::Utils;

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
        { id => 'exclude_default', label => 'Exclude all notifications', default => 0},
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

1;


