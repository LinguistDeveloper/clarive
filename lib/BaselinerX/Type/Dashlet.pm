package BaselinerX::Type::Dashlet;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
with 'Baseliner::Role::Registrable';
with 'Baseliner::Role::Palette';

register_class 'dashlet' => __PACKAGE__;
sub service_noun { 'dashlet' }

has name  => (is=>'rw', isa=>'Str', default=>'');
has form  => (is=>'rw', isa=>'Str', default=>'');
has html  => (is=>'rw', isa=>'Str', default=>'');
has js_file  => (is=>'rw', isa=>'Str', default=>'');
has no_boot  => ( is => 'rw', isa => 'Bool', default => 0);
has id => (is=>'rw', isa=>'Str', default=>'');

has dsl            => ( is => 'rw', isa => 'CodeRef', default=>sub{
	return sub{
	    my ($self, $n, %p ) = @_;
	    sprintf(q{
            my $config = parse_vars %s, $stash;
            my $name = $config->{title} || $config->{name};
            my $id_field = Util->_name_to_id( $name );
            if( $stash->{rule_context} eq 'form' ) {
                push @{ $stash->{fieldlets} }, {
                    section=>'between',
                    %%{$config},
                    type => 'generic',
                    id_field => $id_field,
                    bd_field => $id_field,
                    name => $name,
                    name_field => $name,
                    section_allowed => ['between']
                };
            } else {
                push @{ $stash->{dashlets} }, $config; 
            }
	    }, Data::Dumper::Dumper({ id=>$n->{id}, key=>$n->{key}, html=>$n->{html}, title=>$n->{text}, name=>$n->{name}, data=>$n->{data} }));
	};
});

no Moose;
__PACKAGE__->meta->make_immutable;

1;


