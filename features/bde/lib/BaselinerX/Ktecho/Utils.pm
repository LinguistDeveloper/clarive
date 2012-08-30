package BaselinerX::Ktecho::Utils;
use List::Util 'reduce';
use Exporter::Tidy default => [ qw{ _biztalk_type
                                    new_log
                                    new_log_form
                                    t
                                    nil
                                    sum
                                    concat
                                    to_html
                                    date
                                    fix_year
                                    is_in
                                    grant_role } ];


sub get_role {
  my $role  = shift;
  my $where = {role => uc($role)};
  my $args  = {select => 'id'};
  my $rs    = Baseliner->model('Baseliner::BaliRole')->search($where, $args);
  rs_hashref($rs);
  $rs->first->{id};
}

sub get_cam {
  my $cam   = shift;
  my $where = {name => $cam, id_parent => undef};
  my $args  = {select => 'id'};
  my $rs = Baseliner->model('Baseliner::BaliProject')->search($where, $args);
  rs_hashref($rs);
  $rs->first->{id};
}

sub grant_role {
  my %p = @_;
  my $args = {
    username => $p->{user},
    id_role  => get_role($p->{role}),
    ns       => get_cam($p->{project})
  };
  Baseliner->model('Baseliner::BaliRoleuser')->create($args);
}

=head1 grant_role

Grants permissions to an user.

=head2 Usage

  grant_role(user => 'q74613x', role => 'PR', project => 'SCT')

=cut                                    


# Gets the value of a biztalk type and returns its real value to be used on
# the database according to the configuration file:
sub _biztalk_type {
  my $value    = shift;

  my $biz_type = Baseliner->model('ConfigStore')->get('config.biztalk.tipo');
  my %reverse_biz_type = reverse %{$biz_type};

  return $reverse_biz_type{$value} }


# Kludge, avoid!
sub new_log {
  my $title     = uc(shift) . "\n";
  my $init_date = date();
  my $line;
  for ( 1 .. length( ( $init_date x 2 ) . $title . (" - ") x 2 ) - 1 ) {
      $line .= '-' }
  for ( 1 .. length( $init_date . " - " ) ) { $title = " $title" }
  my $init = "$line\n$title$line";
  return sub {
    my $add = shift || q{};
    my $date = BaselinerX::Comm::Balix->ahora_log();
    if ($add) { $init .= "\n$date - $add" if $add }
    else {
       $init .= "\n$line";
       return print $init }
    return $init } }


sub new_log_form {
  use Perl6::Form;
  my $title = uc(shift);    # required!
  my $p     = shift;
  my $NULL  = 0;
  my $WIDTH = 78;
  my $EMPTY = q{};
  my $line;
  my $separator;

  # Set defaults...
  #            If option given...    Use option...  Else default...
  my $html   = exists $p->{html}   ? $p->{html}   : $NULL;
  my $desc   = exists $p->{desc}   ? $p->{desc}   : $EMPTY;
  my $print  = exists $p->{print}  ? $p->{print}  : $NULL;
  my $MAX    = exists $p->{limit}  ? $p->{limit}  : $WIDTH;
  my $format = exists $p->{format} ? $p->{format} : $NULL;
  my $save   = exists $p->{save}   ? $p->{save}   : $NULL;
  my $warn   = exists $p->{warn}   ? $p->{warn}   : $NULL;

  # Defines line length and format style...
  for ( 1 .. $MAX ) {
      $line      .= '-';
      $separator .= '|' }

  # Builds title...
  my $init = "$line\n";
  $init .= form " {$separator} ", $title;
  $init .= "$line\n";

  return sub {
    my $add = shift || q{};
    my $date = concat( date(), '-' );
    my $date_limit;
    for ( 1 .. length($date) - 1 ) { 
        $date_limit .= '<' }

    # If we are adding a new line...
    if ($add) {
       # Sets text size and format...
       my $text_limit = "[";
       for ( 1 .. $MAX - length($date) - 4 ) {
           $text_limit .= $format ? ']' : '[' }

       my $concat = form "{$date_limit}{$text_limit}", $date, $add;
       print $concat if $print;    # Print?
       warn $concat  if $warn;     # Warn?
       $init .= $concat }

    # Otherwise we are done with it...
    else {
       my $ret = "$init$line";
       $ret = to_html( $ret, { font => $html } ) if $html;
       my $filename = "/root/logs/$title";
       if ($save) {
          # Convert to html...
          $filename .= '.html' if $html;

          # Print to file...
          open my $fh, '>', $filename;
          print $fh $ret }

       # Return what we have plus an ending line...
       return $ret }

    return $init } }


# Formats a string in order to print it in html templates.  Receives custom
# font as optional parameter.
sub to_html {
  my ( $v, $p ) = @_;
  my $FONT = 'Courier New';
  my $font = $p->{font}
           ? ( $p->{font} =~ m/^-?\d+$/ ? $FONT
                                        : $p->{font} )
           : $FONT;
  $v =~ s/\n/<br>/g;
  $v =~ s/\s/&nbsp;/g;
  return "<font face=\"$font\">$v</font>" }


# Gets current date in international format.
sub date {
  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst )
   = localtime(time);
  sprintf( "%d/%02d/%02d %02d:%02d:%02d",
   fix_year($year), $mon, $mday, $hour, $min, $sec ) }


sub t {1}


sub nil {0}


sub sum { reduce { $a + $b } @_ }


sub concat { reduce { $a . q{ } . $b } @_ }


sub fix_year { return (shift) + 1900 }


sub is_in {
  my ( $needle, $haystack ) = @_;
  for my $item (@$haystack) {
      return t if $item eq $needle }
  return nil }


1;
