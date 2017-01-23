package BaselinerX::Notificacion;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;

with 'Baseliner::Role::Service';

register 'action.admin.notification' => { name=>_locl('Admin Notifications') };

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
        { id => 'exclude_default', label => _locl('Exclude all notifications'), default => 0},
    ]
};

register 'config.comm.email' => {
    name => 'Email configuration',
    metadata => [
        { id=>'frequency', name=>_locl('Email daemon frequency'), default=>10 },
        { id=>'timeout', name=>_locl('Email daemon process_queue timeout'), default=>30 },
        { id=>'max_message_size', name=> _locl('Max message size in bytes'), default=>(1024 * 1024) },
        { id=>'server', name=> _locl('Email server'), default=>'smtp.example.com' },
        { id=>'from', name=> _locl('Email default sender'), default=>'user <user@mailserver>' },
        { id=>'domain', name=> _locl('Email domain'), default=>'exchange.local' },
        { id=>'max_attempts', name=> _locl('Max attempts'), default=>10 },
        { id=>'baseliner_url', name=> _locl('Base URL to access baseliner'), default=>'http://localhost:3000' },
        { id=>'default_template', name=> _locl('Default template for emails'), default=>'/email/generic.html' },
        { id=>'smtp_auth', name=> _locl('SMTP needs authentication'), default=>0 },
        { id=>'smtp_user', name=> _locl('SMTP server user'), default=>'' },
        { id=>'smtp_password', name=> _locl('SMTP server password'), default=>''}
    ]
};

register 'service.daemon.email' => {
    name => _locl('Email Daemon'),
    config => 'config.comm.email',
    show_in_palette => 0,
    handler => sub {
        my $self = shift;
        require Baseliner::Comm::Email;
        Baseliner::Comm::Email->new->daemon( @_ );
    }
};

register 'service.email.flush' => {
    name => _locl('Email Flush Queue Once'),
    config => 'config.comm.email',
    show_in_palette => 0,
    handler => sub {
        my $self = shift;
        require Baseliner::Comm::Email;
        Baseliner::Comm::Email->new->process_queue( @_ );
    }
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
