use strict;
use warnings;
#use Test::More tests => 20;

$ENV{BALI_CMD} = 1;

#require Baseliner;
#my $c = Baseliner->new();
#Baseliner->app( $c );

#use_ok 'Catalyst::Test';
#use_ok 'Baseliner::Utils';

#use Baseliner::Utils;

package Carp;
sub ret_backtrace {
  my ($i, @error) = @_;
  my $mess;
  my $err = join '', @error;
  $i++;

  my $tid_msg = '';
  if (defined &threads::tid) {
    my $tid = threads->tid;
    $tid_msg = " thread $tid" if $tid;
  }

  my %i = caller_info($i);
  my $f = $i{file};
  $f =~ s{^.*/(.*?)}{$1}g;
  $mess = "$err\n at $f line $i{line}$tid_msg\n";

  while (my %i = caller_info(++$i)) {
	my $s = $i{sub_name};
	my $f = $i{file};
	$s =~ s{\(.*\)}{(...)}g;
	$f =~ s{^.*/(.*?)}{$1}g;
      $mess .= "\t$s called at $f line $i{line}$tid_msg\n";
  }
  return $mess;
}

package This::Is::A::Really::Long::Package::Name::That::Would::Be::Lovely::If::I::Were::A::Java::Programmer;
use Carp;
$Carp::MaxArgLen = 1;
$Carp::MaxArgNums = 1;
sub foo { confess 'monkeypatching for fun'; }
sub bar { foo(@_) }
sub jack { bar(@_) }
sub joe { jack(@_) }
sub ann { joe(@_) }

package main;
This::Is::A::Really::Long::Package::Name::That::Would::Be::Lovely::If::I::Were::A::Java::Programmer->ann("a string very interesting", "no likely", {}, []);
