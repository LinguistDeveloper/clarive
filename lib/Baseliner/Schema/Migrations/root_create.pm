package Baseliner::Schema::Migrations::root_create 2;
use Mouse;

sub upgrade {
    if( ! ci->user->find_one({ name=>'root' }) ) {
        ci->user->new({
            name             => 'root',
            username         => 'root',
            project_security => {},
            realname         => 'Root User',
            password         => Util->_md5( Util->_md5( Util->_md5 ) ),
        })->save;
    }
}

sub downgrade {
    
}

1;




