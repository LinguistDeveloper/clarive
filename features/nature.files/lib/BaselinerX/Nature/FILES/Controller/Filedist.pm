package BaselinerX::Nature::FILES::Controller::Filedist;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::Filesys;
use BaselinerX::Session::ConfigState;
use BaselinerX::Nature::J2EE::Controller::Deploy;

BEGIN { extends 'Catalyst::Controller' }
use YAML;
use JavaScript::Dumper;

register 'action.nature.filedist.config' => { name=>'Config File Distribution' };
register 'menu.nature.filedist' => { label => 'Ficheros', url_comp => '/filedist', title=>'Ficheros', actions=>['action.nature.filedist.config']  };

sub filedist_json : Path('/filedist/json') {
    my ( $self, $c ) = @_;
    
		  my $p = $c->request->parameters;

		  my $tipo = ($p->{tipo}) ? $p->{tipo}: BaselinerX::Nature::FILES::Service::Filedist->TIPO_FICHEROS; 
		  
		BaselinerX::Nature::FILES::Controller::Filedist->parseStashData($c,$tipo);
		BaselinerX::Nature::FILES::Controller::SSHScript->parseStashData($c,$tipo);

		  my $query = $p->{query};
		  
    	  my ($ns,$bl) =  BaselinerX::Session::ConfigState->getConfigState($c,$tipo);
		
    	  my $filedist = undef;
		  if($tipo eq "J2EE"){
			$filedist = BaselinerX::Nature::FILES::Filedist->new( $ns, $bl, BaselinerX::Nature::J2EE::Service::Deploy->getTipoDistribuciones());		  
		  }else{
			$filedist = BaselinerX::Nature::FILES::Filedist->new( $ns, $bl, $tipo );
    	  }
		  $filedist->load($c,$query);
		  
          my @json_array = ();
          
          #for my $r (@{$filedist->{mappings}}){
          #	push @json_array, $r->{value};
          #}
                  
          $c->stash->{json} = { success=>\1, data => \@{$filedist->{mappings}}  };    
          $c->forward('View::JSON');
}

sub filedist_json_bl_ns: Path('/filedist/json_bl_ns'){
	    my ( $self, $c ) = @_;
	      my $p = $c->request->parameters;
          my $config = $c->registry->get( 'config.nature.filedist_comp' );
          my $datos = $config->factory($c,ns=>$p->{ns}, bl=>$p->{bl},default_data=>$p);
		  
		  my $tipo = ($p->{xtype}) ? $p->{xtype}: BaselinerX::Nature::FILES::Service::Filedist->TIPO_FICHEROS; 
          #Se guarda el estado de ns y bl obtenido mediante el request       
          BaselinerX::Session::ConfigState->setConfigState($c,$p->{ns},$p->{bl},$tipo);          

		  $self->filedist_json($c);		           
}

sub j2ee_filedist_json : Path('/j2ee/filedist/json') {
    my ( $self, $c ) = @_;
    	  my ($ns,$bl) =  BaselinerX::Session::ConfigState->getConfigState($c);
    	  my $filedist = BaselinerX::Nature::FILES::Filedist->new( $ns, $bl );
		  $filedist->load($c,{'src_dir'=>{'like','%/J2EE/%'}});
		  
          my @json_array = ();
          
          for my $r (@{$filedist->mappings}){
          	push @json_array, $r;
          }
          
          my $json_data = js_dumper (\@json_array);          
          $c->stash->{json} = { success=>\1, data => \@json_array  };    
          $c->forward('View::JSON');
}


sub filedist : Path('/filedist') {
    my ( $self, $c ) = @_;
    
    my $config = $c->registry->get( 'config.nature.filedist_comp' );	

    BaselinerX::Session::ConfigState->reset($c, BaselinerX::Nature::FILES::Service::Filedist->TIPO_FICHEROS);	
	
    $c->forward('list_packages');
	$c->forward('/baseline/load_baselines');	
 
    $c->stash->{metadata} = $config->metadata; ## lo utilizará el config_form.mas

	$self->parseStashData($c, BaselinerX::Nature::FILES::Service::Filedist->TIPO_FICHEROS);
	BaselinerX::Nature::FILES::Controller::SSHScript->parseStashData($c,BaselinerX::Nature::FILES::Service::Filedist->TIPO_FICHEROS);
		
    $c->stash->{template} = '/comp/filedist_comp.mas';
}

sub parseStashData{
    my ( $self, $c, $tipo ) = @_;	
    my $config = $c->registry->get( 'config.nature.filedist' );	
   
	my ($ns,$bl) =  BaselinerX::Session::ConfigState->getConfigState($c,$tipo);
    	  
	$c->stash->{url_filedist_store} = '/filedist/json?ns='. $ns . '&bl=' . $bl . "&tipo=" . $tipo;
    $c->stash->{url_filedist_submit} = '/filedist/submit?filedist_type=' . $tipo;
    $c->stash->{url_filedist_delete} = '/filedist/delete';
    
    $c->stash->{title} = _loc('Distribucion Ficheros');

    $c->stash->{metadata_filedist} = $config->metadata; ## lo utilizará el config_form.mas
    
}

sub filedist_json_filter : Path('/filedist/json_filter') {
    my ( $self, $c ) = @_;

}

sub filedist_submit : Path('/filedist/submit') {
          my ($self,$c)=@_;
          my $p = $c->req->params;
		  my $tipo = $p->{filedist_type};
 	  
		  my ($ns,$bl) =  BaselinerX::Session::ConfigState->getConfigState($c,$tipo);
    	  my $filedist = BaselinerX::Nature::FILES::Filedist->new( $ns, $bl );

          $filedist->save($c,
          {	
          	id=>$p->{id},
          	ns=>$ns,
          	bl=>$bl, 
          	filter=>$p->{filter},
          	exclussions=>$p->{exclussions},
          	isrecursive=>$p->{isrecursive},
          	src_dir=>$p->{src_dir},
          	dest_dir=>$p->{dest_dir},
          	ssh_host=>$p->{ssh_host},
          	xtype=>$p->{xtype},
			sys=>$p->{sys},
          });
          
          $c->stash->{json} = { success=>\1 };    
          $c->forward('View::JSON');          
}

sub filedist_delete : Path('/filedist/delete') {
          my ($self,$c)=@_;
          my $p = $c->req->params;
  		  my $tipo = $p->{tipo} || $p->{xtype} || BaselinerX::Nature::FILES::Service::Filedist->TIPO_FICHEROS; 
    	  my ($ns,$bl) =  BaselinerX::Session::ConfigState->getConfigState($c,$tipo);
    	  my $filedist = BaselinerX::Nature::FILES::Filedist->new( $ns, $bl );
          my $id = $p->{id};
         
          $filedist->delete($c,$id);
          $c->stash->{json} = { success=>\1 };    
          $c->forward('View::JSON');            
}

sub parseValue{
	my ($val,$default) = @_;
	return ($val eq undef)?$default:$val;	
}

sub list_packages : Path('/filedist/list_packages') {
    my ( $self, $c ) = @_;
    my @NS;
    $c->stash->{ns_query} = {
		states => ['Desarrollo', 'Desarrollo Integrado'],	
		username => $c->username,
		nature => 'FILES',
		does=>[
			'Baseliner::Role::Namespace::Application',
			'Baseliner::Role::Namespace::Subapplication', ]
	};
    $c->forward('/namespace/load_namespaces');
}

1;
