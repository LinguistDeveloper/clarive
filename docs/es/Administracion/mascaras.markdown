---
title: Gestión de las máscaras
---
* Las máscaras de carga en Clarive se modifican, actualizan, teniendo en cuenta los siguientes puntos:

• El icono actual, gif animado, se encuentra localizado en el directorio: clarive/root/static/images. Ruta completa clarive/root/static/images/loading.gif 
• CSS : Tanto la ruta del icono como todas sus características en cuanto a estilos están definidas en la hoja de estilos final.css. Ruta completa: clarive/root/static/final.css

• CSS : Las llamadas al elemento máscara se realizan en el archivo javascript correspondiente, vinculado al componente gráfico correspondiente.


Una vez en los javascript donde aparecen las máscaras, hay varias formas de referenciar el elemento:

&nbsp;• HTML embebido: Encontramos este formato de manera excepcional en la cargas generales de clarive, como loading.html, en la pantalla de login/password, o en la máscara asociada a los dashlets. 
En estos casos cualquier modificación al respecto debe realizarse sobre dicho HTML de forma directa.
Igualmente y de forma excepcional en estos casos no hay vínculo entre la máscara y las propiedades definidas en la hoja de estilos, aunque sí llama a la misma url del incono mencionada anteriormente.



&nbsp;• loadMask:true.

Propiedad de Ext.grid.xxxx (Ext.grid.GridPanel, EditorGridPanel, Ext.grid.GroupingWiew...) , vincula la máscara al grid desde el cual se le llama. Llama al componente Ext.LoadMask.js. Aclarar al respecto:

Ext.LoadMask.js es el componente gráfico "de cabecera de extjs en materia de máscaras. En la url clarive/features/extjs_3.4.0/root/static/ext/src/widgets/LoadMask.js puede verse la configuración por defecto de las máscaras extjs. En nuestro caso hemos querido modifiar tanto el mensaje de espera como la clase css definidos por defecto. Para ello, realizamos un override del componente en nuestro archivo common.js.

La máscara clarive es un gif dinámico sin texto, por lo que en el override hemos eliminado el string "Loading...".

Además, ha sido necesario definir estilos adicionales y modificar otros existentes, motivo por el cual hemos desvinculado la clase css por defecto, "x-mask-loading" cambiándola por "ext-el-mask-msg".

&nbsp;• Baseliner.showLoadingMask( el.getEl());

Definida en tabfu.js, función que se vincula a los componentes correspondientes y en los eventos en los que queremos que se reproduzca. 

Vinculada a esta tenemos Baseliner.hideLoadingMask(); que igualmente vinculada al evento correspondiente hace desaparecer la máscara.

Se definen otros Baseliner similares como Baseliner.showLoadingTreeMask con una clase css especialmente definida para objetos tipo árbol.


&nbsp;• Excepciones:

&nbsp; &nbsp; &nbsp; &nbsp; &nbsp;• Funciones de grid vinculadas a otros componentes.

Hay casos en los que el grid tiene una función vinculada a otros componentes, por ejemplo, como en los Mensajes del Sistema, en los que al crear un nuevo mensaje o clonarlo abrimos una ventana adicional con un formulario. En estos casos la propiedad loadMask:true no tiene el comportamiento esperado (no muestra o lo hace en el evento incorrecto).

En estos casos definimos loadMask:false o directamente la eliminamos, y definimos los eventos de carga del grid y de su store asociado con la llamada al Baseliner de la máscara. Siguiendo el ejemplo de los Mensajes del sistema, se muestra la máscara al activar el grid y se esconde al cargar el store que contiene.

		grid.on("activate", function() {
	        Baseliner.showLoadingMask( grid.getEl());
	    });

	    sms_store.on("load", function() {
	        Baseliner.hideLoadingMaskFade(grid.getEl());
	    });

&nbsp; &nbsp; &nbsp; &nbsp; &nbsp;• el.mask();

Excepcionalmente en los archivos help.js y kanban.js se define internamente la máscara con una variable que después se asocia al elemento que debe mostrarla, así:

Definición de variables:

		help_win.mask = function(){
	        help_win.body.mask('');
	     };
	    help_win.unmask = function(){
	        help_win.body.unmask();
	    };


Llamada en eventos:

	    docs_tree.getLoader().on('beforeload', function(lo){
	        help_win.mask();
	    });
	    docs_tree.getLoader().on('load', function(lo){
	        help_win.unmask();


Como comentamos, es excepcional, y la práctica correcta es la llamada al componente a través de loadMask:true en el caso de los grids o a los Baseliner definidos.