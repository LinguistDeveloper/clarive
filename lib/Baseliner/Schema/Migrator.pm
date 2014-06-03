package Baseliner::Schema::Migrator;
use v5.10;
use strict;
use warnings;
use Baseliner::Utils;

sub check {
    my ($self)=@_;
    my %ids;
    _log('Checking for migrations...');
    my @current = mdb->_migrations->find->all;
    my @candidates = Baseliner->path_to('lib/Baseliner/Schema/Migrations'), map { _dir($_->path,'lib/Baseliner/Schema/Migrations') } _array(Baseliner->features->list );
    for my $f ( map { $_->children } grep { -e } @candidates ) {
        my ($id) = $f->basename =~ /^(.+)\.(.*?)$/;
        my $body = $f->slurp;
        my ($version) = $body =~ /our\s+\$VERSION\s*=\s*([0-9]+)/;
        $version //= 0;
        $ids{ $id } = 1;
        my $wh ={ _id=>$id };
        $wh->{'$or'} = [{version=>undef},{ '$and'=>[{version=>{'$gte'=>$version}}, {version=>{ '$ne'=>undef } }] }] if $version>0;
        if( my $doc = mdb->_migrations->find_one($wh) ) {
            _debug("====> Migration ok: $id (version: $version)" );
            next;
        } else {
            # lib/Clarive/Cmd/install->_ask_me()
            my $pkg = "Baseliner::Schema::Migrations::$id";
            _info( _loc('Running migration %1 (%2)...', $id,$version) ); 
            eval { 
                eval "require $pkg" or die $@;
                $pkg->upgrade;
            };
            my $err = $@;
            mdb->_migrations->update({ _id=>$id }, { _id=>$id, rb=>$body, err=>$err, ts=>mdb->ts, version=>0+$version },{ upsert=>1 });
        }
        say "ID=$id";
    }
    
    # check if migrations past are still here
    for my $doc ( @current ) {
        next if exists $ids{ $doc->{_id} };
        _warn( _loc( 'Migration source not found: %1. Rolling back...', $doc->{_id} ) );
    }
    
    _log('Migration check done.');
}

1;
