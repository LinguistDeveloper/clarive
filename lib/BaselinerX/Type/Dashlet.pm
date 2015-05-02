package BaselinerX::Type::Dashlet;
use Baseliner::PlugMouse;
with 'Baseliner::Role::Registrable';
with 'Baseliner::Role::Palette';

register_class 'dashlet' => __PACKAGE__;
sub service_noun { 'dashlet' }

has name  => (is=>'rw', isa=>'Str', default=>'');
has form  => (is=>'rw', isa=>'Str', default=>'');
has html  => (is=>'rw', isa=>'Str', default=>'');
has js_file  => (is=>'rw', isa=>'Str', default=>'');

has dsl            => ( is => 'rw', isa => 'CodeRef', default=>sub{
	return sub{
	    my ($self, $n, %p ) = @_;
	    sprintf(q{
	        push @{ $stash->{dashlets} }, %s; 
	    }, Data::Dumper::Dumper({ form=>$self->{form}, key=>$n->{key}, html=>$n->{html}, name=>$n->{name}, data=>$n->{data} }));
	};
});

1;


