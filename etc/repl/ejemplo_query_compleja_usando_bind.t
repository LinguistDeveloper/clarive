 package My::Schema::User;

  use base qw/DBIx::Class/;

  # ->load_components, ->table, ->add_columns, etc.

  # Make a new ResultSource based on the User class
  my $source = __PACKAGE__->result_source_instance();
  my $new_source = $source->new( $source );
  $new_source->source_name( 'UserFriendsComplex' );

  # Hand in your query as a scalar reference
  # It will be added as a sub-select after FROM,
  # so pay attention to the surrounding brackets!
  $new_source->name( \<<SQL );
  ( SELECT u.* FROM user u 
  INNER JOIN user_friends f ON u.id = f.user_id 
  WHERE f.friend_user_id = ?
  UNION 
  SELECT u.* FROM user u 
  INNER JOIN user_friends f ON u.id = f.friend_user_id 
  WHERE f.user_id = ? )
  SQL 

  # Finally, register your new ResultSource with your Schema
  My::Schema->register_source( 'UserFriendsComplex' => $new_source );

__END__

