(function(code){
    var ts = require('typescript.min.js');
    return ts.transpile(code);
})
