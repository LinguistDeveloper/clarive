package Baseliner::Controller::Chain;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
use DateTime;
use Carp;

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
    my ( $start, $limit, $query, $dir, $sort, $cnt ) =
      @{$p}{qw/start limit query dir sort/};
    my $where = {};
    $sort ||= 'id';
    $limit ||= 50;
    $query and $where = { 'lower(name||job_type||description)' => { -like => "%$query%" } };
    my $page = to_pages( start => $start, limit => $limit );
	my $rs = $c->model('Baseliner::BaliChain')->search( $where, { order_by=>"$sort $dir", page=>$page, rows=>$limit });
    rs_hashref($rs);
    my @rows = $rs->all;
	$c->stash->{json} = { totalCount=>scalar @rows, data=>\@rows };
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
  use BaselinerX::Ktecho::Utils;
  my @data = table_data('Baseliner::BaliChainedRule', 
                        $where);

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
	$c->stash->{template} = '/comp/chain_grid.mas';
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

1;
