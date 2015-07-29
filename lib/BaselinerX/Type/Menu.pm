package BaselinerX::Type::Menu;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
with 'Baseliner::Role::Registrable';

register_class 'menu' => __PACKAGE__;

has id                 => ( is => 'rw', isa => 'Str', default => '' );
has name               => ( is => 'rw', isa => 'Str' );
has label              => ( is => 'rw', isa => 'Str' );
has index              => ( is => 'rw', isa => 'Int', default => 100 );                ## menu ordering
has url                => ( is => 'rw', isa => 'Str' );
has url_comp           => ( is => 'rw', isa => 'Str' );
has url_run            => ( is => 'rw', isa => 'Str' );
has url_eval           => ( is => 'rw', isa => 'Str' );
has url_js             => ( is => 'rw', isa => 'Str' );
has url_browser_window => ( is => 'rw', isa => 'Str' );
has url_iframe         => ( is => 'rw', isa => 'Str' );
has title              => ( is => 'rw', isa => 'Str' );
has level              => ( is => 'rw', isa => 'Int' );
has handler            => ( is => 'rw', isa => 'Str' );
has icon               => ( is => 'rw', isa => 'Str', default => '' );
has cls                => ( is => 'rw', isa => 'Str', default => 'bali-main-menu' );
has comp_data          => ( is => 'rw', isa => 'HashRef', default => sub { +{} } );
has separator          => ( is => 'rw', isa => 'Bool', default => 0 );
has hideOnClick        => ( is => 'rw', isa => 'Bool', default =>1 );

sub ext_menu_json {
    my ($self, %p)=@_;
    my $ref = $self->ext_menu(%p);
    require JavaScript::Dumper;
    return defined $ref
        ? JavaScript::Dumper::js_dumper($ref)   # TODO this is the only dumper that does bare \'function()' ? 
        : undef;
}

sub ext_menu {
    my ($self, %p)=@_;
    #my $ret={ xtype=> 'tbbutton', text=> _loc($self->{label}) };
    return '-' if $self->separator;
    my $ret={ text=> \"_('$self->{label}')", hideOnClick=>\( $self->hideOnClick ) };
    my @children;
    my $top_level = delete $p{top_level};
    for( sort { sprintf('%05d-%s',$a->index,$a->label) cmp sprintf('%05d-%s',$b->index,$b->label) } grep {$_->index && $_->label} $self->get_children(%p) ) {
        my $submenu = $_->ext_menu(%p);
        push @children, $submenu;
    }
    return undef if $top_level && scalar(@children) == 0;

    my $title = $self->{title} || $self->{label};
    my $icon  = $self->{icon};
    
    my $comp_data = $self->comp_data;

    if( defined $self->{url} ) {
        $comp_data->{tab_icon} //= $icon;
        $comp_data = _encode_json( $comp_data );
        $ret->{handler}=\"function(){ Baseliner.addNewTab('$self->{url}', _('$title'), $comp_data ); }";
    }
    elsif( defined $self->{url_run} ) {
        $ret->{handler}=\"function(){ Baseliner.runUrl('$self->{url_run}'); }";
    }
    elsif( defined $self->{url_eval} ) {
        $ret->{handler}=\"function(){ Baseliner.evalUrl('$self->{url_eval}'); }";
    }
    elsif( defined $self->{url_browser_window} ) {
        $ret->{handler}=\"function(){ Baseliner.addNewBrowserWindow('$self->{url_browser_window}', _('$title') ); }";
    }
    elsif( defined $self->{url_iframe} ) {
        $comp_data->{tab_icon} //= $icon;
        $comp_data = _encode_json( $comp_data );
        $ret->{handler}=\"function(){ Baseliner.addNewIframe('$self->{url_iframe}', _('$title'), $comp_data ); }";
    }
    elsif( defined $self->{url_comp} ) {
        $comp_data->{tab_icon} //= $icon;
        $comp_data = _encode_json( $comp_data );
        $ret->{handler}=\"function(){  Baseliner.addNewTabComp('$self->{url_comp}', _('$title'), $comp_data ); }";
    }
    elsif( defined $self->{handler} ) {
        $ret->{handler}=\"$self->{handler}";
    }
    elsif( ! @children ) {
        $ret->{handler}=\"function() { Ext.Msg.alert('Error', 'No action defined'); } "; 
    }
    $ret->{menu} = { ignoreParentClicks=>\'1', items=>\@children } if(@children);
    $ret->{menu_count} = scalar(@children);
    $ret->{cls} ||= $self->{cls};
    if( $icon ) {
        $ret->{icon} = $icon;
        $ret->{cls} = 'x-btn-text-icon';
    } 
    return $ret;
}
1;
