package BaselinerX::Job::Service::Notify;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use BaselinerX::BdeUtils;
use BaselinerX::Dist::Utils;
use BaselinerX::Comm::Balix;
use Data::Dumper;
use Try::Tiny;

with 'Baseliner::Role::Service';

register 'action.notify.scheduled_job' => { name=>'Notify when job is scheduled' };

register 'service.scheduled.notify' => {
  name   => 'Notify users when job is scheduled',
  config  => 'config.comm.email',
  handler => \&main
};

sub main {
   my ($self, $c, $mailcfg) = @_;
   my $job       = $c->stash->{job};
   my $log       = $job->logger;
   my $job_stash = $job->job_stash;
   my $contents  = $job_stash->{ contents };
   my $bl        = $job->bl;

   my $now=DateTime->now;
   my $start=parse_dt( '%Y-%m-%d %H:%M',$job->{job_data}->{starttime} );

   return unless $bl eq 'PROD';  ## Slo se refresca LinkList en PROD
#   return unless $start->delta_ms($now)->in_units('minutes') > 10 ;

   use Encode;
   my $action = 'action.notify.scheduled_job';
   my $not_action = 'action.notify.disabled';

   # find receivers
   my $action = 'action.notify.scheduled_job';
   my $not_action = 'action.notify.disabled';
   my @ns;

   my @users = sort {$a cmp $b} _unique map {
   if ( $_->{provider} ) {
      push @ns, "project/".cam_to_projectid((ns_split($_->{application}))[1]);
      Baseliner->model('Permissions')->list(
         action      => [ $action ],
         not_action  => [$not_action ],
         ns          => "project/".cam_to_projectid((ns_split($_->{application}))[1]),
         bl          => $job->job_data->{bl}
         );
   } else {
      my $nature=$_->{item};$nature=~s{nature/}{nature.}g;
      my $rpt_action = $c->model('Registry')->get( $nature  )->action;

      Baseliner->model('Permissions')->list(
         action      => [ $action, $rpt_action ],
         not_action  => [ $not_action ],
         ns          => @ns,
         bl          => $job->job_data->{bl}
         );
      }
   } _array $job_stash->{contents};

   @users = grep { $_ ne 'root' } _unique @users;

   #_log "Notifying users: " . join ',',@users;

   _throw _loc( "No users found for action %1", $action ) unless @users;

   # Get user info
   my $u = Baseliner->model('Users')->get( $job->{job_data}->{username} );
   my $realname = $u->{realname} || $job->username ;
   $realname = encode("iso-8859-15", $realname);
   $realname =~ s{\?}{}g;
   $realname =~ s{}{}g;
   utf8::downgrade($realname);

   my @users_with_realname = map {
        my $ud = Baseliner->model('Users')->get( $_ );
        my $rn = $ud->{realname};
        $rn = encode("iso-8859-15", $rn);
        $rn =~ s{\?}{}g;
        $rn =~ s{}{}g;
        utf8::downgrade($rn);
        $rn ? "$_ ($rn)" : $_;
   } @users;

   my @packageList = _unique map{ (ns_split($_->{item}))[1] if $_->{provider}} _array $job_stash->{contents};
   my $subject = _loc("Scheduled at %1 of %2",$start->hms(':'),$start->dmy('/'));
   # Queue email
   my $url_log = sprintf( "%s/tab/job/log/list?id_job=%d", _notify_address(), $job->jobid ); 

   my $msg = Baseliner->model('Messaging')->notify(
            subject => $subject,
            sender  => $mailcfg->{from},
            to      => { users => [ _unique(@users) ] },
            carrier =>'email',
            template => 'email/job.html',
            template_engine => 'mason',
            vars   => {
                action    => _loc('scheduled'),
                bl        => $job->bl,
                job       => $job->name,
                packageList => [@packageList],
                realname  => $realname,
                status    => _loc('READY'),
                subject   => $subject,  # Job xxxx: (error|finished|started|cancelled...)
                to        => [_unique(@users)],
                type      => $job->{job_data}->{type},
                username  => $job->{job_data}->{username},
                url_log   => $url_log,
                url       => _notify_address(),
                windowType=> $job_stash->{approval_needed}->{reason} eq 'Pase Urgente'?'Urgente':'Normal'
            }
    );
}

1
