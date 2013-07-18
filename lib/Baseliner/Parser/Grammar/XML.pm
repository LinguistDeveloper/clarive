package Baseliner::Parser::Grammar::XML;
use Baseliner::Moose;

sub grammar {
    q{
          <logfile: parser_log >   # Log description of the grammar

          <nocontext:>             # Switch off debugging noise

          <Document>               # Define a document  

          <rule: Document>        <[Element]>*     # Contains many elements

          <rule: Element>         <XMLDecl>        # Which can be XML declarations, 
                                | <SelfClosingTag> # OR self closing tags
                                | <NormalTag>      # OR normal tags

          <rule: XMLDecl>         \<\?xml <[Attribute]>* \?\>      # An xml can have zero or more attributes

          <rule: SelfClosingTag>  \< <TagName> <[Attribute]>* / \> # A self closing tag similarly

          <rule: NormalTag>       \< <TagName> <[Attribute]>* \>   # A normal tag can also have attributes
                                      <TagBody>?                                     #   And a body
                                  <EndTag(:TagName)>                                 # And an end tag named the same
          
          <token: TagName>        [^\W\d][^\s\>]+          # A name begins with a non-digit non-non word char
          
          <rule: EndTag>       \< / <:TagName> \>          # An end tag is a tagname in <>s with a leading /   

          <rule: TagBody>         <[NormalTag]>*           # A tag body may contain normal tags 
                                | <[SelfClosingTag]>*      # OR self closing tags                                 
                                | <Text>                   # OR text
                                                           # note that NormalTags are recursive.

          <rule: Text>            [^<]+                           # Text is one or more non < chars

          <rule: Attribute>       <AttrName> = \" <AttrValue> \"  # An attribute is a key="value"

          <token: AttrName>       [^\W\d][^\s]+                   # Attribute names defined similarly to tag names

          <token: AttrValue>      [^"]+                           # Attribute values are series of non " chars
    }
}

1;
