       [ Baseliner->model('Registry')->search_for(
            key             => 'portlet.',

        )
]
__END__
--- 
- &1 !!perl/hash:BaselinerX::Type::Portlet 
  id: monitor
  key: portlet.monitor
  module: BaselinerX::Job
  name: Job Monitor
  registry_node: &2 !!perl/hash:Baseliner::Core::RegistryNode 
    id: monitor
    init_rc: 5
    instance: *1
    key: portlet.monitor
    module: BaselinerX::Job
    param: 
      id: monitor
      key: portlet.monitor
      module: BaselinerX::Job
      name: Job Monitor
      registry_node: *2
      short_name: monitor
      url: /job/monitor_portlet
      url_max: /job/monitor
    version: 1.0
  url: /job/monitor_portlet
  url_max: /job/monitor
  version: 0.1

