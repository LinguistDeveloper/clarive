(function(params){
    var users;

    if( !params.rec ) {
        params.rec = {}
    }

    users = new Baseliner.CIGrid({
        fieldLabel:_('Users'), ci: { 'class': 'user' },
        anchor:'100%',
        height: 500,
        value: params.rec.users, name: 'users'
    });

    return [users]
})
