package BaselinerX::Controller::FiledistUnix;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }
extends 'BaselinerX::Controller::Filedist';

with 'Baseliner::Role::Catalog';

sub catalog_name { 'Mapeo de Ficheros Unix' }
sub catalog_description { 'Mapea ficheros Unix' }
sub catalog_icon { '/static/images/icons/action_save.gif' }
sub catalog_url { '/comp/filedist/form_unix.js' }
sub catalog_seq { 100 }

1;
