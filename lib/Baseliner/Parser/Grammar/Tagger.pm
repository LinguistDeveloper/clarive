package Baseliner::Parser::Grammar::Tagger;
use Baseliner::Moose;

sub grammar {
    #q{
    #    <nocontext: >  
    #    #<debug: on>
    #    <Tagger> 
    #    <rule: Tagger>         <[MATCH=single_tag]>+  % .*
    #    <rule: single_tag>    <matchline> \#\:<tag>\:
    #    <token: tag>           \w+
    #    <token: ws>            (?: \s+ | \#[^\n]* )*    
    #} 
    q{
        <nocontext: >  
        <Tagger> 
        <rule: Tagger>         <[MATCH=single_tag]>+  % (.*)
        <token: single_tag>    <matchline> \#\:<tag>\:
        <token: tag>           \w+
    }
}


1;


