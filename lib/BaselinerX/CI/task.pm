package BaselinerX::CI::task;
use Baseliner::Moose;

with 'Baseliner::Role::CI';
with 'Baseliner::Role::CI::CatalogTask';

has type => qw(is rw isa Any), default => 'P';
has text_help => qw(is rw isa Str), default => '';
has variables_input => qw(is rw isa HashRef), default=>sub{ +{} };
has variables_output => qw(is rw isa HashRef), default=>sub{ +{} };
has_ci  'area';
has_cis 'prerequisite';
has_cis 'ancestor';
has_cis 'input';
has_cis 'output';

sub rel_type { 
    { 
        prerequisite    => [ from_mid => 'task_task' ],
        ancestor        => [ from_mid => 'task_task' ],        
        area            => [ from_mid => 'task_area' ],
        input           => [ from_mid => 'task_input'],
        output          => [ from_mid => 'task_output']
    },
}

sub icon { '/static/images/icons/catalog-target.png' }

1;
