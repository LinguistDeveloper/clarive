package Baseliner::Controller::Chain;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
use DateTime;
use Carp;
use Baseliner::Sugar;
use v5.10;

BEGIN { extends 'Catalyst::Controller' }

#register 'menu.admin.chain' => { label => ' Chains' };

register 'menu.admin.chain' => { label    => 'Job Chains',
                                 url_comp => '/chain/grid',
                                 title    => 'Chains',
                                 icon     => '/static/images/icons/chain.gif' };

# register 'menu.admin.features.install' => { label    => 'Install Features',
#                                             url_comp => '/feature/install',
#                                             title    => 'Install' };


sub list : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my ( $start, $limit, $query, $dir, $sort, $cnt ) = @{$p}{qw/start limit query dir sort/,0};
    my $where = {};
    $sort ||= 'id';
    $limit ||= 50;
    $query and $where = { 'lower(name||job_type||description)' => { -like => "%".lc($query)."%" } };
    my $page = to_pages( start => $start, limit => $limit );
    my $rs = $c->model('Baseliner::BaliChain')->search( $where, { order_by=>"$sort $dir", page=>$page, rows=>$limit });
    rs_hashref($rs);
    my $pager = $rs->pager;
    $cnt = $pager->total_entries;	
    my @rows = $rs->all;
    $c->stash->{json} = { totalCount=>$cnt, data=>\@rows };
    $c->forward('View::JSON');
}

sub edit : Local {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	$c->stash->{id_chain} = $p->{id};
	$c->stash->{template} = '/comp/chain_edit.mas';
}

# Added by Eric (q74613x) @ [may 24, 2011 12:53]
sub edit_test : Local {
  my ( $self, $c ) = @_;
  my $p = $c->request->parameters;

  $c->stash->{id_chain} = $p->{id};
  $c->stash->{template} = '/comp/grid-filter.js'; }

# Added by Eric (q74613x) @ [may 24, 2011 15:04]
sub data_grid_filter : Local {
  my ( $self, $c ) = @_;
  my $params   = $c->request->parameters();
  my $show_all = $params->{show_all};
  my $chain_id = $params->{chain_id};

  # Builds requisites...
  my $where = ( $show_all == 1 )
            ? { chain_id => $chain_id }
            : { chain_id => $chain_id,
                active   => 1 };

  # Gets data from schema...
  my $rs = $c->model('Baseliner::BaliChainedRule')->search;
  rs_hashref( $rs ); 
  my @data = $rs->all( $where );

  $c->stash->{json} = { data => \@data };
  $c->forward('View::JSON') }

# Added by Eric (q74613x) @ [may 25, 2011 11:48]
sub view_dsl : Local {
  # Shows a textarea with the current DSL for a given filter.
  my ( $self, $c ) = @_;
  my $p = $c->request->parameters;
  my $id = $p->{id};
  my $active = $p->{id};

  # Get data from schema...
  my $rs = Baseliner->model('Baseliner::BaliChainedRule')
             ->search( { id => $id },
                       { select => ['dsl',
                                    'dsl_code'],
                         as     => ['dsl',
                                    'code'] } );
  rs_hashref($rs);
  my $row  = $rs->next;
  my $dsl  = $row->{dsl};
  my $code = $row->{code};

  # Fix some stuff...
  $dsl  =~ s/'/\\'/gx;      # Quotation marks...
  $code =~ s/'/\\'/gx;      # ...
  $code =~ s/\n//gx;        # Delete existing neutral return characters...
  $code =~ s/\r/\\n/gx;     # Force SQL return characters to neutral...

  # Send back...
  $c->stash->{id}       = $id;
  $c->stash->{active}   = $active;
  $c->stash->{dsl}      = "'$dsl'";      # Force string...
  $c->stash->{code}     = "'$code'";     # Force string...
  $c->stash->{template} = '/comp/dsl.js' }

# Added by Eric (q74613x) @ [may 25, 2011 15:58]
# This stuff should go in a model but oh well...
sub save_dsl : Local {
  # Saves content of textarea into the database.
  my ( $self, $c ) = @_;
  my $args = $c->request->parameters;
  my $code = $self->filter_dsl( $args->{dsl_code} );
  my $id   = $args->{id};

  # Update...
  my $rs = Baseliner->model('Baseliner::BaliChainedRule')
             ->search( { id => $id } );
  $rs->update( { dsl_code => $code } );

  return }

