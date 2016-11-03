package BaselinerX::Service::SystemMessages;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Carp;
use Try::Tiny;
use Path::Class;
use Baseliner::Sugar;
use Class::Date;

with 'Baseliner::Role::Service';

register 'service.job.system_messages' => {
    name => _locl('System Messages'),
    job_service  => 1,
    form => '/forms/system_messages.js',
    icon => "/static/images/icons/sms.svg",
    handler => \&run_create, };

sub run_create {
    my ($self, $c, $p)=@_;

    try {
        # create job CI
        $p->{_id} = mdb->oid;
        $p->{exp} = Class::Date->now + ( $p->{expires} || '1D' );
        $p->{action} = "add";
        $p->{username} = $c->{stash}->{username};

        model->SystemMessages->update($p);

        _info(_loc( "System message %1 created", "<b>$p->{title}</b>" ));
        return 1;
    } catch {
        my $err = shift;
        _fail(_loc( "Error creating system message: %1", "$err" ));
    };
}

1;
