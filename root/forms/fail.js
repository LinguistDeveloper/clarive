(function(params) {
    var data = params.data || {};

    return [
        new Baseliner.MonoTextArea({
            fieldLabel: _('Error Message'),
            height: 80,
            name: 'msg',
            value: data.msg || _('abort here')
        }),
    ];
})
