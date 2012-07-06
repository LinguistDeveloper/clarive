(function(params){
    return [
        new Baseliner.form.ComboList({ 
            data: ['Petición Simple', 'Petición Compleja'],
            name: 'tipo_pet',
            fieldLabel: 'Tipo Petición',
            emptyText: 'Seleccione Petición...'
        })
    ]
})
