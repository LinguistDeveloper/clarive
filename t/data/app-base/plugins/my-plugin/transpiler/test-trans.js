(function(code){
    if (/error/.test(code)) {
        throw new Error('some error');
    }
    else if (/empty/.test(code)) {
        return undefined;
    }
    return code + '.aa + 11';
});
