/*

Reloads some critical Baseliner scripts.

TODO this should eventually find all scripts loaded in the page, and reload. 
Or keep a load list from the first, controlled, load.

This is great loading, since it errors to the console.log with better line error accuracy. 

*/
// if you reload globals.js, tabs lose their info, and hell breaks loose
Baseliner.loadFile( '/site/common.js', 'js' );
Baseliner.loadFile( '/site/tabfu.js', 'js' );
Baseliner.loadFile( '/site/model.js', 'js' );
Baseliner.loadFile( '/comp/topic/topic_lib.js', 'js' );

Baseliner.message(_('JS'), _('Reloaded successfully') );  
