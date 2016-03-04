package Baseliner::Model::TopicExporter::Html;
use Moose;

use Baseliner::Utils qw(_array);

has renderer => qw(is ro);

sub export {
    my $self = shift;
    my ( $data, %params ) = @_;

    $data = $self->_report_data_replace( $data, $params{show_desc} );

    return $self->renderer->( data => $data, %params );
}

sub _report_data_replace {
    my $self = shift;
    my ( $data, $show_desc ) = @_;

    my @mids;
    for ( _array( $data->{rows} ) ) {
        push @mids, $_->{topic_mid};

        # find and replace report_data columns
        for my $col ( keys %{ $_->{report_data} || {} } ) {
            $_->{$col} = $_->{report_data}->{$col};
        }
    }

    if ($show_desc) {
        my @descs = mdb->topic->find( { mid => mdb->in(@mids) } )->fields( { description => 1 } )->all;
        map { $_->{description} = ( shift @descs )->{description}; } _array( $data->{rows} );
        push @{ $data->{columns} }, { name => 'Description', id => 'description' };
    }

    return $data;
}

1;
