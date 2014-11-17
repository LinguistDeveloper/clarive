(function(params){
    var node = params.node;
    var data = params.data;
    var title = data.doc_title||node.text||node.attributes.text||_('Clarive DocGen: no title');
    var win = window.open( data.doc_url, '_blank' );
    // can't set title from here, difficult async task... win.document.title = title;
    
})
