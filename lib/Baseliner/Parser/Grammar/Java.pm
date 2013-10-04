package Baseliner::Parser::Grammar::Java;
use Baseliner::Moose;

sub grammar {
    q{
        <nocontext: >
        <Java>
        <rule: Java>                               <prefix=package_declaration>? <[depends=import_declaration]>* <[module=type_declaration]>* 
        <rule: package_declaration>                (?: <matchline> package <MATCH=package_name> );
        #<rule: package_name>                       <[MATCH=identifier]>+ % (\.) 
        <rule: package_name>                       <MATCH=type_name>
        <rule: type_declaration>                   <MATCH=class_declaration> # | <interface_declaration> 
        <rule: class_declaration>                  <.class_modifiers>? class <MATCH=identifier> <super>? <interfaces>? { .* }  
        <rule: class_modifiers>                    <[class_modifier]>+
        <rule: class_modifier>                     public | abstract | final 
        <rule: super>                              extends <class_type> 
        <rule: class_type>                         <type_name>
        <rule: interfaces>                         implements <interface_type_list>
        <rule: interface_type_list>                <[interface_type]>+ % , 
        <rule: interface_type>                     <type_name>
        <rule: type_name>                          <MATCH=qualified_package>
        <rule: import_declaration>                 <MATCH=single_type_import_declaration> | <MATCH=type_import_on_demand_declaration>
        <rule: single_type_import_declaration>     import <MATCH=type_name> ;
        <rule: type_import_on_demand_declaration>  import <MATCH=package_with_mask> ;
        <token: package_with_mask>                  [_\$a-zA-Z][_\$a-zA-Z0-9\.\*]*
        <token: identifier>                        [_\$a-zA-Z][_\$a-zA-Z0-9]*   # probably missing unicode
        <token: qualified_package>                 [_\$a-zA-Z][_\$a-zA-Z0-9\.]*   # probably missing unicode
        <token: ws>                                (?: \s+ | //[^\n]* | /\*(?:(?!\*/).)*\*/ )*  # redefine whitespace with comments
    }    
}

=pod 

    q{
    <nocontext: >
    <Java>
    <rule: Java>                               <package_declaration>? <[import_declaration]>*
    <rule: package_declaration>                (?: <matchline> package <package_name> );
    #<rule: package_name>                       <identifier> | <package_name> \. <identifier>
    <rule: package_name>                       <[identifier]>+ % (\.) 
    # <rule: type_name>                          <identifier> | <package_name> \. <identifier>
    <rule: type_name>                          <[identifier]>+ % (\.)
    #<rule: import_declarations>                <import_declaration> | <import_declarations> <import_declaration>
    <rule: import_declaration>                 <single_type_import_declaration> | <type_import_on_demand_declaration>
    <rule: single_type_import_declaration>     import <type_name> ;
    <rule: type_import_on_demand_declaration>  import <package_name> \. \* ;
    <rule: identifier>                         [_\$a-zA-Z][_\$a-zA-Z0-9]*   # probably missing unicode
    }

=cut

1;
