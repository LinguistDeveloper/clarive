package TestFactory;
use strict;
use warnings;
use Class::Load;
use JSON ();

sub create_status_ci {
    my $class = shift;
    my (%params) = @_;
    if ( $class->_has_trait( \%params, 'new' ) )   { $params{name} //= 'New';    $params{type} //= 'I'; }
    if ( $class->_has_trait( \%params, 'final' ) ) { $params{name} //= 'Closed'; $params{type} //= 'F'; }
    $params{name} //= 'In Progress';
    $params{type} //= 'G';
    return $class->_create_ci( 'status', %params );
}

sub create_user_ci {
    my $class = shift;
    my (%params) = @_;
    if ( !$params{project_security} && $class->_has_with( \%params, 'project_security' ) ) {
        my $role     = $class->create_role_doc;
        my $projects = $params{projects};
        $projects = ref $projects eq 'ARRAY' ? $projects : [$projects];
        $params{project_security} = { $role->{id} => { project => [ map { $_->mid } @$projects ] } };
    }
    my $username = delete $params{username} // 'Developer';
    my $password = delete $params{password} // 'password';
    return $class->_create_ci(
        'user',
        name     => $username,
        username => $username,
        password => ci->user->encrypt_password( $username, $password ),
        %params
    );
}

sub create_topic_doc {
    my $class = shift;
    my (%params) = @_;
    if ( !$params{rule} && $self->_has_with( \%params, 'rule' ) ) {
        $params{rule} = { _traits => [ 'form', 'status_field', 'assigned_field' ] };
    }
    if ( my $rule = delete $params{rule} ) { $params{id_rule} = $class->create_rule_doc($rule); }
    if ( !$params{status} && $self->_has_with( \%params, 'status' ) ) {
        $params{status} = { _traits => [ 'form', 'status_field', 'assigned_field' ] };
    }
    my $id_form = delete $params{form} || delete $params{id_rule} || TestSetup->create_rule_form;
    my $status = delete $params{status} || TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_category = delete $params{id_category}
      || TestSetup->create_category( id_rule => $id_form, name => 'Category', id_status => $status->mid );
    my $project = delete $params{project} || TestUtils->create_ci_project;
    my $base_params = {
        'project' => ref $project eq 'ARRAY' ? [ map { $_->mid } @$project ] : $project->mid,
        'category'           => $id_category,
        'status_new'         => $status->mid,
        'status'             => $status->mid,
        'id_rule'            => $id_form,
        'category_status'    => { id => $status->mid },
        'id_category_status' => $status->mid,
    };
    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update(
        { %$base_params, action => 'add', title => 'New Topic', username => 'developer', %params } );
    return mdb->topic->find_one( { mid => "$topic_mid" } );
}

sub create_project_ci {
    my $class = shift;
    my (%params) = @_;
    return $class->_create_ci( 'project', name => 'Project', %params );
}

sub create_category_doc {
    my $class = shift;
    my (%params) = @_;
    if ( !$params{rule} && $class->_has_with( \%params, 'rule' ) ) { $params{rule} = { _traits => 'topic' }; }
    my $rule = $params{rule} ? $class->create_rule( $params{rule} ) : undef;
    if ( !$params{statuses} && $class->_has_with( \%params, 'statuses' ) ) {
        push @{ $params{statuses} }, { _traits => 'new' };
        push @{ $params{statuses} }, { _traits => 'final' };
        push @{ $params{statuses} }, {};
    }
    my $statuses = [];
    foreach my $status ( @{ $params{statuses} } ) { push @$statuses, $class->create_status(%$status); }
    my $id_cat = mdb->seq('category');
    mdb->category->insert(
        {
            id       => "$id_cat",
            name     => 'Category',
            statuses => map { $_->mid } @$statuses,
            $rule ? ( default_form => $rule->id ) : (), %params
        }
    );
    return "$id_cat";
}

sub create_rule_doc {
    my $class = shift;
    my (%params) = @_;
    $params{rule_tree} //= [];
    if ( $class->_has_trait( \%params, 'form' ) ) { $params{rule_type} //= 'form'; }
    if ( $class->_has_trait( \%params, 'status_field' ) ) {
        push @{ $params{rule_tree} },
          {
            "attributes" => {
                "data" => {
                    "bd_field"     => "id_category_status",
                    "fieldletType" => "fieldlet.system.status_new",
                    "id_field"     => "status_new",
                },
                "key" => "fieldlet.system.status_new",
            }
          };
    }
    if ( $class->_has_trait( \%params, 'assigned_field' ) ) {
        push @{ $params{rule_tree} },
          { "attributes" =>
              { "data" => { id_field => 'assigned', }, "key" => "fieldlet.system.users", name => 'Assigned', } };
    }
    $params{rule_tree} = JSON::encode_json( $params{rule_tree} );
    my $id_rule  = mdb->seq('rule');
    my $seq_rule = 0 + mdb->seq('rule_seq');
    mdb->rule->insert( { id => "$id_rule", rule_active => 1, rule_name => 'Rule', rule_seq => $seq_rule, %params, } );
    return mdb->rule->find_one( { id => "$id_rule" } );
}

sub create_role_doc {
    my $class    = shift;
    my (%params) = @_;
    my $id_role  = mdb->seq('role');
    mdb->role->insert( { id => "$id_role", actions => [], role => 'Role', %params } );
    return mdb->role->find_one( { id => "$id_role" } );
}
sub _has_trait { my $class = shift; my ( $params, $what ) = @_; return $class->_has( '_traits', $params, $what ); }
sub _has_with  { my $class = shift; my ( $params, $what ) = @_; return $class->_has( '_with',   $params, $what ); }

sub _has {
    my $class = shift;
    my ( $type, $params, $what ) = @_;
    my $where = $params->{$type};
    return unless $where;
    $where = [$where] unless ref $where eq 'ARRAY';
    my @matches = grep { $_ eq $what } @$where;
    return @matches ? 1 : 0;
}

sub _create_ci {
    my $class = shift;
    my ( $name, %params ) = @_;
    my $ci_class = 'BaselinerX::CI::' . $name;
    Class::Load::load_class($ci_class);
    my $ci = $ci_class->new(%params);
    $ci->save;
    return $ci;
}
1;
