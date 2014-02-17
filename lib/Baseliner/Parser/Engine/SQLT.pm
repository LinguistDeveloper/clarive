package Baseliner::Parser::Engine::SQLT;
use Baseliner::Moose;

=head1 DESCRIPTION

This module uses SQL::Translator to parse one or more statements
and creates a source tree structure with dependencies and
tables and procedure names, etc.

         my $input = q[
             create table foo (
                 foo_id int not null default '0' primary key,
                 foo_name varchar(30) not null default ''
             );

             create table bar (
                 bar_id int not null default '0' primary key,
                 bar_value varchar(100) not null default ''
             );
         ];

=cut

has driver => qw(is rw isa Any default MySQL);

sub parse {
    my ($self,%p) =@_;
    my $f = "$p{file}";
    my $source = $p{source};
    my $tree = {};
    my @depends;
    require SQL::Translator;

     my $t = SQL::Translator->new;
     $t->parser('MySQL') or die $t->error;
     $t->producer( sub {
         my $tr     = shift;
         my $schema = $tr->schema;
         my $output = '';
         # tables
         push @{ $tree->{tables} }, map{
            push @depends, $_->name;
            { 
                table=>$_->name,  
                fields=>[map{
                    $_->name 
                } $_->get_fields ],  
            }
         } $schema->get_tables;
         # procedures
         push @{ $tree->{procedures} }, map{
            push @depends, $_->name;
            { 
                name=>$_->name,
            }
         } $schema->get_procedures;
         return $schema;
     } ) or die $t->error;
     my $output = $t->translate( \$source ) or Util->_fail( $t->error );
    
    return $tree;
}   

1;
