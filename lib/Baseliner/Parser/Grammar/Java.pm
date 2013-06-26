package Baseliner::Parser::Grammar::Java;
use Baseliner::Moose;

sub grammar {
    q{
        <Java>
        <rule: Java>                               <package_declaration>? <[import_declaration]>* <[type_declaration]>*
        <rule: package_declaration>                (?: <matchline> package <package_name> );
        #<rule: package_name>                       <identifier> | <package_name> \. <identifier>
        <rule: package_name>                       <[MATCH=identifier]>+ % (\.) 
        
        <rule: type_declaration>                   <class_declaration>  # | <interface_declaration> 
        <rule: class_declaration>                  <MATCH=class_modifiers>? class <identifier> <super>? <interfaces>? { .* }  
        <rule: class_modifiers>                    <[MATCH=class_modifier]>+ 
        <rule: class_modifier>                     public | abstract | final 
        <rule: super>                              extends <class_type> 
        <rule: class_type>                         <type_name>
        <rule: interfaces>                         implements <interface_type_list>
        <rule: interface_type_list>                <[interface_type]>+ % , 
        <rule: interface_type>                     <type_name>
        #<token: class_body>                         { .* }

        # <rule: type_name>                          <identifier> | <package_name> \. <identifier>
        <rule: type_name>                          <MATCH=qualified_package>
        #<rule: qualified_package>                  <[MATCH=identifier]>+ % (\.)
        #<rule: import_declarations>                <import_declaration> | <import_declarations> <import_declaration>
        <rule: import_declaration>                 <MATCH=single_type_import_declaration> | <MATCH=type_import_on_demand_declaration>
        <rule: single_type_import_declaration>     import <type_name> ;
        <rule: type_import_on_demand_declaration>  import <package_name> \. \* ;
        <token: identifier>                         [_\$a-zA-Z][_\$a-zA-Z0-9]*   # probably missing unicode
        <token: qualified_package>                  [_\$a-zA-Z][_\$a-zA-Z0-9\.]*   # probably missing unicode
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
