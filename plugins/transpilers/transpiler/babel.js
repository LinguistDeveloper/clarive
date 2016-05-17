(function(code){
    var babel = require('babel.min.js');
    return babel.transform(code).code;
})
