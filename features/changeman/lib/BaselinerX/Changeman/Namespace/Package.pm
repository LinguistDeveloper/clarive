#
#===============================================================================
#
#         FILE:  package.pm
#
#  DESCRIPTION: Package namespace for Changeman
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Javi Rodriguez
#      COMPANY:
#      VERSION:  1.0
#      CREATED:  07/05/2011 02:37:31 PM
#     REVISION:  ---
#===============================================================================

package BaselinerX::Changeman::Namespace::Package;
use Moose;
use Baseliner::Utils;
use Catalyst::Exception;
use Try::Tiny;
use Data::Dumper;

with 'Baseliner::Role::Namespace::Package';
with 'Baseliner::Role::Namespace::JobOptions';
with 'Baseliner::Role::JobItem';
# with 'Baseliner::Role::Transition';
# with 'Baseliner::Role::Approvable';

has 'ns_type' => ( is=>'ro', isa=>'Str', default=>_loc('Changeman package') );
has 'view_to_baseline' => ( is=>'rw', isa=>'HashRef' );
has 'inc_id' => ( is=>'rw', isa=>'ArrayRef' );
has 'moreInfo' => ( is=>'rw', isa=>'Str' );
# has 'audit' => ( is=>'rw', isa=>'Str' );
# has 'circuito' => ( is=>'rw', isa=>'Str' );
# has 'codigo' => ( is=>'rw', isa=>'Str' );
# has 'motivo' => ( is=>'rw', isa=>'Str' );
# has 'promoteFrom' => ( is=>'rw', isa=>'Str' );
# has 'site' => ( is=>'rw', isa=>'Str' );
# has 'urgente' => ( is=>'rw', isa=>'Str' );

sub can_job {
    my ( $self, %p ) = @_;

	my $job_type = $p{job_type} or _throw 'Missing job_type parameter';
	my $bl = $p{bl} or _throw 'Missing bl parameter';

    # check active jobs
    my $active_job = Baseliner->model('Jobs')->is_in_active_job( $self->ns );
    if( ref $active_job ) {
        $self->why_not( _loc( "Package is in job %1 with status %2", $active_job->name, $active_job->status ) );
        return $self->_can_job(0);
    }

	# check if it's included in another release
	my $relid = $1 if $p{ns} =~ m/release\/(.*)/;
	my $relsearch = ($relid?{ns=>"changeman.package/".$self->ns_name,id_rel=>{ '<>' => $relid } }:{ns=>"changeman.package/".$self->ns_name }) ;
	my $rs = Baseliner->model('Baseliner::BaliReleaseItems')->search($relsearch);
	while ( my $r = $rs->next ) {
		$self->why_not( _loc "Item %1 already in release %2",$self->ns_name,$r->id_rel->name);
		return $self->_can_job( 0 );
	}

 	# check if it's pending to approve
	unless ( $bl ne 'PROD' || Baseliner->model('Request')->list (ns=>$self->ns, pending=>1)->{count} eq 0 ) {
		$self->why_not( _loc('Package %1 is pending to approve.', $self->ns_name) );
		# $self->why_not( 'Package is pending to approve.' );
		return $self->_can_job( 0 );
	}

	return $self->_can_job(1);
}

sub packageobjid {
    my $self = shift;
	return $self->ns_id;
	}

sub bl {
    my $self = shift;
    # _throw 'not implemented';
    #TODO get bl from Repository
    #my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid },);
    #return $pkg ? $self->map_bl( $self->application , $pkg->state->viewobjid->viewname ) : 'ERROR';  #TODO convert viewname or statename to bl
}

sub created_on {
    my $self = shift;
    _throw 'not implemented';
    #my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid },);
    #return $pkg->creationtime;
}

sub created_by {
    my $self = shift;
    _throw 'not implemented';
    #my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid }, { prefetch=>['modifier'] });
    #return $pkg ? $pkg->modifier->username : _loc 'Package not found';
}

sub transition {
	my ($self, $trans)= @_;
    _throw 'not implemented';
    #TODO merge or rollback PROD branch
	#_throw _loc( 'Error during %1: %2', $trans, $co->{msg} ) if $co->{rc};
	#return $co;
	}

sub viewpaths {
	my ($self, $level ) = @_;
    _throw 'not implemented';
	#TODO get log for tag
}

sub checkout { 
    my $self = shift;
    _throw 'not implemented';
	}

our %transition_cmd = ( promote=>'hpp', demote=>'hdp' );

sub promote {
	my $self = shift;
	$self->transition( 'promote', @_ );
	}

sub demote {
	my $self = shift;
	$self->transition( 'demote', @_ );
	}

sub nature {
	my $self = shift;
    return $self->{ns_data}->{linklist} eq 'SI'?'changeman.nature/changeman_batch_linklist':$self->{ns_data}->{db2} eq 'SI'?'changeman.nature/changeman_batch_db2':'changeman.nature/changeman_batch',
	}

sub approve { 
    my $self = shift;
    _throw 'not implemented';
	}
sub reject  { 
    my $self = shift;
    _throw 'not implemented';
	}
sub is_approved  { 
    my $self = shift;
    _throw 'not implemented';
	}
sub is_rejected  { 
    my $self = shift;
    _throw 'not implemented';
	}
sub user_can_approve  { 
    my $self = shift;
    _throw 'not implemented';
	}

sub find {
    my $self = shift;
    return $self;
	}

sub path {
    my $self = shift;
    my $pkg = $self->find;
    my $env = $pkg->envobjid;
    my $path = $self->compose_path($env->environmentname, $pkg->packagename);
	}

sub state {
    my $self = shift;
    my $state = $self->find->state;
    return $state->statename;
	}

sub project {
    my $self = shift;
    $self->{related}[0];
	}

sub application {
    my $self = shift;
    $self->{related}[0];
	}

sub rfc {
	my $self = shift;
    _throw 'not implemented';  
	# my $pkgname = $self->ns_name;
	# my $rfc = $pkgname;
	# $rfc =~ s{^.{5}(.*?)\@.*$}{$1}g;
	# return $rfc;
	}

sub get_row {
    my $self = shift;
	return Baseliner->model('Repository')->get( ns=>$self->ns );
}

our @parents;
sub parents {
    return @parents if scalar @parents;
    my $self = shift;
    my $pkg = $self->get_row;
    my $env = $pkg->envobjid->environmentname;
    #my $app = BaselinerX::CA::changeman::Project::get_apl_code( $env );
    #push @parents, "application/" . $app;
    #push @parents, "changeman.project/" . $env;
    #push @parents, "/";
    #return @parents;
}

sub job_options_global {
    my $self = shift;
    my @ret;
    push @ret, {id=>'chm_rf_ll', name=>_loc('Changeman Force LinkList Refresh')} if $self->{ns_data}->{linklist} eq 'SI';
    push @ret, {id=>'chm_rf_db2', name=>_loc('Changeman Force DB2 Refresh')} if $self->{ns_data}->{db2} eq 'SI';
    return \@ret;
}

sub job_options {

}

1;

