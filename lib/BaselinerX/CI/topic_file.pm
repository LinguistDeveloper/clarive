package BaselinerX::CI::topic_file;
use Baseliner::Moose;

sub icon { '/static/images/icons/post.png' }

with 'Baseliner::Role::CI::CCMDB';
with 'Baseliner::Role::CI::Item';

has md5 => qw(is rw isa Any);

method checkout( :$dir ) {
    my $file = DB->BaliFileVersion->search({ mid=>$self->mid }, { select=>'filedata' })->hashref->first;
    my $dest = Util->_file($dir,$self->path);
    $dest->dir->mkpath;
    open( my $ff, '>:raw', $dest) or _fail( _loc('Could now checkout topic file `%1`', $dest) );
    print $ff $file->{filedata}; 
    close $ff;
    
    1;
}

1;

