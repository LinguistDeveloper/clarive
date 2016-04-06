package TestExtJsComponent;
use strict;
use warnings;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{driver} = $params{driver};
    $self->{elem}   = $params{elem};

    return $self;
}

sub id {
    my $self = shift;

    return $self->{elem}->{id};
}

sub elem {
    my $self = shift;

    return $self->{elem}->{dom} || $self->{elem};
}

sub get_xtype { shift->_eval('function(cmp) { return cmp.getXType() }') }

sub get_form {
    my $self = shift;

    my $id = $self->_eval('function(cmp) { return cmp.getForm().id }');

    my $elem = $self->{driver}->find_element( $id, 'id' );

    return ref($self)->new( driver => $self->{driver}, elem => $elem );
}

sub is_displayed { shift->_eval('function(cmp) { return !cmp.hidden }') }
sub is_rendered  { shift->_eval('function(cmp) { return cmp.rendered }') }
sub is_enabled   { shift->_eval('function(cmp) { return !cmp.disabled }') }

sub _eval {
    my $self = shift;
    my ($js) = @_;

    my $script = qq{
       var id = arguments[0];

       var cmp = Ext.getCmp(id);

       if (cmp) {
           var fn = $js;
           return fn(cmp);
       }

       return "";
    };

    return $self->{driver}->execute_script( $script, $self->id );
}

1;
