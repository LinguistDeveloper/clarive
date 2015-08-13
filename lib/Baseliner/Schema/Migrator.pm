package Baseliner::Schema::Migrator;
use v5.10;
use strict;
use warnings;
use Baseliner::Utils;

sub check {
    my ($self, $migration)=@_;
    $migration //= '';
    my %args = map { $_=>1 } split /,/, $migration;
    my %ids;
    say('Checking for migrations...');
    my @current = mdb->_migrations->find->all;
    my @candidates = (
        Clarive->path_to('lib/Baseliner/Schema/Migrations'), 
        map { _dir($_->path,'lib/Baseliner/Schema/Migrations') } _array(Clarive->features->list) 
    );
    for my $f ( map { $_->children } grep { -e } @candidates ) {
        my ($id) = $f->basename =~ /^(.+)\.(.*?)$/;
        my $body = $f->slurp;
        my ($version) = $body =~ /package\s+\S+\s+([0-9]+);/;
        ($version) = $body =~ /our\s+\$VERSION\s*=\s*([0-9]+)/ unless defined $version;
        $version //= 0;
        $ids{ $id } = 1;
        my $wh ={ _id=>$id };
        $wh->{'$or'} = [{version=>undef},{ '$and'=>[{version=>{'$gte'=>0+$version}}, {version=>{ '$ne'=>undef } }] }] if $version>0;
        my $doc = mdb->_migrations->find_one($wh);
        if( $doc && !$args{$id} ) {
            say("====> Migration ok: $id (version: $version)" );
            next;
        } else {
            _warn(_loc('Skipping migration %1 on user request',$id)),next if %args && !exists $args{ $id };
            say "Forcing migration for `$id`" if $args{$id};
            # lib/Clarive/Cmd/install->_ask_me()
            my $pkg = "Baseliner::Schema::Migrations::$id";
            _info( _loc('Running migration %1 (%2)...', $id,$version) ); 
            eval { 
                eval "require $pkg" or die $@;
                $pkg->upgrade;
            };
            my $err = $@;
            Util->_error( $err );
            mdb->_migrations->update({ _id=>$id }, { _id=>$id, rb=>$body, err=>$err, ts=>mdb->ts, version=>0+$version },{ upsert=>1 })
                unless length $err;
        }
        say "ID=$id";
    }
    
    # check if migrations past are still here
    for my $doc ( @current ) {
        next if exists $ids{ $doc->{_id} };
        _warn( _loc( 'Migration source not found: %1. Rolling back...', $doc->{_id} ) );
    }
    
    say('Migration check done.');
}

1;
