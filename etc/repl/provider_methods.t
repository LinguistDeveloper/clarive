for( $c->model('Namespaces')->provider_instances({
    does => ['Baseliner::Role::Namespace::Package', 'Baseliner::Role::Namespace::Release']
}) ) {
    print join',', map { $_->name } $_->meta->get_all_methods;
 print "\n";
}
__END__
dump,DEMOLISHALL,find,meta,domain,get,does,new,list,namespace,DESTROY,BUILDALL,not_implemented,BUILDARGS,DOES
dump,DEMOLISHALL,find,meta,domain,get,does,new,list,namespace,DESTROY,BUILDALL,not_implemented,BUILDARGS,DOES
dump,DEMOLISHALL,find,meta,domain,get,does,new,list,namespace,DESTROY,BUILDALL,not_implemented,BUILDARGS,DOES
dump,DEMOLISHALL,find,meta,domain,get,does,new,list,namespace,DESTROY,BUILDALL,not_implemented,BUILDARGS,DOES


