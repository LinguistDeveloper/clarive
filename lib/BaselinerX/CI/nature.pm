package BaselinerX::CI::nature;
use Baseliner::Moose;
use Baseliner::Utils;
use namespace::autoclean;

with 'Baseliner::Role::CI::Nature';
with 'Baseliner::Role::CI::VariableStash';

sub icon { '/static/images/icons/nature.gif' }


has include => qw(is rw isa Any);
has exclude => qw(is rw isa Any);
has_cis 'parsers';
has_cis 'items';

sub rel_type {
    { 
        items => [ from_mid => 'nature_item' ] ,
        parsers => [ from_mid => 'nature_parser' ] ,
    };
}

service scan => 'Scan Nature Items' => sub {
    my ($self,$c,$p) =@_;
    $self->scan;  # asssumes the nature already has items 
    return "ok scan: " . Util->_dump( $self );
};

sub has_bl { 0 }

1;
