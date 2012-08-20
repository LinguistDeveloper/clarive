package BaselinerX::Nature::FILES::SSHScript;
use strict;
use Carp;
use File::Find;
use Error qw(:try);

use constant TIPO_PRE => "PRE";
use constant TIPO_POST => "POST";

sub new {
    my ($class, $ns, $bl) = @_;
    my @scripts = ();

    my $self = {
        ns => $ns,
        bl  => $bl,
        #parentId => $parentId,
    };
    bless( $self, $class );
}

sub load {
	my ($self,$c,$ns,$bl) = @_;
	 
	my $rs = $c->model('Baseliner::BaliSshScript')->search({ ns=>$self->{ns}, bl=>$self->{bl} });
	while(my $r = $rs->next){
		push @{$self->{scripts}}, $r;
	}
}

# sub loadByFileDist {
	# my $self = shift();
	# my $c = shift();

	# my $rs = $c->model('Baseliner::BaliFileDist')->search({ id=>$self->{parentId} });
	# if(my $r = $rs->next){
		# $self->{bl} = $r->bl; 
		# $self->{ns} = $r->ns; 
	# }
	 
	# $rs = $c->model('Baseliner::BaliScriptsInFileDist')->search({ file_dist_id=>$self->{parentId} });
	# while(my $r = $rs->next){
		# push @{$self->{scripts}}, $r->script_id;
	# }
# }

# sub getFromFileDistId {
	# my $self = shift();
	# my $c = shift();
	# my $id = shift();
	# my @scripts = ();
	 
	# my $rs = $c->model('Baseliner::BaliScriptsInFileDist')->search({file_dist_id=>$id });
	# while(my $r = $rs->next){
		# push @scripts, {$r->script_id->get_columns};
	# }
	# return @scripts;
# }

sub getFromNamespace {
	my $self = shift();
	my $c = shift();
	my $ns = shift();
	my $bl = shift();
	my $tipo = shift();
	my $subtipo = shift();
	my @scripts = ();
	 
	# my $rs = $c->model('Baseliner::BaliSshScript')->search({ ns=>$ns, bl=>$bl, type=>$tipo });
	# No devuelve NS = '/' ni BL = '*'
	
	my $rs = (not ref($subtipo))? 
					$c->model('Baseliner::BaliSshScript')->search({ ns=>{ 'in' => [ "/", "$ns" ] }, bl=> { 'in' => [ "*", "$bl" ] }, type=>$tipo })
					:$c->model('Baseliner::BaliSshScript')->search({ ns=>{ 'in' => [ "/", "$ns" ] }, bl=> { 'in' => [ "*", "$bl" ] }, type=>$tipo, xtype=>{'in' => [ "*", "$subtipo" ] } });

	while(my $r = $rs->next){
		push @scripts, {$r->get_columns};
	}
	return @scripts;
}

sub save{
	my $self = shift();
	my $c = shift();
	my $script = shift();	
			
	my $rs = $c->model('Baseliner::BaliSshScript')->search({id=>$script->{id} });	
			
	if (my $r = $rs->next){
		$r->set_columns($script);
		$r->update;
	}else{	
		my $r = $c->model('Baseliner::BaliSshScript')->create($script);				
		$r->update;
		
		# my $rs = $c->model('Baseliner::BaliSshScript')->search(
			# {
				# bl=>$script->{bl}, 
				# ns=>$script->{ns},
				
		# },{order_by=>'id desc'});	
		
		# my $id = 0;			
		# $id = $r->id if($r = $rs->next);		
		
		# $r = $c->model('Baseliner::BaliScriptsInFileDist')->create(
			# {
				# id => 0,
				# file_dist_id => $self->{parentId},
				# script_id=>$id
				
			# }
		# );				
		# $r->update;
		
	}
		
}

sub delete {
	my $self = shift();
	my $c = shift();
	my $id = shift();

	#$c->model('Baseliner::BaliScriptsInFileDist')->search({script_id=>$id })->delete;
	$c->model('Baseliner::BaliSshScript')->search({id=>$id })->delete;	
}

# sub deleteByFileDist {
	# my $self = shift();
	# my $c = shift();
	# my $fid = shift();
	# my @scriptsId = ();

	# my $rs = $c->model('Baseliner::BaliScriptsInFileDist')->search({file_dist_id=>$fid });	
	# while(my $r = $rs->next){
		# my $scriptId = $r->script_id->id;
		# $r->delete;		
		# $c->model('Baseliner::BaliSshScript')->search({id=>$scriptId })->delete;
	# }

		
# }


1;