# Added by Eric (q74613x) @ [jun 01, 2011 12:39]
sub filter_dsl : Local {
  my ( $self, $code ) = @_;
  my @forbidden_words = ('die',
                         '_throw',
                         'return',
                         );
  $code =~ s/\n/\r/gx;                           # Force neutral return character
  $code =~ s/print\s(.+);/\$log->debug($1);/gx;  # Turn print into log
  for my $word (@forbidden_words) { $code =~ s/$word\s(.+);//gx }
  $code }

# Added by Eric (q74613x) @ [may 25, 2011 17:28]
sub delete_row : Local {
  # Deletes selected row in BaliChainedRule.
  my ( $self, $c ) = @_;
  my $params = $c->request->parameters;
  my $id     = $params->{id};

  # Delete row...
  my $rs = Baseliner->model('Baseliner::BaliChainedRule')
             ->search( { id => $id } );
  $rs->delete;

  return }

# Added by Eric (q74613x) @ [26 may, 2011 10:45]
sub modify_active : Local {
  # Modifies active column for a given chain.
  my ( $self, $c ) = @_;
  my $p     = $c->request->parameters;
  my $id    = $p->{id};
  my $value = $p->{value};

  # Update active...
  my $rs = Baseliner->model('Baseliner::BaliChainedRule')
             ->search( { id => $id } );
  $rs->update( { active => $value } );

  # Explicit return...
  return; }

sub grid : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = '/comp/chain_grid.js';
}

sub detail : Local {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = @{$p}{qw/start limit query dir sort/};
	my @order_by;
	if( $sort ) {
 		@order_by = ("$sort $dir");
		$sort ne 'seq' && push( @order_by, 'seq');
	} else {
 		@order_by = qw/step seq /;
	}
	my @rows;
	my $rs = $c->model('Baseliner::BaliChainedService')->search({},{ order_by=>\@order_by }) ;
	$rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
	while( my $r = $rs->next ) {
		warn _dump $r;
		push @rows, $r;
	}
	$c->stash->{json} = {
		totalCount=>scalar @rows,
		data=>\@rows
	};
	$c->forward('View::JSON');
}

sub delete : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try {
        my $chain = Baseliner->model('Baseliner::BaliChain')->find( $p->{id} );
        $chain->delete;
        $chain->update;
		$c->stash->{json} = { success => \1, msg => _loc("Chain '%1' deleted", $p->{name} ) };
    } catch {
		$c->stash->{json} = { success => \0, msg => _loc("Error deleting the chain '%1': %2", $p->{name}, shift) };
    };
	$c->forward('View::JSON');
}

sub create : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try {
        Baseliner->model('Baseliner::BaliChain')->search({ name=>$p->{name} })->first 
            and _loc("name '%1' already in use", $p->{name} );

        $p->{active} = $p->{active} eq 'true' ? 1 : 0;
        my $chain = Baseliner->model('Baseliner::BaliChain')->create( $p );
		$c->stash->{json} = { success => \1, msg => _loc("Chain '%1' created", $p->{name} ) };
    } catch {
		$c->stash->{json} = { success => \0, msg => _loc("Error creating the chain '%1': %2", $p->{name}, shift) };
    };
	$c->forward('View::JSON');
}

sub add : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'comp/chain_edit.mas';
}

#***********************************************************************************************************************
#METODOS NUEVOS
#***********************************************************************************************************************
sub change_active : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $id = $p->{id};
    my $action = $p->{action};
    my $msg_active = $action eq 'start' ? 'started' : 'stopped';
    
    my $chain = Baseliner->model('Baseliner::BaliChain')->find( $id );
    if( ref $chain ) {
	$chain->active( $action eq 'start' ? 1 : 0 );
	$chain->update;
	$c->stash->{json} = { success => \1, msg => _loc("Chain $msg_active") };
    }
    else{
	
	$c->stash->{json} = { success => \0, msg => _loc('Error modifying the chain') };
    }
    $c->forward('View::JSON');
}


sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $action = $p->{opt};

    given ($action) {
        when ('add') {
            try{
                my $chain = $c->model('Baseliner::BaliChain')->create(
                                {
                                name	=> $p->{name},
                                description => $p->{description},
                                job_type => $p->{job_type},
                                active 	=> $p->{state},
                                action => $p->{action}
                                });
                
                $c->stash->{json} = { msg=>_loc('Chain added'), success=>\1, chain_id=> $chain->id };
    
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error adding Chain: %1', shift()), failure=>\1 }
            };
        }
        when ('update') {
            try{
                my $id_chain = $p->{id};
                my $chain = $c->model('Baseliner::BaliChain')->find( $id_chain );
                $chain->name( $p->{name} );
                $chain->description( $p->{description} );
                $chain->job_type( $p->{job_type} );
                $chain->active( $p->{state});
                $chain->action( $p->{action});
            
            
                $chain->update();
                $c->stash->{json} = { msg=>_loc('Chain modified'), success=>\1, chain_id=> $id_chain };
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error modifying Chain: %1', shift()), failure=>\1 };
            };
        }
        when ('delete') {
            my $id_chain = $p->{id};
            
            try{
                my $row = $c->model('Baseliner::BaliChain')->find( $id_chain );
                $row->delete;
            
                $c->stash->{json} = { success => \1, msg=>_loc('Chain deleted') };
            }
            catch{
                $c->stash->{json} = { success => \0, msg=>_loc('Error deleting Chain') };
            };
        }
    }
    
    $c->forward('View::JSON');
}

