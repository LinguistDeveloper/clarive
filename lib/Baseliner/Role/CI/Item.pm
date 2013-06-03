package Baseliner::Role::CI::Item;
use Moose::Role;
with 'Baseliner::Role::CI';

sub icon { '/static/images/icons/page.png' }

has name       => qw(is rw isa Maybe[Str]);    # basename
has dir        => qw(is rw isa Str default /);  # my parent
has path       => qw(is rw isa Str default /);  # fullpath
has is_dir     => qw(is rw isa Maybe[Bool]);
has basename   => qw(is rw isa Str lazy 1), default => sub {
    my ($self)=@_;
    $self->name =~ /^(.*)\.(.*?)$/ ? $1 : $self->name;
};
has extension  => qw(is rw isa Str lazy 1), default => sub {
    my ($self)=@_;
    lc( $self->name =~ /^(.*)\.(.*?)$/ ? $2 : '' );
};
has module_dependencies => qw(is rw isa ArrayRef), default=>sub{[]};
has item_relationship => qw(is rw isa Str default item_item); # rel_type

sub save_relationships {
    my($self, %p)=@_;
    my $cache = $p{cache} // {};
    for my $module ( Util->_array( $self->module_dependencies ) ) {
        my $mid = $cache->{ $module };
        if( !defined $mid ) {
            my $row = DB->BaliMaster->search({ moniker=>$module })->first;
            if( $row ) {
                $mid = $row->mid;
                $cache->{ $module } = $mid;
            }
        }
        if( defined $mid ) {
            DB->BaliMasterRel->find_or_create({ from_mid=>$self->mid, to_mid=>$mid, rel_type=>$p{rel_type} // $self->item_relationship }); 
        }
    }
}

1;

