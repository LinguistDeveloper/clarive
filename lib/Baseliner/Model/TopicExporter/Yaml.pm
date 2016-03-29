package Baseliner::Model::TopicExporter::Yaml;
use Moose;

use Baseliner::Utils qw(_dump _utf8);

has renderer => qw(is ro);

sub export {
    my $self = shift;
    my ( $data, %params ) = @_;

    my $yaml = _dump($data);
    $yaml = _utf8($yaml);

    return <<"EOF";
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
    </head>
    <body>
        <pre>${yaml}</pre>
    </body>
</html>
EOF
}

1;
