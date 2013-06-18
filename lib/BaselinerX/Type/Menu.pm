package BaselinerX::Type::Menu;
use Baseliner::Plug;
use Baseliner::Utils;
use JavaScript::Dumper;
with 'Baseliner::Core::Registrable';

register_class 'menu' => __PACKAGE__;

has id => ( is => 'rw', isa => 'Str', default => '' );
has name               => ( is => 'rw', isa => 'Str' );
has label              => ( is => 'rw', isa => 'Str' );
has index              => ( is => 'rw', isa => 'Int', default => 100 );    ## menu ordering
has url                => ( is => 'rw', isa => 'Str' );
has url_comp           => ( is => 'rw', isa => 'Str' );
has url_run            => ( is => 'rw', isa => 'Str' );
has url_win            => ( is => 'rw', isa => 'Str' );
has url_js             => ( is => 'rw', isa => 'Str' );
has url_browser_window => ( is => 'rw', isa => 'Str' );
has url_iframe         => ( is => 'rw', isa => 'Str' );
has title              => ( is => 'rw', isa => 'Str' );
has level              => ( is => 'rw', isa => 'Int' );
has handler            => ( is => 'rw', isa => 'Str' );
has icon               => ( is => 'rw', isa => 'Str', default => '' );
has cls                => ( is => 'rw', isa => 'Str' );
has actions            => ( is => 'rw', isa => 'ArrayRef' );
has separator          => ( is => 'rw', isa => 'Bool', default => 0 );

sub BUILDARGS {
    my $class = shift;
    my $args  = shift;
    $args->{registry_node}->{actions} = [ $args->{action} ]
        if $args->{action} && !ref $args->{registry_node}->{actions};
    return $args;
} ## end sub BUILDARGS

sub ext_menu_json {
    my ( $self, %p ) = @_;
    my $ref = $self->ext_menu( %p );
    return defined $ref
        ? js_dumper( $ref )
        : undef;
} ## end sub ext_menu_json

sub ext_menu {
    my ( $self, %p ) = @_;

    #my $ret={ xtype=> 'tbbutton', text=> _loc($self->{label}) };
    return '-' if $self->separator;
    my $ret = {text => \"_('$self->{label}')"};
    my @children;
    my $top_level = delete $p{top_level};

    for ( sort { $a->index <=> $b->index } $self->get_children( %p ) ) {
        my $submenu = $_->ext_menu;
        push @children, $submenu;
    }
    return undef if $top_level && scalar( @children ) == 0;

    my $title = $self->{title} || $self->{label};
    my $icon = $self->{icon};

    if ( defined $self->{url} ) {
        $ret->{handler} =
            \"function(){ Baseliner.addNewTab('$self->{url}', _('$title'), { tab_icon: '$icon' } ); }";
    } elsif ( defined $self->{url_run} ) {
        $ret->{handler} = \"function(){ Baseliner.runUrl('$self->{url_run}'); }";
    } elsif ( defined $self->{url_browser_window} ) {
        $ret->{handler} =
            \"function(){ Baseliner.addNewBrowserWindow('$self->{url_browser_window}', _('$title') ); }";
    } elsif ( defined $self->{url_iframe} ) {
        $ret->{handler} =
            \"function(){ Baseliner.addNewIframe('$self->{url_iframe}', _('$title'), { tab_icon: '$icon' } ); }";
    } elsif ( defined $self->{url_comp} ) {
        $ret->{handler} =
            \"function(){  Baseliner.addNewTabComp('$self->{url_comp}', _('$title'), { tab_icon: '$icon' } ); }";
    } elsif ( defined $self->{url_win} ) {
        $ret->{handler} =
            \"function(){  Baseliner.add_wincomp('$self->{url_win}', _('$title'), { }); }";
    } elsif ( defined $self->{handler} ) {
        $ret->{handler} = \"$self->{handler}";
    } elsif ( !@children ) {
        $ret->{handler} = \"function() { Ext.Msg.alert('Error', 'No action defined'); } ";
    }
    $ret->{menu} = {ignoreParentClicks => \'1', items => \@children} if ( @children );
    $ret->{menu_count} = scalar( @children );
    if ( $icon ) {
        $ret->{icon} = $icon;
        $ret->{cls} = $self->{cls} || 'x-btn-text-icon';
    }
    return $ret;
} ## end sub ext_menu
1;
