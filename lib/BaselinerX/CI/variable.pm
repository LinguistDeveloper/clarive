package BaselinerX::CI::variable;
use Baseliner::Moose;
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Types;

has var_type             => qw(is rw isa Str);
has var_ci_class         => qw(is rw isa ArrayRef);
has var_ci_role          => qw(is rw isa Maybe[Str]);
has var_ci_mandatory     => qw(is rw isa BoolCheckbox coerce 1);
has var_ci_multiple      => qw(is rw isa BoolCheckbox coerce 1);
has var_combo_options    => qw(is rw isa ArrayRef), default=>sub{ [] };
has var_default          => qw(is rw isa Any);
has old_name             => qw(is rw isa Str lazy 1), default=>sub{my $self= shift; $self->name};

with 'Baseliner::Role::CI::VariableStash';

after save => sub {
    my ($self, $master_row, $data ) = @_;

    if ( $self->name ne $self->old_name ) {    
        $self->change_var_names();
        $self->change_var_names_in_rules() if config_get('config.rules')->{auto_rename_vars};
        $self->old_name($self->name);
        $self->save;
    }
};

sub icon { '/static/images/icons/element_copy.png' }

sub unique_keys {
    [
        ['name']
    ]
}
sub has_bl { 0 }

sub default_hash {
    my ($class, $bl)=@_;
    $bl //= '*';
    my %vars;
    my @all = BaselinerX::CI::variable->search_cis;
    for my $var ( @all ) {
        next unless ! length($var->bl) || $var->bl eq '*' || $var->bl eq $bl;
        my $variables = $var->variables;
        my $def = ref $variables 
            ? (exists $variables->{$bl} ? $variables->{$bl} : $variables->{'*'} ) 
            : $var->var_default;
        $vars{ $var->name } = $def; 
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

sub change_var_names_in_rules {
    my ($self) = @_;
    my $new_name = $self->{name};
    my $old_name = $self->{old_name};

    my @rules = mdb->rule->find()->all;

    for my $rule ( @rules ) {
        my $tree = $rule->{rule_tree};
        
        
        if ( $tree && $tree =~ /\{$old_name\}|\"$old_name\"|\'$old_name\'/  ) {
            $tree =~ s/\{$old_name\}/\{$new_name\}/g;
            $tree =~ s/\"$old_name\"/\"$new_name\"/g;
            $tree =~ s/\'$old_name\'/\'$new_name\'/g;
            _debug _log("Updating variable name from $old_name to $new_name in rule $rule->{id}");
            Baseliner::Controller::Rule->local_stmts_save( {username => 'clarive', id_rule => $rule->{id} , stmts => $tree, old_ts => $rule->{ts} }); 
        }
    }
}

sub is_ci {
    my ($self)=@_;
    return $self->var_ci_class || $self->var_ci_role;
}

1;

