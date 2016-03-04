package Baseliner::Model::TopicExporter;
use Moose;

use File::Temp  ();
use Class::Load ();
use Baseliner::Model::Events;
use Baseliner::Utils qw(_fail _decode_json _decode_json_safe);

has renderer => qw(is ro);

sub export {
    my $self = shift;
    my ( $format, $data, %params ) = @_;

    my $exporter = $self->_build_exporter($format);

    my $fh = File::Temp->new;

    my $content;
    Baseliner::Model::Events->new_event(
        'event.topic_list.export',
        {
            username         => $params{username},
            export_format    => $format,
            export_title     => $params{title},
            export_params    => _decode_json_safe( $params{params} ),
            export_temp_file => $fh->filename,
        },
        sub {
            $data = _decode_json($data) unless ref $data;

            $content = $exporter->export($data, %params);

            print $fh $content;
            close $fh;
        },
        sub {
            my $error = shift;

            _fail "Export error: $error";
        },
        caller
    );

    return $content;
}

sub _build_exporter {
    my $self = shift;
    my ($format) = @_;

    my $class_name = __PACKAGE__ . '::' . ucfirst( lc($format) );

    Class::Load::load_class($class_name);

    return $class_name->new( renderer => $self->renderer );
}

1;
