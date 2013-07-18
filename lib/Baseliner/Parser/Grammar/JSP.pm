package Baseliner::Parser::Grammar::JSP;
use Baseliner::Moose;

sub grammar {
    q{
        <nocontext: >
        
        <JSP>
        #<rule: JSP>                                <depends=import_blocks>? | <[jsp_block]>* | <[tex=(?:\S+)]>*
        
        <rule: JSP>                                ^ (.*)? <[blocks]> (.*)? $
        <rule: blocks>                             <depends=import_blocks> # | <depends=include_block> 
        
        <rule: include_block>                      <[jsp_include]>+ 
        <rule: jsp_include>                        \< jsp : include page = " <MATCH=(?:.*)> " flush="true" \/\>
        
        <rule: import_blocks>                      <[MATCH=import_block]>+ <minimize:>
        <rule: import_block>                       \<\% @ page import = " <MATCH=packages>? " \%\> 
        <rule: packages>                           <[MATCH=package_with_mask]>* % , <minimize: >
        
        <rule: jsp_block>                          \<\% <text>? \%\> 
        #<rule: contents>                           <[MATCH=text]>
        <rule: text>                               (?:(?!\%\>).)*
        
        <token: package_with_mask>                 [_\$a-zA-Z][_\$a-zA-Z0-9\.\*]*
        <token: identifier>                        [_\$a-zA-Z][_\$a-zA-Z0-9]*   
        <token: qualified_package>                 [_\$a-zA-Z][_\$a-zA-Z0-9\.]* 
        <token: ws>                               (?: \s+ | //[^\n]* | /\*(?:(?!\*/).)*\*/ )*  # redefine whitespace with comments
        <token: open_tag>   \<\%
        <token: close_tag>   \%\>
    }    
}

1;
