package Baseliner::Model::TopicExporter::Csv;
use Moose;

use Encode ();
use Baseliner::Model::Topic;
use Baseliner::Utils qw(_array _strip_html _loc);

has renderer => qw(is ro);

sub export {
    my $self = shift;
    my ( $data, %params ) = @_;

    my @columns = $self->_prepare_columns(%params);

    my @csv;
    my $headers;

    $headers = join( ';', map { "\"" . _loc( $_->{name} ) . "\"" } @columns ) . "\n";

    for my $row ( _array $data) {
        my $main_category = $row->{category}->{name} || $row->{category_name};
        my @cells;
        for my $col (@columns) {
            my $col_id = $col->{id};

            my $v = $row->{$col_id};
            if ( ref $v eq 'ARRAY' ) {
                if ( $col->{id} eq 'projects' ) {
                    my @projects;
                    for ( @{$v} ) {
                        push @projects, ( split ';', $_ )[1];
                    }
                    @$v = @projects;
                }
                ( my $du ) = _array $v;
                if ( ref $du eq 'HASH' && exists $du->{mid} ) {
                    $v = $du->{category}->{name} . " #$du->{mid}";
                }
                elsif ( ref $du eq 'HASH' ) {
                    my @res;
                    foreach ( keys %$du ) {
                        push @res, "$_:$du->{$_}";
                    }
                    $v = join ';', @res;
                }
                else {
                    if ( $col->{id} eq 'referenced_in' || $col->{id} eq 'references_out' ) {
                        $v = scalar @$v;
                    }
                    else {
                        $v = join ',', @$v;
                    }
                }
            }
            elsif ( ref $v eq 'HASH' ) {
                if ( $v && exists $v->{mid} ) {
                    $v = $v->{category}->{name} . " #$v->{mid}";
                }
                else {
                    # $v = Util->hash_flatten($v);
                    # $v = Util->_encode_json($v);
                    # $v =~ s/{|}//g;
                    my $result;
                    for my $step ( keys %$v ) {
                        $result .= "$v->{$step}->{slotname} End: $v->{$step}->{plan_end_date}, ";
                    }
                    if   ($result) { $v = $result }
                    else           { $v = ''; }
                }
            }
            if ( $v && ( $v =~ /^[\d,]+$/ ) && $col_id )
            {    # Look for related category for prepending if $v is a mid or several.
                my $rel_category;
                ($col_id) = ( $col->{id} =~ m/^(.*[^_])_.*$/ ) if $col_id ne 'topic_mid';
                if ( !defined $col_id || !$row->{$col_id} ) {    # Fields in database have not homegeneous format.
                    $col_id = $col->{id};
                }
                if ($col_id) {
                    if ( $col_id !~ /agrupador/ ) {
                        ($col_id) = lc($col_id);
                        ($col_id) =~ s/\s/_/;
                    }
                    if ( ref $row->{$col_id} eq 'HASH' ) {
                        $rel_category = $row->{$col_id}->{category}->{name};
                        $v = $rel_category . ' #' . $v if ($rel_category);
                    }
                    elsif ( ref $row->{$col_id} eq 'ARRAY' ) {
                        my @v = split ',', $v;
                        my $i = 0;
                        for ( @{ $row->{$col_id} } ) {
                            ( my $du ) = _array $_;
                            if ( ref $du eq 'HASH' && exists $du->{category} ) {
                                my $rel_category = $du->{category}->{name};
                                $v[$i] = $rel_category . ' #' . $v[$i];
                            }
                            $i++;
                        }
                        $v = join( ' ', @v );
                    }
                }
            }
            $v = $main_category . ' #' . $v if ( $col_id eq 'topic_mid' && $col->{name} ne 'MID' );
            $v = _strip_html($v);    # HTML Code
            $v =~ s/\t//g   if $v;
            $v =~ s{"}{""}g if $v;

            if ( $v || ( defined $v && $v eq '0' && $params{id_report} && $params{id_report} =~ /\.statistics\./ ) ) {
                push @cells, qq{"$v"};
            }
            else { push @cells, qq{""} }
        }
        push @csv, join ';', @cells;
    }

    my $body = join( "\n", @csv );
    $body = $headers . $body;

    # I#6947 - chromeframe does not download csv with less than 1024: pad the file
    my $len = length $body;
    $body .= "\n" x ( 1024 - $len + 1 - 3 ) if $len < 1024;

    $body = Encode::encode( 'UTF-8', $body );

    $body = "\xEF\xBB\xBF" . $body;

    return $body;
}

sub _prepare_columns {
    my $self = shift;
    my (%params) = @_;

    my @columns = ();

    for my $column ( grep { length $_->{name} } _array( $params{columns} ) ) {
        push @columns, $column;

        # This is a special Info columns. Yes, the column name suggests that the author was under drugs probably
        if ( $column->{id} eq 'numcomment' ) {
            push @columns,
              {
                id   => 'referenced_in',
                name => _loc("Referenced In"),
              };

            push @columns,
              {
                id   => 'references_out',
                name => _loc("References"),
              };

            push @columns,
              {
                id   => 'num_file',
                name => 'file_name',
              };
        }
    }

    return @columns;
}

1;
