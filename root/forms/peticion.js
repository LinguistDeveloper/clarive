(function(params){
    var petstore=new Ext.data.SimpleStore({
        fields: ['tipo_pet'],
        data:[
            [ 'Petición Simple' ],
            [ 'Petición Compleja' ]
        ]
    });
    
    return [
        new Baseliner.form.ComboList({ 
            data: ['Petición Simple', 'Petición Compleja'],
            name: 'tipo_pet',
            fieldLabel: 'Tipo Petición',
            emptyText: 'Seleccione Petición...'
        })
    ]
})
