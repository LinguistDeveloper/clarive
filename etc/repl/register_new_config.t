    my $id      = 'key';
    my $default = 'value';  
    my $table   = 'BaliConfig';
    my $config  = 'bali';
    my $rs =
        Baseliner->model("Baseliner::$table")
        ->search( undef, { select => [ $id, $default ], as => [qw/ id default /], order_by => { -asc => 'id' } } );

    rs_hashref($rs);

    my @metadata = $rs->all;

    register "config.$config" => { metadata => [ @metadata ] };
__END__
--- &1 !!perl/hash:Baseliner::Core::RegistryNode 
id: bali
init_rc: 5
key: config.bali
module: Baseliner::Controller::REPL
param: 
  id: bali
  key: config.bali
  metadata: 
    - 
      default: /home/aps/scm/servidor/tmp
      id: PERLTEMP
    - 
      default: prue
      id: LDIFMAQ
  module: Baseliner::Controller::REPL
  registry_node: *1
  short_name: bali
version: '1.0'