sub update_service : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $action = $p->{action};
    my $service;
    my $seq;

    given ($action) {
	when ('add') {
	    try{
		$service = $c->model('Baseliner::BaliChainedService')->search({chain_id => $p->{id_chain}, step => $p->{step}},
									      {order_by=> 'seq desc'})->first;
		if(ref $service){
		    $seq = $service -> seq + 1;
		}else{
		    $seq = 1
		}
		    
	        $service = $c->model('Baseliner::BaliChainedService')->create(
						    {
							key	=> $p->{service},
							chain_id => $p->{id_chain},
							description => $p->{description},
							seq => $seq,
							step => $p->{step},
							active 	=> $p->{state},
							data => $p->{txt_conf} ? $p->{txt_conf}: undef
						    });
		    
		$c->stash->{json} = { msg=>_loc('Service added'), success=>\1, service_id=> $service->id };

	    }
	    catch{
		$c->stash->{json} = { msg=>_loc('Error adding Service: %1', shift()), failure=>\1 }
	    }
	}
	when ('update') {
	    try{
		my $id = $p->{id};
		my $service = $c->model('Baseliner::BaliChainedService')->find( $id );
		$service->description( $p->{description} );
		$service->step( $p->{step} );
		$service->active( $p->{state} );
		
		$service->update();
		$c->stash->{json} = { msg=>_loc('Service modified'), success=>\1, service_id=> $service->id };
	    }
	    catch{
		$c->stash->{json} = { msg=>_loc('Error modifying Service: %1', shift()), failure=>\1 };
	    }
	}
	when ('delete') {
	    my $id_chain = $p->{id};
	    try{
		my $row = $c->model('Baseliner::BaliChain')->find( $id_chain );
		$row->delete;
	
		$c->stash->{json} = { success => \1, msg=>_loc('Chain deleted') };
	    }
	    catch{
		$c->stash->{json} = { success => \0, msg=>_loc('Error deleting Chain') };
	    }
	}
    }
    
    $c->forward('View::JSON');
}

sub list_services : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my ( $start, $limit, $id_chain, $step, $query, $dir, $sort, $cnt ) = @{$p}{qw/start limit id_chain step query dir sort/,0};
    my $where = {};
    $sort ||= 'id';
    $limit ||= 50;
    
    my $where = $query
        ? { 'lower(key||step||description)' => { -like => "%".lc($query)."%" }, chain_id => $id_chain }
        : $step ? { chain_id => $id_chain, step => $step }: { chain_id => $id_chain } ;       
    my $page = to_pages( start => $start, limit => $limit );
    my $rs = $c->model('Baseliner::BaliChainedService')->search( $where, { order_by=>"$sort $dir", page=>$page, rows=>$limit });
    rs_hashref($rs);
    my $pager = $rs->pager;
    $cnt = $pager->total_entries;	
    my @rows = $rs->all;
    $c->stash->{json} = { totalCount=>$cnt, rows=>\@rows };
    $c->forward('View::JSON');
}

sub getconfig : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $id = $p->{id};
    my $txtconfig;
    my $config_key = try { $c->model('Registry')->get( $id )->{registry_node}->{param}->{config} };
    if( $config_key ) {
	$txtconfig = config_get( $config_key );
    } else {
	$txtconfig = undef ;
    };
     
    $c->stash->{json} = { success => \1, msg => _loc("Chain txtconfig"), yaml => $txtconfig?_dump($txtconfig):undef };
    $c->forward('View::JSON');
}

sub update_conf : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $id = $p->{id};
    my $conf = $p->{conf};
    
    my $service = Baseliner->model('Baseliner::BaliChainedService')->find( $id );
    if( ref $service ) {
	$service->data( $p->{conf} );
	$service->update;
	$c->stash->{json} = { success => \1, msg => _loc("Configuration changed") };
    }
    else{
	$c->stash->{json} = { success => \0, msg => _loc('Error changing the configuration') };
    }
    $c->forward('View::JSON');
}

sub update_sequence : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $sequence_services = $p->{sequence_services};
    my $seq = 1;
    
    foreach my $sequence_service (_array $sequence_services){
	my $service = Baseliner->model('Baseliner::BaliChainedService')->find( $sequence_service );
	if( ref $service ) {
	    $service->seq( $seq );
	    $service->update;
	}
	$seq ++
    }
    $c->stash->{json} = { msg=>_loc('Sequence changed'), success=>\1 };
   
    $c->forward('View::JSON');
}
1;
