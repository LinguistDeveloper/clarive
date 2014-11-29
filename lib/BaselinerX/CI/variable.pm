package BaselinerX::CI::variable;
use Baseliner::Moose;
use Baseliner::Utils;

has var_type             => qw(is rw isa Str);
has var_ci_class         => qw(is rw isa Maybe[Str]);
has var_ci_role          => qw(is rw isa Maybe[Str]);
has var_ci_mandatory     => qw(is rw isa BoolCheckbox coerce 1);
has var_ci_multiple      => qw(is rw isa BoolCheckbox coerce 1);
has var_combo_options    => qw(is rw isa ArrayRef), default=>sub{ [] };
has var_default          => qw(is rw isa Any);
has old_name             => qw(is rw isa Str), default=>sub{my $self= shift; $self->name};

with 'Baseliner::Role::CI::Variable';

after save => sub {
    my ($self, $master_row, $data ) = @_;

    if ( $self->name ne $self->old_name ) {    
        $self->change_var_names();
        $self->old_name($self->name);
        $self->save;
    }
};

sub icon { '/static/images/icons/element_copy.png' }

sub has_bl { 0 }

sub default_hash {
    my ($class, $bl)=@_;
    $bl //= '*';
    my %vars;
    my @all = BaselinerX::CI::variable->search_cis;
    for my $var ( @all ) {
        next unless ! length($var->bl) || $var->bl eq '*' || $var->bl eq $bl;
        if( $var->var_type eq 'ci' ) {
            my $def = $var->var_default;
            $vars{ $var->name } = $def; #Baseliner::CI->new( $def ) if length $def;   
        } else {
            $vars{ $var->name } = $var->var_default;
        }
    } 
    \%vars;
}

sub change_var_names {
    my ($self) = @_;
    
    my @bls = map {$_->{bl}} ci->bl->find({},{bl=>1,_id=>0})->all;

    my @ors = map { +{"variables.".$_.".".$self->{old_name}=>{'$exists'=>1}} } @bls;

    my @prjs = ci->project->search_cis( '$or' => \@ors );

    for my $prj ( @prjs ) {
        my $changed=0;
        my $vars = $prj->{variables};
        for my $bl ( @bls ) {
            if ( $vars->{$bl}->{$self->{old_name}} ) {
                my $valor = $vars->{$bl}->{$self->{old_name}};
                $changed=1;
                $vars->{$bl}->{$self->{name}} = $valor;
                delete $vars->{$bl}->{$self->{old_name}};
            }
        }
        if ( $changed ) {
            $prj->variables( $vars );
            $prj->save;
        }
    }
}
1;

