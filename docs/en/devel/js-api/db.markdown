---
title: Cla.db - MongoDB namespace
---

The database namespace has functions
designed to make use of the MongoDB 
database where Clarive runs. 

### General Considerations

#### Regular expressions

Using regular expressions is necessary for searching Mongo,
for that you need to generate a `Cla.regex()` object
since *javascript regular expressions are not supported 
through the Mongo interface*. 

Example:

    var doc = Cla.db
            .getCollection("topic")
            .findOne({ title: Cla.regex("there","i") });


### Cla.db.getDatabase(dbname)

Returns a connection to a MongoDB database
within the Clarive MongoDB instance.

With the returning object, you can use any other 
`db.` method.

    var db = Cla.db.getDatabase("mydb");
    var coll = Cla.db.getCollection("mycoll");
    coll.insert({ id: 1, txt:"my first doc" });
    coll.findOne({ id: 1 }); 

### Cla.db.getCollection(collectionName)

Returns a Mongo collection from the database.

A collection is analogous to a table in the relational 
database world.

There is no need to create a new collection, just use it
and it will be created by Mongo.

### Cla.db.seq(sequenceName, [resetCounter])

Accesses the Clarive sequence table
to increment the sequence.

    var nextid  = Cla.db.seq('myseq'); // should be 1
    var another = Cla.db.seq('myseq'); // should be 2
    Cla.db.seq('myseq', 1); // resets the sequence back to 1

### collection.insert(document)

Inserts a document into a collection.

    var coll = Cla.db.getCollection('mycoll');
    coll.insert({ title: 'test', priority: 80, other: [ 1,2,3 ], nested: { a: 11, b: 22 } });

### collection.remove(query)

Removes one or more documents from a collection. 

    var coll = Cla.db.getCollection('mycoll');
    coll.remove({ title: 'test' });

### collection.update(query, options)

Updates documents in a collection;

    var coll = Cla.db.getCollection('mycoll');
    coll.update({ title: 'test' }, { $set : { title: 'test2' } });

### collection.drop()

Drops a collection. 

    var coll = Cla.db.getCollection('mycoll');
    coll.drop();

### collection.clone()

Copies one collection to another. 

    var coll = Cla.db.getCollection('mycoll');
    coll.clone('mycoll-copy');

### collection.findOne(query, [fields])

Finds one document in the collection
and returns the document. 

Returns `undefined` if no documents were 
found. 

    var coll = Cla.db.getCollection('mycoll');
    coll.insert({ id: 22, title: 'test' });
    var doc = coll.findOne({ id: 22, title: 'test' });
    print( doc.id );

### collection.find(query)

Returns a cursor with the results of
the search, also called *result set*.

    var coll = Cla.db.getCollection('topic');
    var cursor = coll.find({ priority: { $gt: 100 } });
    while( cursor.hasNext() ) {
        var doc = cursor.next();
        print( doc.mid );
    }

The returning cursor query is not executed until one the
cursor methods is called (`next()`, `count()`, etc.);

### cursor.next()

Returns the next document in the cursor's result set.

    var cursor = Cla.db.getCollection('topic').find();
    var doc = cursor.next();

### cursor.hasNext()

Returns true or false depending if the cursor 
has already gone through all its rows. 

    var cursor = Cla.db.getCollection('topic').find();
    if( cursor.hasNext() ) {
        // ...
    }

### cursor.forEach()

Iterates a cursor result set with a callback function.

    var cursor = Cla.db.getCollection('topic').find();
    cursor.forEach(function(doc){
        print( doc.mid );
    });

### cursor.count()

Returns the number of documents retrieved by 
a cursor. 

    var cursor = Cla.db.getCollection('topic').find();
    Cla.printf( "Found %d rows", cursor.count() );

### cursor.limit(numberOfRows)

Limit the number of documents returned by the cursor. 

    var cursor = Cla.db.getCollection('topic').find();
    cursor.limit(10);
    Cla.printf( "Found %d rows", cursor.count() );   // should print 10 rows

### cursor.skip(numberOfRows)

Skip the first few rows of the result set returned. 

    var cursor = Cla.db.getCollection('topic').find();
    cursor.skip(50);
    cursor.limit(10);
    cursor.forEach( function(doc){
        Cla.dump( doc );  // should dump docs 50 to 60 in the result set
    });

### cursor.sort(sortObject)

Configures the sorting for the result set to be returned. 

    var cursor = Cla.db.getCollection('topic').find();
    cursor.sort({ title: 1 }); // sort by mid (as numeric) 
    cursor.sort({ m: 1 }); // sort by mid (as numeric) 

