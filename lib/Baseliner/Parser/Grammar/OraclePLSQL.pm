package Baseliner::Parser::Grammar::OraclePLSQL;
use Baseliner::Moose;

sub grammar {
    q{
        <nocontext: >
        <PLSQL>
        <token: PLSQL>                             <definition>

        <rule: definition>                         <create_replace> <declaration> <arguments>? <return>? (?: IS <variables>?  )? # <implementation>?
        <rule: create_replace>                     CREATE (?: OR REPLACE )? 
        
        <rule: implementation>                     BEGIN <body> END;
        <rule: body>                               <[statement]>+ % ; 
        <rule: variables>                          <[variable]>+ % (;) 
        <rule: variable>                           <identifier> <type> <default>?
        <rule: arguments>                          \( <[variable]> + % (,) \)
        <rule: return>                             RETURN <identifier>
        <rule: default>                            DEFAULT <anything> 
        <rule: type>                               <data_type> (?: \( <size> \) )?
        <rule: declaration>                        <keyword_declare> <identifier>
        <rule: keyword_declare>                    FUNCTION | PROCEDURE | TRIGGER
        <token: data_type>                         VARCHAR2 | NUMBER | DATE | VARCHAR | CHAR | INTEGER | BOOLEAN
        <rule: statement>                          <[word]>+ % (\s) 
        <rule: line>                               ^$ | ^\s*(~[^']?|[^@]).*$ 
        <token: word>                              \S+
        <token: anything>                          \S+
        <token: size>                              [0-9]+
        <rule: identifier>                         [_a-zA-Z][_a-zA-Z0-9]* 
    }
}

1;
