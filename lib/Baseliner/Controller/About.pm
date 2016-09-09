package Baseliner::Controller::About;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Try::Tiny;

BEGIN {  extends 'Catalyst::Controller' }

register 'action.help.server_info' => { name => _locl('View server info in about window')};
register 'menu.help' => { label => _locl('Help'), index => 999 };

register 'menu.help.help_main' => {
    label => _locl('Clarive Help'),
    title => _locl('Clarive Help'),
    icon  => '/static/images/icons/help.svg',
    url_eval => '/site/help-show.js',
    index => 10
};
register 'menu.help.about' => {
    label => _locl('About...'),
    icon  => '/static/images/icons/about.svg',
    url   => '/about/show',
    title => _locl('About') . ' ' . ( Clarive->config->{app_name} // 'Clarive' ),
    index => 999
};

sub show : Local {
    my ( $self, $c ) = @_;
    require Sys::Hostname;
    my @about = map { { name=>$_, value=>$c->config->{About}->{$_} } } keys %{ $c->config->{About} || {} };
    push @about, { name=>_locl('Server Version'), value=>$Baseliner::VERSION };

    if ( Baseliner::Model::Permissions->user_has_action( action => 'action.help.server_info', username => $c->username ) ) {
        push @about, { name=>_loc('Perl Version'), value=>$] };
        push @about, { name=>_loc('Hostname'), value=>Sys::Hostname::hostname() };
        push @about, { name=>_loc('Process ID'), value=>$$ };
        push @about, { name=>_loc('Server Time'), value=>_now };
        push @about, { name=>_loc('Server Exec'), value=>$0 };
        push @about, { name=>_loc('Server Bin'), value=>$FindBin::Bin };
        push @about, { name=>_loc('Server Parent ID'), value=>$ENV{BASELINER_PARENT_PID} };
        push @about, { name=>_loc('OS'), value=>$^O };
        push @about, { name => _loc('Active users count'), value => Clarive::Util::TLC->user_count };
        push @about, { name => _loc('Active nodes count'), value => Clarive::Util::TLC->node_count };
        $c->stash->{environment_vars} = [
            map {
                +{ name=>$_, value=>$ENV{$_} }
            }
            grep /(CLARIVE|BASELINER)/i, keys %ENV
        ];
        $c->stash->{tlc} = $Baseliner::TLC;
    }
    $c->stash->{about} = \@about;

    my $licenses     = [];
    my $current_year = DateTime->now->year();
    foreach my $license_file ( grep { -e } glob('LICENSE* features/*/LICENSE') ) {
        my $content = _file($license_file)->slurp;
        $content =~ s/\(CURRENT_DATE\)/2010-$current_year/g;
        push @$licenses,
          {
            name => $_,
            text => $content
          };
    }

    $c->stash->{licenses} = $licenses;

    $c->stash->{copyright} = [
        map {
           { name=>$_, text=>scalar _file( $_ )->slurp };
        }
        grep { -e }
        glob( 'COPYRIGHT* features/*/COPYRIGHT' )
    ];
    if ($c->config->{logo_file}){
        $c->stash->{about_logo} = $c->config->{logo_file};
    }
    $c->stash->{third_party} = try { scalar $c->path_to('THIRD-PARTY-NOTICES')->slurp };
    $c->stash->{template} = '/site/about.html';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
