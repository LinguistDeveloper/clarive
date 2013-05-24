package Baseliner::Moose;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    with_meta => ['has_ci', 'has_cis'],
    also      => ['Moose'],
);

sub has_ci {
    my $meta = shift;
    my $name = shift;
    my %options;
    if ( @_ > 0 && @_ % 2 ) {
        $options{isa} = shift;
        $options{is}  = 'rw';
        $options{traits}  = ['CI'];
        if( @_ > 1 ) {  # allow: has_ci 'att' => 'Obj', required=>1;
            %options = ( %options, @_ );
        }
    }
    else {
        %options = @_;
        $options{isa} ||= 'CI';
        $options{is}  ||= 'rw';
        $options{traits} ||= ['CI'];
    }
 
    $meta->add_attribute( $name, %options, );
}

sub has_cis {
    my $meta = shift;
    my $name = shift;
    my %options;
    if ( @_ > 0 && @_ % 2 ) {
        $options{isa} = shift;
        $options{is}  = 'rw';
        $options{traits}  = ['CI'];
        if( @_ > 1 ) {  # allow: has_ci 'att' => 'Obj', required=>1;
            %options = ( %options, @_ );
        }
    }
    else {
        %options = @_;
        $options{isa} ||= 'CIs';
        $options{is}  ||= 'rw';
        $options{traits} ||= ['CI'];
    }
 
    $meta->add_attribute( $name, %options, );
}


1;
