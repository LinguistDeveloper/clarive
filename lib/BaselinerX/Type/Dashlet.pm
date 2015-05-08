package BaselinerX::Type::Dashlet;
use Baseliner::PlugMouse;
use Baseliner::Utils;
with 'Baseliner::Role::Registrable';
with 'Baseliner::Role::Palette';

register_class 'dashlet' => __PACKAGE__;
sub service_noun { 'dashlet' }

has name  => (is=>'rw', isa=>'Str', default=>'');
has form  => (is=>'rw', isa=>'Str', default=>'');
has html  => (is=>'rw', isa=>'Str', default=>'');
has js_file  => (is=>'rw', isa=>'Str', default=>'');
has id => (is=>'rw', isa=>'Str', default=>'');

has dsl            => ( is => 'rw', isa => 'CodeRef', default=>sub{
	return sub{
	    my ($self, $n, %p ) = @_;
	    sprintf(q{
            my $config = parse_vars %s, $stash;
	        push @{ $stash->{dashlets} }, $config; 
	    }, Data::Dumper::Dumper({ key=>$n->{key}, html=>$n->{html}, title=>$n->{text}, name=>$n->{name}, data=>$n->{data} }));
	};
});

1;


