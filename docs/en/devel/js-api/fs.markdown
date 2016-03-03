---
title: Cla.fs - Local Filesystem Access
---

These functions are for accessing the Clarive
server instance filesystem. 

For remote filesystem management, look at
the agent CI. 

### Cla.fs.createFile(file,contents)

Creates and writes content to file in one go.

```javascript
Cla.fs.createFile("/tmp/myfile", "first line\nsecond line\n");
```

### Cla.fs.slurp(file)

Reads files content into a string in one go.

```javascript
var content = Cla.fs.slurp("/tmp/myfile");
```

### Cla.fs.openFile(filepath,mode)

Opens a file for reading, returning
a file handle. 

```javascript
var fh = Cla.fs.openFile("/tmp/myfile", "r");
while( !fh.eof() ) {
    print( fh.readLine() );
}
```

#### fh.readLine()

Reads a single line from the file.

```javascript
var fh = Cla.fs.openFile("/tmp/myfile", "r");
while( !fh.eof() ) {
    print( fh.readLine() );
}
```

Returns `undefined` if the file has reach its end.

#### fh.readChunk(length)

Reads any number of bytes from a file. 

```javascript
var fh = Cla.fs.openFile("/tmp/myfile", "r");
while( !fh.eof() ) {
    print( fh.readChunk(10) ); // read only 10 bytes out from the file
}
```

Returns `undefined` if the file has reach its end.

#### fh.eof()

Checks if filehandle has reached the end of file.

#### fh.close()

Closes a file.

```javascript
var fh = Cla.fs.openFile("/tmp/myfile", "r");
fh.close();
```

#### fh.fileno()

Returns the filehandle number. 

```javascript
var fh = Cla.fs.openFile("/tmp/myfile", "r");
print( fh.fileno() );
```

### Cla.fs.iterateDir(dirpath,cb)

Iterates through directory contents.

```javascript
Cla.fs.iterateDir( "/tmp", function(file,path){
    if( Cla.fs.isDir(file) ) return; 
});
```

### Cla.fs.stat(file)

Returns status info for a file.

```javascript
Cla.dump( Cla.fs.stat("/tmp/myfile") );
```

Not all fields are supported on all filesystem types. Here are the meanings of the fields:

<pre>
 0 dev      device number of filesystem
 1 ino      inode number
 2 mode     file mode  (type and permissions)
 3 nlink    number of (hard) links to the file
 4 uid      numeric user ID of file's owner
 5 gid      numeric group ID of file's owner
 6 rdev     the device identifier (special files only)
 7 size     total size of file, in bytes
 8 atime    last access time in seconds since the epoch
 9 mtime    last modify time in seconds since the epoch
10 ctime    inode change time in seconds since the epoch
11 blksize  preferred I/O size in bytes for interacting with the file (may vary from file to file)
12 blocks   actual number of system-specific blocks allocated on disk (often, but not always, 512 bytes each)
</pre>

### Cla.fs.isDir(`path`)

Returns true if `path` is a directory.

### Cla.fs.isFile(path)

Returns true if `path` is a file.

### Cla.fs.deleteFile(path)

Deletes a file.

```javascript
Cla.fs.deleteFile("/tmp/myfile");
```

### Cla.fs.createDir()

Creates a directory in the filesystem,
but does not create the intermediate paths.

```javascript
var dir = "/tmp/dad/son";
if( !Cla.fs.isDir(dir) ) {
    Cla.fs.createDir(dir);
}
```

### Cla.fs.createPath()

Creates a directory in the filesystem,
creating the intermediate parent path if necessary. 

```javascript
var dir = "/tmp/dad/son";
Cla.fs.createPath(dir);
```

### Cla.fs.deleteDir()

Deletes an empty directory. 

```javascript
Cla.fs.deleteDir("/tmp/dad/son");
```

Returns true if deletion was successful. 
