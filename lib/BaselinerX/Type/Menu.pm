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
has cls                => ( is => 'rw', isa => 'Str', default => 'main-menu main-menu-header' );
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

    my $class = lc $self->{id};
    $class =~ s{\s+}{-}g;

    my $handler;
    my $comp_data = $self->comp_data;
    $comp_data->{tab_cls} = "ui-tab-$class";
    $comp_data->{tab_icon} //= $icon;
    $comp_data->{title}    //= $title;

    if ( defined $self->{url} ) {
        $comp_data->{url}  = $self->{url};
        $comp_data->{mode} = 'url';
    }
    elsif ( defined $self->{url_run} ) {
        $comp_data->{url}  = $self->{url_run};
        $comp_data->{mode} = 'run';
    }
    elsif ( defined $self->{url_eval} ) {
        $comp_data->{url}  = $self->{url_eval};
        $comp_data->{mode} = 'eval';
    }
    elsif ( defined $self->{url_browser_window} ) {
        $comp_data->{url}  = $self->{url_browser_window};
        $comp_data->{mode} = 'browserWindow';
    }
    elsif ( defined $self->{url_iframe} ) {
        $comp_data->{url}  = $self->{url_iframe};
        $comp_data->{mode} = 'iframe';
    }
    elsif ( defined $self->{url_comp} ) {
        $comp_data->{url}  = $self->{url_comp};
        $comp_data->{mode} = 'comp';
    }
    elsif ( defined $self->{handler} ) {
        $comp_data->{mode} = 'handler';
        $handler = $self->{handler};
    }
    elsif ( !@children ) {
        $comp_data->{mode} = '';
    }

    my $data_json = _encode_json($comp_data);
    if ($comp_data->{mode} && $comp_data->{mode} eq 'handler'){
        $ret->{handler} = \"$handler"
    }else{
        $ret->{handler} = \"function(){  Cla.dispatcherMenu($data_json); }";
    }
    $ret->{menu} = { ignoreParentClicks=>\'1', items=>\@children } if(@children);
    $ret->{menu_count} = scalar(@children);
    $ret->{cls} ||= $self->{cls};
    if( $icon ) {
        $ret->{icon} = $icon;
        $ret->{cls} = 'x-btn-text-icon';
    }

    $ret->{cls} .= ' ' if $ret->{cls};
    $ret->{cls} .= "ui-menu-$class";

    return $ret;
}
no Moose;
__PACKAGE__->meta->make_immutable;

1;
