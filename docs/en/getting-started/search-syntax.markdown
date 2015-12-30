---
title: Search Syntax
index: 2000
icon: search-small
---

* Most of Clarive's lists and reports have search boxes. Terms
introduced in the search boxes are case insentive and represent an OR search.


* For example a search for the following terms:
            
        gui security


* Will match all documents that have EITHER gui or security in one
of the documents fields, be it a [CI](concepts/ci) or a [Topic](concepts/topic)

* On the other hand, the following query:
            
        +gui +security

* Will only match documents that have BOTH gui or security in any
of the documents fields. One field, ie. "title" may contain the word "gui", 
and the other, ie. "department" may contain the word "security". 

<br />
### Case Sensitivity

* All searches are case insensitive. To make them case sensitive, 
put double quotes around the word:
            
        "GUI"


* Will only search for documents with the word "GUI" in full uppercase.

* In summary, here's a sample of supported search syntax:
            
        term
        "term"  - case insensitive
        Term  - case insensitive
        T?rm  - match 1 char in ?
        T*rm  - match 0 to many chars in *
        +term1 +term2  - must have both term1 and term2
        +term1 -term2  - must have term1 but not term2
        /term regex.*/  - regular expression

<br />


    
<br />
### Field searching

* Clarive supports also a limited set of 
field searches. Field searches search only specified fields.
            
        status:"QA Done"


* Searches only the "QA Done" status.

* The tool also allows the use of hash for a directly access to a specific topic.
            
        #123456


* Goes directly to the specific topic.
