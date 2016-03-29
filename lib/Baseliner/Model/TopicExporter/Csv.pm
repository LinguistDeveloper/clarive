package Baseliner::Model::TopicExporter::Csv;
use Moose;

use Encode ();
use Text::Unaccent::PurePerl qw(unac_string);
use Baseliner::Model::Topic;
use Baseliner::Utils qw(_dump _utf8 _array _strip_html);

has renderer => qw(is ro);

sub export {
    my $self = shift;
    my ( $data, %params ) = @_;

    my @csv;
    my @cols;

    my ( $ref_in, $ref_out, $num_file, $numcomment );
    for my $row ( _array $data) {
        my $main_category = $row->{category}->{name} || $row->{category_name};
        my @cells;
        for my $col ( grep { length $_->{name} } _array( $params{columns} ) ) {
            my $col_id = $col->{id};
          COMMENTS:
            if ( $col->{id} eq 'numcomment' && $params{id_report} !~ /report/ )
            {    # Look for all fields managed in this column
                if ( $col_id eq 'numcomment' ) {
                    $col_id = 'referenced_in';
                }
                elsif ( $col_id eq 'referenced_in' ) {
                    $col_id = 'references_out';
                }
                elsif ( $col_id eq 'references_out' ) {
                    $col_id = 'num_file';
                }
                elsif ( $col_id eq 'num_file' ) {
                    $col_id = 'numcomment';
                }
            }
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
                    foreach ( keys $du ) {
                        push @res, "$_:$du->{$_}";
                    }
                    $v = join ';', @res;
                }
                else {
                    $v = join ',', @$v;
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
                    for my $step ( keys $v ) {
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

    my $body = join "\n", @csv;

    # I#6947 - chromeframe does not download csv with less than 1024: pad the file
    my $len = length $body;
    $body .= "\n" x ( 1024 - $len + 1 ) if $len < 1024;

    $body = Encode::encode('UTF-8', $body);

    return $body;
}

1;
