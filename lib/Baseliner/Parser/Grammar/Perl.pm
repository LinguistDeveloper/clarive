package Baseliner::Parser::Grammar::Perl;
use Baseliner::Moose;

sub path_capture {
    q{
    ^/.+/(?<module>.+?)\.\w+$
    }
}
sub grammar {
    q{
        <nocontext: >  
        <perl>
        <rule: perl>                 <[MATCH=statement]>+ % ; 
        <rule: statement>            <line=matchline> <module=package> | <line=matchline> <depend=use> | <line=matchline> <depend=require> 
        <rule: package>              package <MATCH=package_name>
        <rule: use>                  use <MATCH=package_name> <stmt>?
        <rule: require>              require <MATCH=package_name>
        <rule: comment>              \# \w+
        <token: package_name>        [\w\:]+
        <token: stmt>                [^;]*
        <token: nl>                  \n
        <token: ws>                  (?: \s+ | \#[^\n]* )*    # redefine whitespace so that comments are included

    }
}


1;

