package BaselinerX::Changeman::Service::notify;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use BaselinerX::Dist::Utils;
use BaselinerX::Comm::Balix;
use Data::Dumper;
use Try::Tiny;

with 'Baseliner::Role::Service';

register 'action.notify.job.linklist' => { name=>'Notify when job needs to refresh the linklist' };

register 'service.changeman.notify' => {
  name    => 'Notify users when job needs refresh the linklist',
  config  => 'config.changeman.connection',
  handler => \&main
};

sub main {
    my ($self, $c, $config) = @_;
    my $job       = $c->stash->{job};
    my $log       = $job->logger;
    my $job_stash = $job->job_stash;
    my $contents  = $job_stash->{ contents };
    my $bl        = $job->bl;

    return unless $job_stash->{approval_needed}->{reason} =~ m{Linklist}g;
    return unless $bl eq 'PROD';  ## Slo se refresca LinkList en PROD

    use Encode;
    my $action = 'action.notify.job.linklist';
    my @users;

    # find parents
    push @users, Baseliner->model('Permissions')->list(
        action      => $action,
        bl          => $bl,
        );
        @users = grep { $_ ne 'root' } _unique @users;

    _log "Notifying users: " . join ',',@users;

    _throw _loc( "No users found for action %1", $action ) unless @users;

        # Get user info
        my $u = Baseliner->model('Users')->get( $job->{job_data}->{username} );
        my $realname = $u->{realname} || $job->username ;
        $realname = encode("iso-8859-15", $realname);
        $realname =~ s{\?}{}g;
        $realname =~ s{ñ}{}g;
        utf8::downgrade($realname);

        my @users_with_realname = map {
            my $ud = Baseliner->model('Users')->get( $_ );
            my $rn = $ud->{realname};
            $rn = encode("iso-8859-15", $rn);
            $rn =~ s{\?}{}g;
            $rn =~ s{ñ}{}g;
            utf8::downgrade($rn);
            $rn ? "$_ ($rn)" : $_;
            } @users;

    my @items = map{ my ($d,$it)=ns_split($_->{item}); $it } _array $job_stash->{contents};
    my $subject = _loc('Job %1 needs to restart the LinkList',$job->name);
    my $reason = _loc('Needs to restart the LinkList');
        # Queue email
    my $items = join ' ', @items;

    my $msg = Baseliner->model('Messaging')->notify(
        to               => { users => [ _unique(@users) ] },
        subject          => $subject,
        sender           => _loc('Job Manager'),
        carrier          => 'email',
        template         => 'email/linklist.html',
        template_engine  => 'mason',
        vars => {
            subject      => $subject,
            jobname      => $job->name,
            items        => [ _unique @items ],
            reason       => $reason,
            requested_by => $u->{username},
            requested_to => [ _unique(@users_with_realname) ] ,
            realname     => $realname
            }
        );

}

1
