(function(params) {
    return {
        fields: [
            Baseliner.ci_box({
                name: 'items',
                fieldLabel: _('Item'),
                allowBlank: true,
                role: 'Item',
                value: params.rec.item,
                singleMode: false
            })
        ]
    }
})